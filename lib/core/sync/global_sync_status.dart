import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/sync/sync_freshness.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';

enum GlobalSyncStatusKind { offline, syncing, stale, online }

class GlobalSyncStatus {
  const GlobalSyncStatus({
    required this.kind,
    required this.label,
    this.detail,
  });

  final GlobalSyncStatusKind kind;
  final String label;
  final String? detail;
}

GlobalSyncStatus deriveGlobalSyncStatus({
  required AppConnectivityStatus connectivityStatus,
  required SyncPullRunState runState,
  SyncWorkspaceFreshness? freshness,
}) {
  if (connectivityStatus == AppConnectivityStatus.offline) {
    return const GlobalSyncStatus(
      kind: GlobalSyncStatusKind.offline,
      label: 'Offline',
      detail: 'Showing cached data when available.',
    );
  }

  final isSyncing =
      runState.status == SyncPullRunStatus.running ||
      freshness?.kind == SyncWorkspaceFreshnessKind.syncing;
  if (isSyncing) {
    return const GlobalSyncStatus(
      kind: GlobalSyncStatusKind.syncing,
      label: 'Syncing',
      detail: 'Refreshing workspace data.',
    );
  }

  if (freshness != null) {
    final detail = switch (freshness.kind) {
      SyncWorkspaceFreshnessKind.refreshFailed =>
        'Refresh failed. Showing last synced data.',
      SyncWorkspaceFreshnessKind.staleUsable =>
        'Showing last synced workspace data.',
      SyncWorkspaceFreshnessKind.syncing => 'Refreshing workspace data.',
    };
    return GlobalSyncStatus(
      kind: GlobalSyncStatusKind.stale,
      label: 'Stale',
      detail: detail,
    );
  }

  return const GlobalSyncStatus(
    kind: GlobalSyncStatusKind.online,
    label: 'Online',
    detail: 'Workspace is connected.',
  );
}

final globalSyncStatusProvider = Provider<GlobalSyncStatus>((ref) {
  final connectivityStatus = ref.watch(appConnectivityStatusProvider);
  final runState = ref.watch(syncPullRunStateProvider);
  final freshness = ref
      .watch(branchWorkspaceSyncFreshnessProvider)
      .asData
      ?.value;

  return deriveGlobalSyncStatus(
    connectivityStatus: connectivityStatus,
    runState: runState,
    freshness: freshness,
  );
});
