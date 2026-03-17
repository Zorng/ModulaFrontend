import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/sync_checkpoint_store.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_api.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';

import '../../test_utils/riverpod_test_utils.dart';

void main() {
  test(
    'pull applies consumers and advances checkpoint only after success',
    () async {
      final checkpointStore = _MemorySyncCheckpointStore();
      final api = _FakeSyncPullApi(
        envelope: SyncPullEnvelope(
          cursor: 'cursor-1',
          pulledAt: DateTime.utc(2026, 3, 17, 9),
          payloadByScope: const {
            'policy': {'version': 1},
          },
          rawData: const {
            'policy': {'version': 1},
          },
        ),
      );
      final consumer = _RecordingConsumer(SyncModuleScope.policy);
      final container = createTestContainer(
        overrides: [
          syncPullApiProvider.overrideWithValue(api),
          syncCheckpointStoreProvider.overrideWithValue(checkpointStore),
          syncPullConsumersProvider.overrideWithValue([consumer]),
        ],
      );

      final orchestrator = container.read(syncPullOrchestratorProvider);
      const context = SyncPullContext(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      );

      await orchestrator.pull(
        context: context,
        moduleScopes: {SyncModuleScope.policy},
      );

      final checkpoint = await checkpointStore.read(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        moduleScopeSetKey: 'policy',
      );
      final runState = container.read(syncPullRunStateProvider);

      expect(api.lastCursor, isNull);
      expect(consumer.lastPayload, {'version': 1});
      expect(checkpoint?.cursor, 'cursor-1');
      expect(checkpoint?.lastPullStatus, 'success');
      expect(runState.status, SyncPullRunStatus.success);
    },
  );

  test('pull keeps previous cursor when consumer apply fails', () async {
    final checkpointStore = _MemorySyncCheckpointStore();
    await checkpointStore.write(
      const SyncCheckpointRecord(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: '',
        moduleScopeSetKey: 'policy',
        cursor: 'cursor-0',
        lastPullStatus: 'success',
      ),
    );
    final api = _FakeSyncPullApi(
      envelope: SyncPullEnvelope(
        cursor: 'cursor-1',
        pulledAt: DateTime.utc(2026, 3, 17, 9),
        payloadByScope: const {
          'policy': {'version': 2},
        },
        rawData: const {
          'policy': {'version': 2},
        },
      ),
    );
    final consumer = _ThrowingConsumer(SyncModuleScope.policy);
    final container = createTestContainer(
      overrides: [
        syncPullApiProvider.overrideWithValue(api),
        syncCheckpointStoreProvider.overrideWithValue(checkpointStore),
        syncPullConsumersProvider.overrideWithValue([consumer]),
      ],
    );

    final orchestrator = container.read(syncPullOrchestratorProvider);
    const context = SyncPullContext(
      deviceId: 'device-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
    );

    await expectLater(
      () => orchestrator.pull(
        context: context,
        moduleScopes: {SyncModuleScope.policy},
      ),
      throwsA(isA<StateError>()),
    );

    final checkpoint = await checkpointStore.read(
      deviceId: 'device-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      moduleScopeSetKey: 'policy',
    );
    final runState = container.read(syncPullRunStateProvider);

    expect(checkpoint?.cursor, 'cursor-0');
    expect(checkpoint?.lastPullStatus, 'failed');
    expect(checkpoint?.lastErrorCode, 'LOCAL_APPLY_FAILED');
    expect(runState.status, SyncPullRunStatus.failure);
  });

  test(
    'pull writes api failure metadata without advancing checkpoint',
    () async {
      final checkpointStore = _MemorySyncCheckpointStore();
      await checkpointStore.write(
        const SyncCheckpointRecord(
          deviceId: 'device-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: '',
          moduleScopeSetKey: 'policy',
          cursor: 'cursor-0',
          lastPullStatus: 'success',
        ),
      );
      final api = _FakeSyncPullApi(
        error: const ApiClientException(
          message: 'Network down',
          code: 'OFFLINE_UNREACHABLE',
        ),
      );
      final consumer = _RecordingConsumer(SyncModuleScope.policy);
      final container = createTestContainer(
        overrides: [
          syncPullApiProvider.overrideWithValue(api),
          syncCheckpointStoreProvider.overrideWithValue(checkpointStore),
          syncPullConsumersProvider.overrideWithValue([consumer]),
        ],
      );

      final orchestrator = container.read(syncPullOrchestratorProvider);
      const context = SyncPullContext(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      );

      await expectLater(
        () => orchestrator.pull(
          context: context,
          moduleScopes: {SyncModuleScope.policy},
        ),
        throwsA(isA<ApiClientException>()),
      );

      final checkpoint = await checkpointStore.read(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        moduleScopeSetKey: 'policy',
      );

      expect(checkpoint?.cursor, 'cursor-0');
      expect(checkpoint?.lastPullStatus, 'failed');
      expect(checkpoint?.lastErrorCode, 'OFFLINE_UNREACHABLE');
      expect(consumer.lastPayload, isNull);
    },
  );
}

class _FakeSyncPullApi extends SyncPullApi {
  _FakeSyncPullApi({this.envelope, this.error}) : super(Dio());

  final SyncPullEnvelope? envelope;
  final Object? error;
  String? lastCursor;

  @override
  Future<SyncPullEnvelope> pull({
    required SyncPullContext context,
    required Set<SyncModuleScope> moduleScopes,
    String? cursor,
  }) async {
    lastCursor = cursor;
    if (error != null) throw error!;
    return envelope!;
  }
}

class _RecordingConsumer implements SyncPullConsumer {
  _RecordingConsumer(this.scope);

  @override
  final SyncModuleScope scope;

  dynamic lastPayload;

  @override
  Future<void> apply({
    required SyncPullContext context,
    required payload,
    required String? cursor,
    required DateTime pulledAt,
  }) async {
    lastPayload = payload;
  }
}

class _ThrowingConsumer implements SyncPullConsumer {
  _ThrowingConsumer(this.scope);

  @override
  final SyncModuleScope scope;

  @override
  Future<void> apply({
    required SyncPullContext context,
    required payload,
    required String? cursor,
    required DateTime pulledAt,
  }) async {
    throw StateError('apply failed');
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
      _key(
        deviceId: deviceId,
        tenantId: tenantId,
        branchId: branchId,
        accountId: accountId,
        moduleScopeSetKey: moduleScopeSetKey,
      ),
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
    return _records[_key(
      deviceId: deviceId,
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      moduleScopeSetKey: moduleScopeSetKey,
    )];
  }

  @override
  Future<void> write(SyncCheckpointRecord record) async {
    _records[_key(
          deviceId: record.deviceId,
          tenantId: record.tenantId,
          branchId: record.branchId,
          accountId: record.accountId,
          moduleScopeSetKey: record.moduleScopeSetKey,
        )] =
        record;
  }

  String _key({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  }) {
    return [
      deviceId.trim(),
      tenantId.trim(),
      (branchId ?? '').trim(),
      (accountId ?? '').trim(),
      moduleScopeSetKey.trim(),
    ].join('|');
  }
}
