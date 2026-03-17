import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/core/sync/sync_checkpoint_store.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_api.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/core/sync/sync_push_api.dart';
import 'package:modular_pos/core/sync/sync_push_coordinator.dart';

void main() {
  const context = SyncPullContext(
    deviceId: 'device-1',
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    accountId: 'account-1',
  );

  test(
    'replayPending updates queue rows and triggers pull after success',
    () async {
      final queueStore = _MemoryOfflineCommandQueueStore([
        _record('op-1'),
        _record('op-2'),
      ]);
      final api = _FakeSyncPushApi(
        envelope: SyncPushEnvelope(
          pushedAt: DateTime.utc(2026, 3, 17, 10),
          results: const [
            SyncPushResult(
              clientOpId: 'op-1',
              status: SyncPushResultStatus.applied,
            ),
            SyncPushResult(
              clientOpId: 'op-2',
              status: SyncPushResultStatus.duplicate,
            ),
          ],
          rawData: const {},
        ),
      );
      final pullApi = _FakeSyncPullApi(
        envelope: SyncPullEnvelope(
          cursor: 'cursor-1',
          pulledAt: DateTime.utc(2026, 3, 17, 10, 1),
          payloadByScope: const {},
          rawData: const {},
        ),
      );
      final pullOrchestrator = _FakeSyncPullOrchestrator(api: pullApi);
      final coordinator = SyncPushCoordinator(
        queueStore: queueStore,
        api: api,
        pullOrchestrator: pullOrchestrator,
        readBranchWorkspaceScopes: () => const {
          SyncModuleScope.policy,
          SyncModuleScope.cashSession,
          SyncModuleScope.menu,
          SyncModuleScope.attendance,
          SyncModuleScope.shift,
        },
      );

      final result = await coordinator.replayPending(context: context);

      expect(result.outcome, SyncPushReplayOutcome.success);
      expect(result.appliedCount, 1);
      expect(result.duplicateCount, 1);
      expect(
        (await queueStore.read('op-1'))?.status,
        OfflineCommandQueueStatus.applied,
      );
      expect(
        (await queueStore.read('op-2'))?.status,
        OfflineCommandQueueStatus.duplicate,
      );
      expect(pullApi.wasCalled, isTrue);
    },
  );

  test(
    'replayPending restores rows to pending on push transport failure',
    () async {
      final queueStore = _MemoryOfflineCommandQueueStore([_record('op-1')]);
      final coordinator = SyncPushCoordinator(
        queueStore: queueStore,
        api: _FakeSyncPushApi(
          error: const ApiClientException(
            message: 'Offline',
            code: 'OFFLINE_UNREACHABLE',
          ),
        ),
        pullOrchestrator: _FakeSyncPullOrchestrator(
          api: _FakeSyncPullApi(
            envelope: SyncPullEnvelope(
              cursor: null,
              pulledAt: DateTime.utc(2026, 3, 17, 10),
              payloadByScope: const {},
              rawData: const {},
            ),
          ),
        ),
        readBranchWorkspaceScopes: () => const {SyncModuleScope.policy},
      );

      final result = await coordinator.replayPending(context: context);

      final record = await queueStore.read('op-1');
      expect(result.outcome, SyncPushReplayOutcome.pushFailed);
      expect(result.pushErrorCode, 'OFFLINE_UNREACHABLE');
      expect(record?.status, OfflineCommandQueueStatus.pending);
      expect(record?.lastErrorCode, 'OFFLINE_UNREACHABLE');
    },
  );
}

OfflineCommandRecord _record(String clientOpId) {
  final createdAt = DateTime.utc(2026, 3, 17, 9);
  return OfflineCommandRecord(
    clientOpId: clientOpId,
    operationType: OfflineOperationType.cashSessionOpen,
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    accountId: 'account-1',
    occurredAt: createdAt,
    payloadJson: '{}',
    status: OfflineCommandQueueStatus.pending,
    retryCount: 0,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

class _MemoryOfflineCommandQueueStore implements OfflineCommandQueueStore {
  _MemoryOfflineCommandQueueStore(Iterable<OfflineCommandRecord> seed) {
    for (final record in seed) {
      _records[record.clientOpId] = record;
    }
  }

  final Map<String, OfflineCommandRecord> _records =
      <String, OfflineCommandRecord>{};

  @override
  Future<int> countForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
  }) async {
    return listForContext(
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      statuses: statuses,
    ).then((records) => records.length);
  }

  @override
  Future<List<OfflineCommandRecord>> listForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
    int limit = 100,
  }) async {
    final normalizedBranchId = (branchId ?? '').trim();
    final normalizedAccountId = (accountId ?? '').trim();
    final filtered = _records.values.where((record) {
      final matchesContext =
          record.tenantId == tenantId &&
          record.branchId == normalizedBranchId &&
          record.accountId == normalizedAccountId;
      final matchesStatus =
          statuses == null || statuses.contains(record.status);
      return matchesContext && matchesStatus;
    }).toList()..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return filtered.take(limit).toList(growable: false);
  }

  @override
  Future<List<OfflineCommandRecord>> listReplayReadyForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    int limit = 100,
  }) {
    return listForContext(
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      statuses: const {
        OfflineCommandQueueStatus.pending,
        OfflineCommandQueueStatus.syncing,
      },
      limit: limit,
    );
  }

  @override
  Future<OfflineCommandRecord?> read(String clientOpId) async {
    return _records[clientOpId];
  }

  @override
  Future<void> write(OfflineCommandRecord record) async {
    _records[record.clientOpId] = record;
  }
}

class _FakeSyncPushApi extends SyncPushApi {
  _FakeSyncPushApi({this.envelope, this.error}) : super(Dio());

  final SyncPushEnvelope? envelope;
  final Object? error;

  @override
  Future<SyncPushEnvelope> push({
    required SyncPullContext context,
    required List<OfflineCommandRecord> operations,
  }) async {
    if (error != null) throw error!;
    return envelope!;
  }
}

class _FakeSyncPullApi extends SyncPullApi {
  _FakeSyncPullApi({this.envelope}) : super(Dio());

  final SyncPullEnvelope? envelope;
  var wasCalled = false;

  @override
  Future<SyncPullEnvelope> pull({
    required SyncPullContext context,
    required Set<SyncModuleScope> moduleScopes,
    String? cursor,
  }) async {
    wasCalled = true;
    return envelope!;
  }
}

class _FakeSyncPullOrchestrator extends SyncPullOrchestrator {
  _FakeSyncPullOrchestrator({required _FakeSyncPullApi api})
    : _api = api,
      super(
        api: api,
        checkpointStore: _MemorySyncCheckpointStore(),
        consumers: const [],
        status: _NoopSyncPullRunStateController(),
      );

  final _FakeSyncPullApi _api;

  @override
  Future<SyncPullEnvelope> pull({
    required SyncPullContext context,
    required Set<SyncModuleScope> moduleScopes,
    bool forceBootstrap = false,
  }) {
    return _api.pull(
      context: context,
      moduleScopes: moduleScopes,
      cursor: null,
    );
  }
}

class _MemorySyncCheckpointStore implements SyncCheckpointStore {
  final Map<String, SyncCheckpointRecord> _records =
      <String, SyncCheckpointRecord>{};

  @override
  Future<void> clear({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  }) async {
    _records.remove(
      '$deviceId|$tenantId|${branchId ?? ''}|${accountId ?? ''}|$moduleScopeSetKey',
    );
  }

  @override
  Future<SyncCheckpointRecord?> read({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  }) async {
    return _records['$deviceId|$tenantId|${branchId ?? ''}|${accountId ?? ''}|$moduleScopeSetKey'];
  }

  @override
  Future<void> write(SyncCheckpointRecord record) async {
    _records['${record.deviceId}|${record.tenantId}|${record.branchId}|${record.accountId}|${record.moduleScopeSetKey}'] =
        record;
  }
}

class _NoopSyncPullRunStateController extends SyncPullRunStateController {
  @override
  void markFailure(
    SyncPullContext context,
    String moduleScopeSetKey,
    DateTime failedAt, {
    String? errorCode,
  }) {}

  @override
  void markRunning(SyncPullContext context, String moduleScopeSetKey) {}

  @override
  void markSuccess(
    SyncPullContext context,
    String moduleScopeSetKey,
    DateTime pulledAt,
  ) {}
}
