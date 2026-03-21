import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/sync_checkpoint_store.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_api.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/core/sync/sync_pull_trigger_controller.dart';

import '../../test_utils/riverpod_test_utils.dart';

void main() {
  test(
    'triggerBranchWorkspace skips when sync context is unavailable',
    () async {
      final container = createTestContainer(
        overrides: [syncPullContextProvider.overrideWith((ref) => null)],
      );

      final controller = container.read(syncPullTriggerControllerProvider);
      final result = await controller.triggerBranchWorkspace(
        trigger: SyncPullTrigger.hydration,
      );

      expect(result.outcome, SyncPullTriggerOutcome.skippedNoContext);
    },
  );

  test('triggerBranchWorkspace skips when branch context is missing', () async {
    const context = SyncPullContext(
      deviceId: 'device-1',
      tenantId: 'tenant-1',
      branchId: '',
      accountId: 'account-1',
    );
    final container = createTestContainer(
      overrides: [syncPullContextProvider.overrideWith((ref) => context)],
    );

    final controller = container.read(syncPullTriggerControllerProvider);
    final result = await controller.triggerBranchWorkspace(
      trigger: SyncPullTrigger.tenantSwitch,
    );

    expect(result.outcome, SyncPullTriggerOutcome.skippedNoBranchContext);
  });

  test('triggerBranchWorkspace resolves first-wave branch scope set', () async {
    final checkpointStore = _MemorySyncCheckpointStore();
    final api = _FakeSyncPullApi(
      envelope: SyncPullEnvelope(
        cursor: 'cursor-1',
        pulledAt: DateTime.utc(2026, 3, 17, 9),
        payloadByScope: const {
          'policy': <String, dynamic>{},
          'cashSession': <String, dynamic>{},
          'menu': <String, dynamic>{},
          'attendance': <String, dynamic>{},
          'shift': <String, dynamic>{},
        },
        rawData: const {},
      ),
    );
    final consumers = [
      _RecordingConsumer(SyncModuleScope.policy),
      _RecordingConsumer(SyncModuleScope.cashSession),
      _RecordingConsumer(SyncModuleScope.menu),
      _RecordingConsumer(SyncModuleScope.attendance),
      _RecordingConsumer(SyncModuleScope.shift),
    ];
    const context = SyncPullContext(
      deviceId: 'device-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      accountId: 'account-1',
    );
    final container = createTestContainer(
      overrides: [
        syncPullApiProvider.overrideWithValue(api),
        syncCheckpointStoreProvider.overrideWithValue(checkpointStore),
        syncPullConsumersProvider.overrideWithValue(consumers),
        syncPullContextProvider.overrideWith((ref) => context),
      ],
    );

    final controller = container.read(syncPullTriggerControllerProvider);
    final result = await controller.triggerBranchWorkspace(
      trigger: SyncPullTrigger.branchSwitch,
    );

    expect(result.outcome, SyncPullTriggerOutcome.success);
    expect(api.lastModuleScopes, {
      SyncModuleScope.policy,
      SyncModuleScope.cashSession,
      SyncModuleScope.menu,
      SyncModuleScope.attendance,
      SyncModuleScope.shift,
    });
  });

  test(
    'triggerForContext skips identical request while one is already running',
    () async {
      final completer = Completer<SyncPullEnvelope>();
      final checkpointStore = _MemorySyncCheckpointStore();
      final api = _FakeSyncPullApi(completer: completer);
      final consumer = _RecordingConsumer(SyncModuleScope.policy);
      const context = SyncPullContext(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'account-1',
      );
      final container = createTestContainer(
        overrides: [
          syncPullApiProvider.overrideWithValue(api),
          syncCheckpointStoreProvider.overrideWithValue(checkpointStore),
          syncPullConsumersProvider.overrideWithValue([consumer]),
        ],
      );

      final controller = container.read(syncPullTriggerControllerProvider);
      final firstRun = controller.triggerForContext(
        trigger: SyncPullTrigger.hydration,
        context: context,
        moduleScopes: {SyncModuleScope.policy},
      );
      final duplicateRun = await controller.triggerForContext(
        trigger: SyncPullTrigger.branchSwitch,
        context: context,
        moduleScopes: {SyncModuleScope.policy},
      );

      completer.complete(
        SyncPullEnvelope(
          cursor: 'cursor-1',
          pulledAt: DateTime.utc(2026, 3, 17, 9),
          payloadByScope: const {'policy': <String, dynamic>{}},
          rawData: const {},
        ),
      );

      final firstResult = await firstRun;

      expect(duplicateRun.outcome, SyncPullTriggerOutcome.skippedInFlight);
      expect(firstResult.outcome, SyncPullTriggerOutcome.success);
      expect(api.callCount, 1);
    },
  );

  test(
    'triggerForContext skips duplicate request during cooldown window',
    () async {
      final checkpointStore = _MemorySyncCheckpointStore();
      final api = _FakeSyncPullApi(
        envelope: SyncPullEnvelope(
          cursor: 'cursor-1',
          pulledAt: DateTime.utc(2026, 3, 17, 9),
          payloadByScope: const {'policy': <String, dynamic>{}},
          rawData: const {},
        ),
      );
      final consumer = _RecordingConsumer(SyncModuleScope.policy);
      const context = SyncPullContext(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'account-1',
      );
      DateTime now = DateTime.utc(2026, 3, 17, 9);
      final container = createTestContainer(
        overrides: [
          syncPullApiProvider.overrideWithValue(api),
          syncCheckpointStoreProvider.overrideWithValue(checkpointStore),
          syncPullConsumersProvider.overrideWithValue([consumer]),
          syncPullTriggerNowProvider.overrideWith(
            (ref) =>
                () => now,
          ),
          syncPullTriggerCooldownProvider.overrideWith(
            (ref) => const Duration(seconds: 5),
          ),
        ],
      );

      final controller = container.read(syncPullTriggerControllerProvider);
      final first = await controller.triggerForContext(
        trigger: SyncPullTrigger.hydration,
        context: context,
        moduleScopes: {SyncModuleScope.policy},
      );
      final second = await controller.triggerForContext(
        trigger: SyncPullTrigger.branchSwitch,
        context: context,
        moduleScopes: {SyncModuleScope.policy},
      );

      now = now.add(const Duration(seconds: 6));
      final third = await controller.triggerForContext(
        trigger: SyncPullTrigger.branchSwitch,
        context: context,
        moduleScopes: {SyncModuleScope.policy},
      );

      expect(first.outcome, SyncPullTriggerOutcome.success);
      expect(second.outcome, SyncPullTriggerOutcome.skippedCooldown);
      expect(third.outcome, SyncPullTriggerOutcome.success);
      expect(api.callCount, 2);
    },
  );

  test(
    'triggerForContext returns failed result when orchestrator pull throws',
    () async {
      final checkpointStore = _MemorySyncCheckpointStore();
      final api = _FakeSyncPullApi(
        error: const ApiClientException(
          message: 'Network down',
          code: 'OFFLINE_UNREACHABLE',
        ),
      );
      final consumer = _RecordingConsumer(SyncModuleScope.policy);
      const context = SyncPullContext(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'account-1',
      );
      final container = createTestContainer(
        overrides: [
          syncPullApiProvider.overrideWithValue(api),
          syncCheckpointStoreProvider.overrideWithValue(checkpointStore),
          syncPullConsumersProvider.overrideWithValue([consumer]),
        ],
      );

      final controller = container.read(syncPullTriggerControllerProvider);
      final result = await controller.triggerForContext(
        trigger: SyncPullTrigger.hydration,
        context: context,
        moduleScopes: {SyncModuleScope.policy},
      );

      expect(result.outcome, SyncPullTriggerOutcome.failed);
      expect(result.errorCode, 'OFFLINE_UNREACHABLE');
    },
  );
}

class _FakeSyncPullApi extends SyncPullApi {
  _FakeSyncPullApi({this.envelope, this.error, this.completer}) : super(Dio());

  final SyncPullEnvelope? envelope;
  final Object? error;
  final Completer<SyncPullEnvelope>? completer;
  int callCount = 0;
  Set<SyncModuleScope>? lastModuleScopes;

  @override
  Future<SyncPullEnvelope> pull({
    required SyncPullContext context,
    required Set<SyncModuleScope> moduleScopes,
    String? cursor,
  }) async {
    callCount++;
    lastModuleScopes = moduleScopes;
    if (error != null) throw error!;
    if (completer != null) return completer!.future;
    return envelope!;
  }
}

class _RecordingConsumer implements SyncPullConsumer {
  _RecordingConsumer(this.scope);

  @override
  final SyncModuleScope scope;

  @override
  Future<void> apply({
    required SyncPullContext context,
    required payload,
    required String? cursor,
    required DateTime pulledAt,
  }) async {}
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
