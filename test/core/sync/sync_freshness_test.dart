import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/sync/sync_checkpoint_store.dart';
import 'package:modular_pos/core/sync/sync_freshness.dart';
import 'package:modular_pos/core/sync/sync_models.dart';

void main() {
  const context = SyncPullContext(
    deviceId: 'device-1',
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    accountId: 'account-1',
  );
  const scopeSetKey = 'attendance|cashSession|menu|policy|shift';
  final runKey = buildSyncPullRunKey(
    context: context,
    scopeSetKey: scopeSetKey,
  );

  test(
    'deriveSyncWorkspaceFreshness returns syncing for active matching run',
    () {
      final freshness = deriveSyncWorkspaceFreshness(
        checkpoint: SyncCheckpointRecord(
          deviceId: context.deviceId,
          tenantId: context.tenantId,
          branchId: context.branchId,
          accountId: context.accountId,
          moduleScopeSetKey: scopeSetKey,
          lastPullAt: DateTime.utc(2026, 3, 17, 8),
          lastSuccessfulPullAt: DateTime.utc(2026, 3, 17, 8),
          lastPullStatus: 'success',
        ),
        runState: SyncPullRunState(
          status: SyncPullRunStatus.running,
          moduleScopeSetKey: scopeSetKey,
          runKey: runKey,
        ),
        connectivityStatus: AppConnectivityStatus.online,
        expectedRunKey: runKey,
        scopeSetKey: scopeSetKey,
      );

      expect(freshness?.kind, SyncWorkspaceFreshnessKind.syncing);
    },
  );

  test(
    'deriveSyncWorkspaceFreshness returns staleUsable when offline with last successful sync',
    () {
      final freshness = deriveSyncWorkspaceFreshness(
        checkpoint: SyncCheckpointRecord(
          deviceId: context.deviceId,
          tenantId: context.tenantId,
          branchId: context.branchId,
          accountId: context.accountId,
          moduleScopeSetKey: scopeSetKey,
          lastPullAt: DateTime.utc(2026, 3, 17, 8),
          lastSuccessfulPullAt: DateTime.utc(2026, 3, 17, 8),
          lastPullStatus: 'success',
        ),
        runState: const SyncPullRunState(),
        connectivityStatus: AppConnectivityStatus.offline,
        expectedRunKey: runKey,
        scopeSetKey: scopeSetKey,
      );

      expect(freshness?.kind, SyncWorkspaceFreshnessKind.staleUsable);
    },
  );

  test(
    'deriveSyncWorkspaceFreshness returns refreshFailed after failed refresh with usable cache',
    () {
      final freshness = deriveSyncWorkspaceFreshness(
        checkpoint: SyncCheckpointRecord(
          deviceId: context.deviceId,
          tenantId: context.tenantId,
          branchId: context.branchId,
          accountId: context.accountId,
          moduleScopeSetKey: scopeSetKey,
          lastPullAt: DateTime.utc(2026, 3, 17, 9),
          lastSuccessfulPullAt: DateTime.utc(2026, 3, 17, 8),
          lastPullStatus: 'failed',
          lastErrorCode: 'LOCAL_APPLY_FAILED',
        ),
        runState: const SyncPullRunState(),
        connectivityStatus: AppConnectivityStatus.online,
        expectedRunKey: runKey,
        scopeSetKey: scopeSetKey,
      );

      expect(freshness?.kind, SyncWorkspaceFreshnessKind.refreshFailed);
    },
  );
}
