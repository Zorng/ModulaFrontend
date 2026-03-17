import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/core/sync/sync_pull_trigger_controller.dart';
import 'package:modular_pos/core/sync/sync_push_api.dart';

enum SyncPushReplayOutcome {
  noPending,
  success,
  partialFailure,
  pushFailed,
  pullFailed,
}

class SyncPushReplayResult {
  const SyncPushReplayResult({
    required this.outcome,
    required this.totalCount,
    this.appliedCount = 0,
    this.duplicateCount = 0,
    this.failedCount = 0,
    this.pushErrorCode,
    this.pullErrorCode,
  });

  final SyncPushReplayOutcome outcome;
  final int totalCount;
  final int appliedCount;
  final int duplicateCount;
  final int failedCount;
  final String? pushErrorCode;
  final String? pullErrorCode;
}

final syncPushCoordinatorProvider = Provider<SyncPushCoordinator>((ref) {
  return SyncPushCoordinator(
    queueStore: ref.read(offlineCommandQueueStoreProvider),
    api: ref.read(syncPushApiProvider),
    pullOrchestrator: ref.read(syncPullOrchestratorProvider),
    readBranchWorkspaceScopes: () =>
        ref.read(syncPullBranchWorkspaceScopesProvider),
  );
});

class SyncPushCoordinator {
  SyncPushCoordinator({
    required OfflineCommandQueueStore queueStore,
    required SyncPushApi api,
    required SyncPullOrchestrator pullOrchestrator,
    required Set<SyncModuleScope> Function() readBranchWorkspaceScopes,
  }) : _queueStore = queueStore,
       _api = api,
       _pullOrchestrator = pullOrchestrator,
       _readBranchWorkspaceScopes = readBranchWorkspaceScopes;

  final OfflineCommandQueueStore _queueStore;
  final SyncPushApi _api;
  final SyncPullOrchestrator _pullOrchestrator;
  final Set<SyncModuleScope> Function() _readBranchWorkspaceScopes;

  Future<SyncPushReplayResult> replayPending({
    required SyncPullContext context,
    int limit = 50,
  }) async {
    final queue = await _queueStore.listReplayReadyForContext(
      tenantId: context.tenantId,
      branchId: context.branchId,
      accountId: context.accountId,
      limit: limit,
    );
    if (queue.isEmpty) {
      return const SyncPushReplayResult(
        outcome: SyncPushReplayOutcome.noPending,
        totalCount: 0,
      );
    }

    final startedAt = DateTime.now();
    for (final record in queue) {
      await _queueStore.write(
        record.copyWith(
          status: OfflineCommandQueueStatus.syncing,
          retryCount: record.retryCount + 1,
          updatedAt: startedAt,
          lastAttemptAt: startedAt,
          lastErrorCode: null,
          lastErrorMessage: null,
        ),
      );
    }

    try {
      final envelope = await _api.push(context: context, operations: queue);
      final resultsById = {
        for (final result in envelope.results) result.clientOpId: result,
      };
      if (!queue.every(
        (record) => resultsById.containsKey(record.clientOpId),
      )) {
        throw const ApiClientException(
          message: 'Push sync response did not include every queued operation.',
          code: 'SYNC_PUSH_INVALID_RESPONSE',
        );
      }

      var appliedCount = 0;
      var duplicateCount = 0;
      var failedCount = 0;
      for (final record in queue) {
        final result = resultsById[record.clientOpId]!;
        switch (result.status) {
          case SyncPushResultStatus.applied:
            appliedCount += 1;
            await _queueStore.write(
              record.copyWith(
                status: OfflineCommandQueueStatus.applied,
                updatedAt: envelope.pushedAt,
                lastSyncedAt: envelope.pushedAt,
                lastErrorCode: null,
                lastErrorMessage: null,
              ),
            );
            break;
          case SyncPushResultStatus.duplicate:
            duplicateCount += 1;
            await _queueStore.write(
              record.copyWith(
                status: OfflineCommandQueueStatus.duplicate,
                updatedAt: envelope.pushedAt,
                lastSyncedAt: envelope.pushedAt,
                lastErrorCode: null,
                lastErrorMessage: null,
              ),
            );
            break;
          case SyncPushResultStatus.failed:
            failedCount += 1;
            await _queueStore.write(
              record.copyWith(
                status: OfflineCommandQueueStatus.failed,
                updatedAt: envelope.pushedAt,
                lastErrorCode: (result.errorCode ?? '').trim().isEmpty
                    ? 'SYNC_PUSH_OPERATION_FAILED'
                    : result.errorCode,
                lastErrorMessage: result.errorMessage,
              ),
            );
            break;
        }
      }

      final shouldPull = (appliedCount + duplicateCount) > 0;
      if (!shouldPull) {
        return SyncPushReplayResult(
          outcome: failedCount > 0
              ? SyncPushReplayOutcome.partialFailure
              : SyncPushReplayOutcome.success,
          totalCount: queue.length,
          appliedCount: appliedCount,
          duplicateCount: duplicateCount,
          failedCount: failedCount,
        );
      }

      try {
        await _pullOrchestrator.pull(
          context: context,
          moduleScopes: _readBranchWorkspaceScopes(),
        );
      } catch (error) {
        return SyncPushReplayResult(
          outcome: SyncPushReplayOutcome.pullFailed,
          totalCount: queue.length,
          appliedCount: appliedCount,
          duplicateCount: duplicateCount,
          failedCount: failedCount,
          pullErrorCode: _errorCode(error, fallback: 'SYNC_PULL_FAILED'),
        );
      }

      return SyncPushReplayResult(
        outcome: failedCount > 0
            ? SyncPushReplayOutcome.partialFailure
            : SyncPushReplayOutcome.success,
        totalCount: queue.length,
        appliedCount: appliedCount,
        duplicateCount: duplicateCount,
        failedCount: failedCount,
      );
    } catch (error) {
      final failedAt = DateTime.now();
      final errorCode = _errorCode(error, fallback: 'SYNC_PUSH_FAILED');
      final errorMessage = _errorMessage(error);
      for (final record in queue) {
        await _queueStore.write(
          record.copyWith(
            status: OfflineCommandQueueStatus.pending,
            updatedAt: failedAt,
            lastErrorCode: errorCode,
            lastErrorMessage: errorMessage,
          ),
        );
      }
      return SyncPushReplayResult(
        outcome: SyncPushReplayOutcome.pushFailed,
        totalCount: queue.length,
        pushErrorCode: errorCode,
      );
    }
  }

  String _errorCode(Object error, {required String fallback}) {
    if (error is ApiClientException) {
      final normalized = (error.code ?? '').trim();
      return normalized.isNotEmpty ? normalized : fallback;
    }
    return fallback;
  }

  String? _errorMessage(Object error) {
    if (error is ApiClientException) {
      final normalized = error.message.trim();
      return normalized.isEmpty ? null : normalized;
    }
    final message = error.toString().trim();
    return message.isEmpty ? null : message;
  }
}
