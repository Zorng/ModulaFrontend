import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_push_coordinator.dart';

enum SyncPushTrigger { reconnect, manual }

enum SyncPushTriggerOutcome {
  success,
  noPending,
  partialFailure,
  pushFailed,
  pullFailed,
  skippedNoContext,
  skippedNoBranchContext,
  skippedInFlight,
  skippedCooldown,
}

class SyncPushTriggerResult {
  const SyncPushTriggerResult({
    required this.trigger,
    required this.outcome,
    this.context,
    this.replayResult,
    this.errorCode,
  });

  final SyncPushTrigger trigger;
  final SyncPushTriggerOutcome outcome;
  final SyncPullContext? context;
  final SyncPushReplayResult? replayResult;
  final String? errorCode;
}

typedef SyncPushNow = DateTime Function();

final syncPushTriggerNowProvider = Provider<SyncPushNow>((ref) {
  return DateTime.now;
});

final syncPushTriggerCooldownProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 5);
});

final syncPushTriggerControllerProvider = Provider<SyncPushTriggerController>((
  ref,
) {
  return SyncPushTriggerController(
    coordinator: ref.watch(syncPushCoordinatorProvider),
    readContext: () => ref.read(syncPullContextProvider),
    now: ref.read(syncPushTriggerNowProvider),
    cooldown: ref.read(syncPushTriggerCooldownProvider),
  );
});

class SyncPushTriggerController {
  SyncPushTriggerController({
    required SyncPushCoordinator coordinator,
    required SyncPullContext? Function() readContext,
    required SyncPushNow now,
    required Duration cooldown,
  }) : _coordinator = coordinator,
       _readContext = readContext,
       _now = now,
       _cooldown = cooldown;

  final SyncPushCoordinator _coordinator;
  final SyncPullContext? Function() _readContext;
  final SyncPushNow _now;
  final Duration _cooldown;

  final Set<String> _inFlightKeys = <String>{};
  final Map<String, DateTime> _lastCompletedAtByKey = <String, DateTime>{};

  Future<SyncPushTriggerResult> triggerBranchWorkspace({
    required SyncPushTrigger trigger,
    SyncPullContext? contextOverride,
    bool bypassCooldown = false,
    int limit = 50,
  }) {
    final context = contextOverride ?? _readContext();
    if (context == null) {
      return Future.value(
        SyncPushTriggerResult(
          trigger: trigger,
          outcome: SyncPushTriggerOutcome.skippedNoContext,
        ),
      );
    }
    if (context.branchId.trim().isEmpty) {
      return Future.value(
        SyncPushTriggerResult(
          trigger: trigger,
          outcome: SyncPushTriggerOutcome.skippedNoBranchContext,
          context: context,
        ),
      );
    }
    return triggerForContext(
      trigger: trigger,
      context: context,
      bypassCooldown: bypassCooldown,
      limit: limit,
    );
  }

  Future<SyncPushTriggerResult> manualFlushBranchWorkspace({
    SyncPullContext? contextOverride,
    int limit = 50,
  }) {
    return triggerBranchWorkspace(
      trigger: SyncPushTrigger.manual,
      contextOverride: contextOverride,
      bypassCooldown: true,
      limit: limit,
    );
  }

  Future<SyncPushTriggerResult> triggerForContext({
    required SyncPushTrigger trigger,
    required SyncPullContext context,
    bool bypassCooldown = false,
    int limit = 50,
  }) async {
    final runKey = _buildRunKey(context);
    if (_inFlightKeys.contains(runKey)) {
      return SyncPushTriggerResult(
        trigger: trigger,
        outcome: SyncPushTriggerOutcome.skippedInFlight,
        context: context,
      );
    }

    final currentTime = _now();
    final lastCompletedAt = _lastCompletedAtByKey[runKey];
    if (!bypassCooldown &&
        lastCompletedAt != null &&
        currentTime.difference(lastCompletedAt) < _cooldown) {
      return SyncPushTriggerResult(
        trigger: trigger,
        outcome: SyncPushTriggerOutcome.skippedCooldown,
        context: context,
      );
    }

    _inFlightKeys.add(runKey);
    try {
      final replayResult = await _coordinator.replayPending(
        context: context,
        limit: limit,
      );
      _lastCompletedAtByKey[runKey] = _now();
      return SyncPushTriggerResult(
        trigger: trigger,
        outcome: _mapOutcome(replayResult.outcome),
        context: context,
        replayResult: replayResult,
        errorCode: replayResult.pushErrorCode ?? replayResult.pullErrorCode,
      );
    } catch (error, stackTrace) {
      final errorCode = _errorCode(error);
      AppLog.e(
        'Automatic sync/push trigger failed',
        error: error,
        stackTrace: stackTrace,
      );
      return SyncPushTriggerResult(
        trigger: trigger,
        outcome: SyncPushTriggerOutcome.pushFailed,
        context: context,
        errorCode: errorCode,
      );
    } finally {
      _inFlightKeys.remove(runKey);
    }
  }

  String _buildRunKey(SyncPullContext context) {
    return [
      context.deviceId.trim(),
      context.tenantId.trim(),
      context.branchId.trim(),
      context.accountId.trim(),
    ].join('|');
  }

  SyncPushTriggerOutcome _mapOutcome(SyncPushReplayOutcome outcome) {
    switch (outcome) {
      case SyncPushReplayOutcome.noPending:
        return SyncPushTriggerOutcome.noPending;
      case SyncPushReplayOutcome.success:
        return SyncPushTriggerOutcome.success;
      case SyncPushReplayOutcome.partialFailure:
        return SyncPushTriggerOutcome.partialFailure;
      case SyncPushReplayOutcome.pushFailed:
        return SyncPushTriggerOutcome.pushFailed;
      case SyncPushReplayOutcome.pullFailed:
        return SyncPushTriggerOutcome.pullFailed;
    }
  }

  String _errorCode(Object error) {
    if (error is ApiClientException) {
      final normalizedCode = (error.code ?? '').trim();
      return normalizedCode.isNotEmpty ? normalizedCode : 'SYNC_PUSH_FAILED';
    }
    return 'SYNC_PUSH_FAILED';
  }
}
