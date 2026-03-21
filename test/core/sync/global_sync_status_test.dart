import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/sync/global_sync_status.dart';
import 'package:modular_pos/core/sync/sync_freshness.dart';
import 'package:modular_pos/core/sync/sync_models.dart';

void main() {
  test('offline wins over all other states', () {
    final status = deriveGlobalSyncStatus(
      connectivityStatus: AppConnectivityStatus.offline,
      runState: const SyncPullRunState(status: SyncPullRunStatus.running),
      freshness: const SyncWorkspaceFreshness(
        kind: SyncWorkspaceFreshnessKind.refreshFailed,
        message: 'Refresh failed. Showing last synced workspace data.',
      ),
    );

    expect(status.kind, GlobalSyncStatusKind.offline);
    expect(status.label, 'Offline');
  });

  test('syncing wins over stale when online', () {
    final status = deriveGlobalSyncStatus(
      connectivityStatus: AppConnectivityStatus.online,
      runState: const SyncPullRunState(status: SyncPullRunStatus.running),
      freshness: const SyncWorkspaceFreshness(
        kind: SyncWorkspaceFreshnessKind.staleUsable,
        message: 'Offline: showing last synced workspace data.',
      ),
    );

    expect(status.kind, GlobalSyncStatusKind.syncing);
    expect(status.label, 'Syncing');
  });

  test('stale is shown when online and cached data is stale', () {
    final status = deriveGlobalSyncStatus(
      connectivityStatus: AppConnectivityStatus.online,
      runState: const SyncPullRunState(),
      freshness: const SyncWorkspaceFreshness(
        kind: SyncWorkspaceFreshnessKind.refreshFailed,
        message: 'Refresh failed. Showing last synced workspace data.',
      ),
    );

    expect(status.kind, GlobalSyncStatusKind.stale);
    expect(status.label, 'Stale');
  });

  test('online is default when connected and not stale', () {
    final status = deriveGlobalSyncStatus(
      connectivityStatus: AppConnectivityStatus.online,
      runState: const SyncPullRunState(),
    );

    expect(status.kind, GlobalSyncStatusKind.online);
    expect(status.label, 'Online');
  });
}
