import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/sync_checkpoint_store.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_api.dart';

abstract class SyncPullConsumer {
  SyncModuleScope get scope;

  Future<void> apply({
    required SyncPullContext context,
    required dynamic payload,
    required String? cursor,
    required DateTime pulledAt,
  });
}

final syncPullConsumersProvider = Provider<List<SyncPullConsumer>>((ref) {
  return const <SyncPullConsumer>[];
});

class SyncPullRunStateController extends Notifier<SyncPullRunState> {
  @override
  SyncPullRunState build() => const SyncPullRunState();

  void markRunning(String moduleScopeSetKey) {
    state = SyncPullRunState(
      status: SyncPullRunStatus.running,
      moduleScopeSetKey: moduleScopeSetKey,
      lastRunAt: DateTime.now(),
    );
  }

  void markSuccess(String moduleScopeSetKey, DateTime pulledAt) {
    state = SyncPullRunState(
      status: SyncPullRunStatus.success,
      moduleScopeSetKey: moduleScopeSetKey,
      lastRunAt: pulledAt,
    );
  }

  void markFailure(
    String moduleScopeSetKey,
    DateTime failedAt, {
    String? errorCode,
  }) {
    state = SyncPullRunState(
      status: SyncPullRunStatus.failure,
      moduleScopeSetKey: moduleScopeSetKey,
      lastRunAt: failedAt,
      lastErrorCode: errorCode,
    );
  }
}

final syncPullRunStateProvider =
    NotifierProvider<SyncPullRunStateController, SyncPullRunState>(
      SyncPullRunStateController.new,
    );

final syncPullOrchestratorProvider = Provider<SyncPullOrchestrator>((ref) {
  final api = ref.read(syncPullApiProvider);
  final checkpointStore = ref.read(syncCheckpointStoreProvider);
  final consumers = ref.read(syncPullConsumersProvider);
  final status = ref.read(syncPullRunStateProvider.notifier);
  return SyncPullOrchestrator(
    api: api,
    checkpointStore: checkpointStore,
    consumers: consumers,
    status: status,
  );
});

class SyncPullOrchestrator {
  SyncPullOrchestrator({
    required SyncPullApi api,
    required SyncCheckpointStore checkpointStore,
    required List<SyncPullConsumer> consumers,
    required SyncPullRunStateController status,
  }) : _api = api,
       _checkpointStore = checkpointStore,
       _consumersByScope = {
         for (final consumer in consumers) consumer.scope: consumer,
       },
       _status = status;

  final SyncPullApi _api;
  final SyncCheckpointStore _checkpointStore;
  final Map<SyncModuleScope, SyncPullConsumer> _consumersByScope;
  final SyncPullRunStateController _status;

  Future<SyncPullEnvelope> pull({
    required SyncPullContext context,
    required Set<SyncModuleScope> moduleScopes,
    bool forceBootstrap = false,
  }) async {
    final normalizedScopes = moduleScopes.toSet();
    if (normalizedScopes.isEmpty) {
      throw ArgumentError.value(
        normalizedScopes,
        'moduleScopes',
        'At least one module scope is required.',
      );
    }

    final missingConsumers = normalizedScopes
        .where((scope) => !_consumersByScope.containsKey(scope))
        .toList(growable: false);
    if (missingConsumers.isNotEmpty) {
      throw StateError(
        'Missing sync consumers for scopes: '
        '${missingConsumers.map((scope) => scope.apiValue).join(', ')}',
      );
    }

    final scopeSetKey = buildModuleScopeSetKey(normalizedScopes);
    _status.markRunning(scopeSetKey);

    final previousCheckpoint = await _checkpointStore.read(
      deviceId: context.deviceId,
      tenantId: context.tenantId,
      branchId: context.branchId,
      accountId: context.accountId,
      moduleScopeSetKey: scopeSetKey,
    );

    try {
      final envelope = await _api.pull(
        context: context,
        moduleScopes: normalizedScopes,
        cursor: forceBootstrap ? null : previousCheckpoint?.cursor,
      );

      for (final scope in normalizedScopes) {
        await _consumersByScope[scope]!.apply(
          context: context,
          payload: envelope.payloadByScope[scope.apiValue],
          cursor: envelope.cursor,
          pulledAt: envelope.pulledAt,
        );
      }

      await _checkpointStore.write(
        SyncCheckpointRecord(
          deviceId: context.deviceId,
          tenantId: context.tenantId,
          branchId: context.branchId,
          accountId: context.accountId,
          moduleScopeSetKey: scopeSetKey,
          cursor: envelope.cursor ?? previousCheckpoint?.cursor,
          lastPullAt: envelope.pulledAt,
          lastSuccessfulPullAt: envelope.pulledAt,
          lastPullStatus: 'success',
          lastErrorCode: null,
        ),
      );
      _status.markSuccess(scopeSetKey, envelope.pulledAt);
      return envelope;
    } catch (error) {
      final failedAt = DateTime.now();
      final errorCode = _errorCode(error);
      await _checkpointStore.write(
        SyncCheckpointRecord(
          deviceId: context.deviceId,
          tenantId: context.tenantId,
          branchId: context.branchId,
          accountId: context.accountId,
          moduleScopeSetKey: scopeSetKey,
          cursor: previousCheckpoint?.cursor,
          lastPullAt: failedAt,
          lastSuccessfulPullAt: previousCheckpoint?.lastSuccessfulPullAt,
          lastPullStatus: 'failed',
          lastErrorCode: errorCode,
        ),
      );
      _status.markFailure(scopeSetKey, failedAt, errorCode: errorCode);
      rethrow;
    }
  }

  String _errorCode(Object error) {
    if (error is ApiClientException) {
      return (error.code ?? '').trim().isNotEmpty
          ? error.code!.trim()
          : 'SYNC_PULL_FAILED';
    }
    return 'LOCAL_APPLY_FAILED';
  }
}
