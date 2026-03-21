import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/core/sync/sync_pull_trigger_controller.dart';
import 'package:modular_pos/core/sync/sync_push_api.dart';
import 'package:uuid/uuid.dart';

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
  static const Uuid _uuid = Uuid();
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  Future<SyncPushReplayResult> replayPending({
    required SyncPullContext context,
    int limit = 50,
  }) async {
    final queuedRecords = await _queueStore.listReplayReadyForContext(
      tenantId: context.tenantId,
      branchId: context.branchId,
      accountId: context.accountId,
      limit: limit,
    );
    if (queuedRecords.isEmpty) {
      return const SyncPushReplayResult(
        outcome: SyncPushReplayOutcome.noPending,
        totalCount: 0,
      );
    }

    final queue = await _repairLegacyClientOpIds(queuedRecords);

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
                payloadJson: _payloadJsonWithResultRefId(
                  record: record,
                  resultRefId: result.resultRefId,
                ),
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
                payloadJson: _payloadJsonWithResultRefId(
                  record: record,
                  resultRefId: result.resultRefId,
                ),
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

  Future<List<OfflineCommandRecord>> _repairLegacyClientOpIds(
    List<OfflineCommandRecord> queue,
  ) async {
    if (queue.isEmpty) return queue;

    final remappedIds = <String, String>{};
    final repairedQueue = <OfflineCommandRecord>[...queue];

    for (var index = 0; index < repairedQueue.length; index += 1) {
      final record = repairedQueue[index];
      final currentClientOpId = record.clientOpId.trim();
      if (_uuidPattern.hasMatch(currentClientOpId)) continue;

      final nextClientOpId = _uuid.v4();
      remappedIds[currentClientOpId] = nextClientOpId;

      final repairedRecord = record.copyWith(
        clientOpId: nextClientOpId,
        payloadJson: _repairPayloadJson(
          record: record,
          previousClientOpId: currentClientOpId,
          nextClientOpId: nextClientOpId,
        ),
      );

      await _queueStore.delete(currentClientOpId);
      await _queueStore.write(repairedRecord);
      repairedQueue[index] = repairedRecord;
    }

    if (remappedIds.isEmpty) return repairedQueue;

    for (var index = 0; index < repairedQueue.length; index += 1) {
      final record = repairedQueue[index];
      final dependency = (record.dependsOnClientOpId ?? '').trim();
      final remappedDependency = remappedIds[dependency];
      if (remappedDependency == null || remappedDependency == dependency) {
        continue;
      }
      final updatedRecord = record.copyWith(
        dependsOnClientOpId: remappedDependency,
      );
      await _queueStore.write(updatedRecord);
      repairedQueue[index] = updatedRecord;
    }

    return repairedQueue;
  }

  String _repairPayloadJson({
    required OfflineCommandRecord record,
    required String previousClientOpId,
    required String nextClientOpId,
  }) {
    final payload = _decodePayloadJson(record.payloadJson);
    if (payload == null) return record.payloadJson;

    var changed = false;
    final nestedClientOpId = (payload['clientOpId'] ?? '').toString().trim();
    if (nestedClientOpId == previousClientOpId) {
      payload['clientOpId'] = nextClientOpId;
      changed = true;
    }

    if (record.operationType == OfflineOperationType.checkoutCashFinalize) {
      final localIntentId = (payload['localIntentId'] ?? '').toString().trim();
      if (localIntentId.isEmpty) {
        payload['localIntentId'] = previousClientOpId;
        changed = true;
      }
    }

    if (record.operationType ==
        OfflineOperationType.orderManualExternalPaymentClaimCapture) {
      final localIntentId = (payload['localIntentId'] ?? '').toString().trim();
      if (localIntentId.isEmpty) {
        payload['localIntentId'] = previousClientOpId;
        changed = true;
      }
    }

    return changed ? jsonEncode(payload) : record.payloadJson;
  }

  String _payloadJsonWithResultRefId({
    required OfflineCommandRecord record,
    required String? resultRefId,
  }) {
    final normalizedResultRefId = (resultRefId ?? '').trim();
    if (normalizedResultRefId.isEmpty) return record.payloadJson;
    final payload =
        _decodePayloadJson(record.payloadJson) ?? <String, dynamic>{};
    if ((payload['resultRefId'] ?? '').toString().trim() ==
        normalizedResultRefId) {
      return record.payloadJson;
    }
    payload['resultRefId'] = normalizedResultRefId;
    return jsonEncode(payload);
  }

  Map<String, dynamic>? _decodePayloadJson(String payloadJson) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded);
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      // Keep corrupt payloads intact; push will surface the real error.
    }
    return null;
  }
}
