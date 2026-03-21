import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/core/sync/sync_checkpoint_store.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_api.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/core/sync/sync_push_api.dart';
import 'package:modular_pos/core/sync/sync_push_coordinator.dart';
import 'package:modular_pos/core/sync/sync_push_trigger_controller.dart';

import '../../test_utils/riverpod_test_utils.dart';

void main() {
  test(
    'triggerBranchWorkspace skips when sync context is unavailable',
    () async {
      final container = createTestContainer(
        overrides: [syncPullContextProvider.overrideWith((ref) => null)],
      );

      final controller = container.read(syncPushTriggerControllerProvider);
      final result = await controller.triggerBranchWorkspace(
        trigger: SyncPushTrigger.reconnect,
      );

      expect(result.outcome, SyncPushTriggerOutcome.skippedNoContext);
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
      overrides: [
        syncPullContextProvider.overrideWith((ref) => context),
        syncPushCoordinatorProvider.overrideWithValue(
          _FakeSyncPushCoordinator(
            result: const SyncPushReplayResult(
              outcome: SyncPushReplayOutcome.noPending,
              totalCount: 0,
            ),
          ),
        ),
      ],
    );

    final controller = container.read(syncPushTriggerControllerProvider);
    final result = await controller.triggerBranchWorkspace(
      trigger: SyncPushTrigger.reconnect,
    );

    expect(result.outcome, SyncPushTriggerOutcome.skippedNoBranchContext);
  });

  test(
    'triggerForContext skips identical request while one is already running',
    () async {
      final completer = Completer<SyncPushReplayResult>();
      final coordinator = _FakeSyncPushPushCompleterCoordinator(completer);
      const context = SyncPullContext(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'account-1',
      );
      final container = createTestContainer(
        overrides: [syncPushCoordinatorProvider.overrideWithValue(coordinator)],
      );

      final controller = container.read(syncPushTriggerControllerProvider);
      final firstRun = controller.triggerForContext(
        trigger: SyncPushTrigger.reconnect,
        context: context,
      );
      final duplicateRun = await controller.triggerForContext(
        trigger: SyncPushTrigger.reconnect,
        context: context,
      );

      completer.complete(
        const SyncPushReplayResult(
          outcome: SyncPushReplayOutcome.noPending,
          totalCount: 0,
        ),
      );

      final firstResult = await firstRun;

      expect(duplicateRun.outcome, SyncPushTriggerOutcome.skippedInFlight);
      expect(firstResult.outcome, SyncPushTriggerOutcome.noPending);
      expect(coordinator.callCount, 1);
    },
  );

  test(
    'triggerForContext skips duplicate request during cooldown window',
    () async {
      final coordinator = _FakeSyncPushCoordinator(
        result: const SyncPushReplayResult(
          outcome: SyncPushReplayOutcome.success,
          totalCount: 1,
          appliedCount: 1,
        ),
      );
      const context = SyncPullContext(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'account-1',
      );
      DateTime now = DateTime.utc(2026, 3, 17, 9);
      final container = createTestContainer(
        overrides: [
          syncPushCoordinatorProvider.overrideWithValue(coordinator),
          syncPushTriggerNowProvider.overrideWith(
            (ref) =>
                () => now,
          ),
          syncPushTriggerCooldownProvider.overrideWith(
            (ref) => const Duration(seconds: 5),
          ),
        ],
      );

      final controller = container.read(syncPushTriggerControllerProvider);
      final first = await controller.triggerForContext(
        trigger: SyncPushTrigger.reconnect,
        context: context,
      );
      final second = await controller.triggerForContext(
        trigger: SyncPushTrigger.reconnect,
        context: context,
      );

      now = now.add(const Duration(seconds: 6));
      final third = await controller.triggerForContext(
        trigger: SyncPushTrigger.reconnect,
        context: context,
      );

      expect(first.outcome, SyncPushTriggerOutcome.success);
      expect(second.outcome, SyncPushTriggerOutcome.skippedCooldown);
      expect(third.outcome, SyncPushTriggerOutcome.success);
      expect(coordinator.callCount, 2);
    },
  );

  test('manualFlushBranchWorkspace bypasses cooldown window', () async {
    final coordinator = _FakeSyncPushCoordinator(
      result: const SyncPushReplayResult(
        outcome: SyncPushReplayOutcome.noPending,
        totalCount: 0,
      ),
    );
    const context = SyncPullContext(
      deviceId: 'device-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      accountId: 'account-1',
    );
    final container = createTestContainer(
      overrides: [
        syncPushCoordinatorProvider.overrideWithValue(coordinator),
        syncPullContextProvider.overrideWith((ref) => context),
      ],
    );

    final controller = container.read(syncPushTriggerControllerProvider);
    final first = await controller.triggerBranchWorkspace(
      trigger: SyncPushTrigger.reconnect,
    );
    final second = await controller.manualFlushBranchWorkspace();

    expect(first.outcome, SyncPushTriggerOutcome.noPending);
    expect(second.outcome, SyncPushTriggerOutcome.noPending);
    expect(coordinator.callCount, 2);
  });
}

class _FakeSyncPushCoordinator extends SyncPushCoordinator {
  _FakeSyncPushCoordinator({required this.result})
    : super(
        queueStore: _NoopOfflineCommandQueueStore(),
        api: _NoopSyncPushApi(),
        pullOrchestrator: _NoopSyncPullOrchestrator(),
        readBranchWorkspaceScopes: () => const <SyncModuleScope>{},
      );

  final SyncPushReplayResult result;
  int callCount = 0;

  @override
  Future<SyncPushReplayResult> replayPending({
    required SyncPullContext context,
    int limit = 50,
  }) async {
    callCount += 1;
    return result;
  }
}

class _FakeSyncPushPushCompleterCoordinator extends SyncPushCoordinator {
  _FakeSyncPushPushCompleterCoordinator(this._completer)
    : super(
        queueStore: _NoopOfflineCommandQueueStore(),
        api: _NoopSyncPushApi(),
        pullOrchestrator: _NoopSyncPullOrchestrator(),
        readBranchWorkspaceScopes: () => const <SyncModuleScope>{},
      );

  final Completer<SyncPushReplayResult> _completer;
  int callCount = 0;

  @override
  Future<SyncPushReplayResult> replayPending({
    required SyncPullContext context,
    int limit = 50,
  }) {
    callCount += 1;
    return _completer.future;
  }
}

class _NoopOfflineCommandQueueStore implements OfflineCommandQueueStore {
  @override
  Future<int> countForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
  }) async {
    return 0;
  }

  @override
  Future<List<OfflineCommandRecord>> listForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
    int limit = 100,
  }) async {
    return const <OfflineCommandRecord>[];
  }

  @override
  Future<List<OfflineCommandRecord>> listReplayReadyForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    int limit = 100,
  }) async {
    return const <OfflineCommandRecord>[];
  }

  @override
  Future<OfflineCommandRecord?> read(String clientOpId) async {
    return null;
  }

  @override
  Future<void> delete(String clientOpId) async {}

  @override
  Future<void> write(OfflineCommandRecord record) async {}
}

class _NoopSyncPushApi extends SyncPushApi {
  _NoopSyncPushApi() : super(Dio());

  @override
  Future<SyncPushEnvelope> push({
    required SyncPullContext context,
    required List<OfflineCommandRecord> operations,
  }) {
    throw UnimplementedError();
  }
}

class _NoopSyncPullOrchestrator extends SyncPullOrchestrator {
  _NoopSyncPullOrchestrator()
    : super(
        api: _NoopSyncPullApi(),
        checkpointStore: _NoopSyncCheckpointStore(),
        consumers: const <SyncPullConsumer>[],
        status: _NoopSyncPullRunStateController(),
      );
}

class _NoopSyncPullApi extends SyncPullApi {
  _NoopSyncPullApi() : super(Dio());

  @override
  Future<SyncPullEnvelope> pull({
    required SyncPullContext context,
    required Set<SyncModuleScope> moduleScopes,
    String? cursor,
  }) {
    throw UnimplementedError();
  }
}

class _NoopSyncCheckpointStore implements SyncCheckpointStore {
  @override
  Future<void> clear({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  }) async {}

  @override
  Future<SyncCheckpointRecord?> read({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  }) async {
    return null;
  }

  @override
  Future<void> write(SyncCheckpointRecord record) async {}
}

class _NoopSyncPullRunStateController extends SyncPullRunStateController {
  @override
  SyncPullRunState build() => const SyncPullRunState();
}
