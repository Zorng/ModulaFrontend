import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/sync/sync_checkpoint_store.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/core/sync/sync_pull_trigger_controller.dart';

enum SyncWorkspaceFreshnessKind { syncing, staleUsable, refreshFailed }

class SyncWorkspaceFreshness {
  const SyncWorkspaceFreshness({
    required this.kind,
    required this.message,
    this.lastPullAt,
    this.lastSuccessfulPullAt,
  });

  final SyncWorkspaceFreshnessKind kind;
  final String message;
  final DateTime? lastPullAt;
  final DateTime? lastSuccessfulPullAt;
}

SyncWorkspaceFreshness? deriveSyncWorkspaceFreshness({
  required SyncCheckpointRecord? checkpoint,
  required SyncPullRunState runState,
  required AppConnectivityStatus connectivityStatus,
  required String expectedRunKey,
  required String scopeSetKey,
}) {
  final lastSuccessfulPullAt = checkpoint?.lastSuccessfulPullAt;
  final hasUsableCache = lastSuccessfulPullAt != null;
  if (!hasUsableCache) {
    return null;
  }

  final isMatchingRun =
      runState.moduleScopeSetKey == scopeSetKey &&
      runState.runKey == expectedRunKey;
  if (isMatchingRun && runState.status == SyncPullRunStatus.running) {
    return SyncWorkspaceFreshness(
      kind: SyncWorkspaceFreshnessKind.syncing,
      message: 'Refreshing cached workspace data...',
      lastPullAt: checkpoint?.lastPullAt,
      lastSuccessfulPullAt: lastSuccessfulPullAt,
    );
  }

  if (connectivityStatus == AppConnectivityStatus.offline) {
    return SyncWorkspaceFreshness(
      kind: SyncWorkspaceFreshnessKind.staleUsable,
      message: 'Offline: showing last synced workspace data.',
      lastPullAt: checkpoint?.lastPullAt,
      lastSuccessfulPullAt: lastSuccessfulPullAt,
    );
  }

  if ((checkpoint?.lastPullStatus ?? '').trim().toLowerCase() == 'failed') {
    final isOfflineLike = _isOfflineLike(checkpoint?.lastErrorCode);
    return SyncWorkspaceFreshness(
      kind: isOfflineLike
          ? SyncWorkspaceFreshnessKind.staleUsable
          : SyncWorkspaceFreshnessKind.refreshFailed,
      message: isOfflineLike
          ? 'Offline: showing last synced workspace data.'
          : 'Refresh failed. Showing last synced workspace data.',
      lastPullAt: checkpoint?.lastPullAt,
      lastSuccessfulPullAt: lastSuccessfulPullAt,
    );
  }

  return null;
}

bool _isOfflineLike(String? errorCode) {
  return (errorCode ?? '').trim().toUpperCase() == 'OFFLINE_UNREACHABLE';
}

final branchWorkspaceSyncFreshnessProvider =
    FutureProvider<SyncWorkspaceFreshness?>((ref) async {
      final context = ref.watch(syncPullContextProvider);
      final runState = ref.watch(syncPullRunStateProvider);
      final connectivityStatus = ref.watch(appConnectivityStatusProvider);
      final moduleScopes = ref.watch(syncPullBranchWorkspaceScopesProvider);

      if (context == null || context.branchId.trim().isEmpty) {
        return null;
      }

      final scopeSetKey = buildModuleScopeSetKey(moduleScopes);
      final checkpoint = await ref
          .watch(syncCheckpointStoreProvider)
          .read(
            deviceId: context.deviceId,
            tenantId: context.tenantId,
            branchId: context.branchId,
            accountId: context.accountId,
            moduleScopeSetKey: scopeSetKey,
          );

      return deriveSyncWorkspaceFreshness(
        checkpoint: checkpoint,
        runState: runState,
        connectivityStatus: connectivityStatus,
        expectedRunKey: buildSyncPullRunKey(
          context: context,
          scopeSetKey: scopeSetKey,
        ),
        scopeSetKey: scopeSetKey,
      );
    });
