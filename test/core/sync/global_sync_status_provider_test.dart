import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/sync/global_sync_status.dart';
import 'package:modular_pos/core/sync/sync_freshness.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';

import '../../test_utils/riverpod_test_utils.dart';

final _testFreshnessProvider =
    NotifierProvider<_TestFreshnessController, SyncWorkspaceFreshness?>(
      _TestFreshnessController.new,
    );

void main() {
  test(
    'globalSyncStatusProvider reacts to connectivity and freshness changes',
    () async {
      final source = _TestAppConnectivitySource(AppConnectivityStatus.online);
      final runStateController = _TestSyncPullRunStateController(
        const SyncPullRunState(),
      );

      final container = createTestContainer(
        overrides: [
          appConnectivitySourceProvider.overrideWithValue(source),
          syncPullRunStateProvider.overrideWith(() => runStateController),
          branchWorkspaceSyncFreshnessProvider.overrideWith(
            (ref) async => ref.watch(_testFreshnessProvider),
          ),
        ],
      );

      await container.read(branchWorkspaceSyncFreshnessProvider.future);
      expect(
        container.read(globalSyncStatusProvider).kind,
        GlobalSyncStatusKind.online,
      );

      source.emit(AppConnectivityStatus.offline);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(globalSyncStatusProvider).kind,
        GlobalSyncStatusKind.offline,
      );

      source.emit(AppConnectivityStatus.online);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(globalSyncStatusProvider).kind,
        GlobalSyncStatusKind.online,
      );

      runStateController.setRunState(
        const SyncPullRunState(status: SyncPullRunStatus.running),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(globalSyncStatusProvider).kind,
        GlobalSyncStatusKind.syncing,
      );

      runStateController.setRunState(const SyncPullRunState());
      container
          .read(_testFreshnessProvider.notifier)
          .setFreshness(
            const SyncWorkspaceFreshness(
              kind: SyncWorkspaceFreshnessKind.refreshFailed,
              message: 'Refresh failed. Showing last synced workspace data.',
            ),
          );
      await container.read(branchWorkspaceSyncFreshnessProvider.future);
      expect(
        container.read(globalSyncStatusProvider).kind,
        GlobalSyncStatusKind.stale,
      );
    },
  );
}

class _TestAppConnectivitySource implements AppConnectivitySource {
  _TestAppConnectivitySource(this.initialStatus);

  @override
  final AppConnectivityStatus initialStatus;

  final StreamController<AppConnectivityStatus> _controller =
      StreamController<AppConnectivityStatus>.broadcast();

  @override
  Stream<AppConnectivityStatus> get onStatusChanged => _controller.stream;

  void emit(AppConnectivityStatus status) {
    _controller.add(status);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class _TestSyncPullRunStateController extends SyncPullRunStateController {
  _TestSyncPullRunStateController(this._initialState);

  final SyncPullRunState _initialState;

  @override
  SyncPullRunState build() => _initialState;

  void setRunState(SyncPullRunState next) {
    state = next;
  }
}

class _TestFreshnessController extends Notifier<SyncWorkspaceFreshness?> {
  @override
  SyncWorkspaceFreshness? build() => null;

  void setFreshness(SyncWorkspaceFreshness? next) {
    state = next;
  }
}
