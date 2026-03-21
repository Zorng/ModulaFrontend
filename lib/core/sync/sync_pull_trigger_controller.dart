import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';

enum SyncPullTrigger { hydration, tenantSwitch, branchSwitch, reconnect }

enum SyncPullTriggerOutcome {
  success,
  skippedNoContext,
  skippedNoBranchContext,
  skippedNoScopes,
  skippedInFlight,
  skippedCooldown,
  failed,
}

class SyncPullTriggerResult {
  const SyncPullTriggerResult({
    required this.trigger,
    required this.outcome,
    this.context,
    this.moduleScopes = const <SyncModuleScope>{},
    this.errorCode,
  });

  final SyncPullTrigger trigger;
  final SyncPullTriggerOutcome outcome;
  final SyncPullContext? context;
  final Set<SyncModuleScope> moduleScopes;
  final String? errorCode;
}

typedef SyncPullNow = DateTime Function();

final syncPullTriggerNowProvider = Provider<SyncPullNow>((ref) {
  return DateTime.now;
});

final syncPullTriggerCooldownProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 5);
});

final syncPullBranchWorkspaceScopesProvider = Provider<Set<SyncModuleScope>>((
  ref,
) {
  return const {
    SyncModuleScope.policy,
    SyncModuleScope.cashSession,
    SyncModuleScope.menu,
    SyncModuleScope.attendance,
    SyncModuleScope.shift,
  };
});

final syncPullTriggerControllerProvider = Provider<SyncPullTriggerController>((
  ref,
) {
  return SyncPullTriggerController(
    orchestrator: ref.watch(syncPullOrchestratorProvider),
    readContext: () => ref.read(syncPullContextProvider),
    readBranchWorkspaceScopes: () =>
        ref.read(syncPullBranchWorkspaceScopesProvider),
    now: ref.read(syncPullTriggerNowProvider),
    cooldown: ref.read(syncPullTriggerCooldownProvider),
  );
});

class SyncPullTriggerController {
  SyncPullTriggerController({
    required SyncPullOrchestrator orchestrator,
    required SyncPullContext? Function() readContext,
    required Set<SyncModuleScope> Function() readBranchWorkspaceScopes,
    required SyncPullNow now,
    required Duration cooldown,
  }) : _orchestrator = orchestrator,
       _readContext = readContext,
       _readBranchWorkspaceScopes = readBranchWorkspaceScopes,
       _now = now,
       _cooldown = cooldown;

  final SyncPullOrchestrator _orchestrator;
  final SyncPullContext? Function() _readContext;
  final Set<SyncModuleScope> Function() _readBranchWorkspaceScopes;
  final SyncPullNow _now;
  final Duration _cooldown;

  final Set<String> _inFlightKeys = <String>{};
  final Map<String, DateTime> _lastSuccessfulRunAtByKey = <String, DateTime>{};

  Future<SyncPullTriggerResult> triggerBranchWorkspace({
    required SyncPullTrigger trigger,
    SyncPullContext? contextOverride,
    bool forceBootstrap = false,
  }) {
    final context = contextOverride ?? _readContext();
    if (context == null) {
      return Future.value(
        SyncPullTriggerResult(
          trigger: trigger,
          outcome: SyncPullTriggerOutcome.skippedNoContext,
        ),
      );
    }
    if (context.branchId.trim().isEmpty) {
      return Future.value(
        SyncPullTriggerResult(
          trigger: trigger,
          outcome: SyncPullTriggerOutcome.skippedNoBranchContext,
          context: context,
        ),
      );
    }
    return triggerForContext(
      trigger: trigger,
      context: context,
      moduleScopes: _readBranchWorkspaceScopes(),
      forceBootstrap: forceBootstrap,
    );
  }

  Future<SyncPullTriggerResult> triggerForContext({
    required SyncPullTrigger trigger,
    required SyncPullContext context,
    required Set<SyncModuleScope> moduleScopes,
    bool forceBootstrap = false,
  }) async {
    final normalizedScopes = moduleScopes.toSet();
    if (normalizedScopes.isEmpty) {
      return SyncPullTriggerResult(
        trigger: trigger,
        outcome: SyncPullTriggerOutcome.skippedNoScopes,
        context: context,
      );
    }

    final scopeSetKey = buildModuleScopeSetKey(normalizedScopes);
    final runKey = _buildRunKey(context: context, scopeSetKey: scopeSetKey);
    if (_inFlightKeys.contains(runKey)) {
      return SyncPullTriggerResult(
        trigger: trigger,
        outcome: SyncPullTriggerOutcome.skippedInFlight,
        context: context,
        moduleScopes: normalizedScopes,
      );
    }

    final lastSuccessfulRunAt = _lastSuccessfulRunAtByKey[runKey];
    final currentTime = _now();
    if (!forceBootstrap &&
        lastSuccessfulRunAt != null &&
        currentTime.difference(lastSuccessfulRunAt) < _cooldown) {
      return SyncPullTriggerResult(
        trigger: trigger,
        outcome: SyncPullTriggerOutcome.skippedCooldown,
        context: context,
        moduleScopes: normalizedScopes,
      );
    }

    _inFlightKeys.add(runKey);
    try {
      await _orchestrator.pull(
        context: context,
        moduleScopes: normalizedScopes,
        forceBootstrap: forceBootstrap,
      );
      _lastSuccessfulRunAtByKey[runKey] = _now();
      return SyncPullTriggerResult(
        trigger: trigger,
        outcome: SyncPullTriggerOutcome.success,
        context: context,
        moduleScopes: normalizedScopes,
      );
    } catch (error, stackTrace) {
      final errorCode = _errorCode(error);
      AppLog.e(
        'Automatic sync/pull trigger failed',
        error: error,
        stackTrace: stackTrace,
      );
      return SyncPullTriggerResult(
        trigger: trigger,
        outcome: SyncPullTriggerOutcome.failed,
        context: context,
        moduleScopes: normalizedScopes,
        errorCode: errorCode,
      );
    } finally {
      _inFlightKeys.remove(runKey);
    }
  }

  String _buildRunKey({
    required SyncPullContext context,
    required String scopeSetKey,
  }) {
    return [
      context.deviceId.trim(),
      context.tenantId.trim(),
      context.branchId.trim(),
      context.accountId.trim(),
      scopeSetKey,
    ].join('|');
  }

  String _errorCode(Object error) {
    if (error is ApiClientException) {
      final normalizedCode = (error.code ?? '').trim();
      return normalizedCode.isNotEmpty ? normalizedCode : 'SYNC_PULL_FAILED';
    }
    return 'LOCAL_APPLY_FAILED';
  }
}
