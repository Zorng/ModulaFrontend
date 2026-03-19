import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/hydration/context_scoped_runtime_resource.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_trigger_controller.dart';
import 'package:modular_pos/core/sync/sync_push_trigger_controller.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_token_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_offline_cash_queue.dart';
import 'package:modular_pos/features/sale/data/sale_outage_store.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_outage_recovery_controller.dart';

/// Bridges authentication context changes (login/logout/tenant/branch) into
/// cross-cutting feature hydration (policy, cash session, etc).
///
/// This exists to avoid side-effects inside provider `build()` methods.
class AppHydrationListener extends ConsumerStatefulWidget {
  const AppHydrationListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppHydrationListener> createState() =>
      _AppHydrationListenerState();
}

class _AppHydrationListenerState extends ConsumerState<AppHydrationListener> {
  String? _lastHydrationToken;
  String? _lastHydrationTenantId;
  String? _lastHydrationBranchId;
  bool _isApplyingSession = false;

  ProviderSubscription<AuthSession?>? _sessionSubscription;
  ProviderSubscription<String?>? _tenantSubscription;
  ProviderSubscription<String?>? _branchSubscription;
  ProviderSubscription<AppConnectivityStatus>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    // Defer initial sync until after the first frame to avoid mutating providers
    // during widget tree construction.
    Future<void>(() {
      if (!mounted) return;
      _applySession(ref.read(loginControllerProvider).session);
    });

    _sessionSubscription = ref.listenManual<AuthSession?>(
      loginControllerProvider.select((s) => s.session),
      (_, next) => _applySession(next),
    );

    _tenantSubscription = ref.listenManual<String?>(authTenantIdProvider, (
      _,
      __,
    ) {
      if (_isApplyingSession) return;
      _refreshBranchScopedStateIfNeeded();
    });

    _branchSubscription = ref.listenManual<String?>(
      activeBranchContextIdProvider,
      (_, __) {
        if (_isApplyingSession) return;
        _refreshBranchScopedStateIfNeeded();
      },
    );

    _connectivitySubscription = ref.listenManual<AppConnectivityStatus>(
      appConnectivityStatusProvider,
      (previous, next) {
        if (previous == AppConnectivityStatus.offline &&
            next == AppConnectivityStatus.online) {
          _handleReconnect();
        }
      },
    );
  }

  @override
  void dispose() {
    _sessionSubscription?.close();
    _tenantSubscription?.close();
    _branchSubscription?.close();
    _connectivitySubscription?.close();
    super.dispose();
  }

  void _applySession(AuthSession? session) {
    _isApplyingSession = true;
    if (session == null) {
      _lastHydrationToken = null;
      _lastHydrationTenantId = null;
      _lastHydrationBranchId = null;

      ref.read(authAccessTokenProvider.notifier).clear();
      ref.read(authTenantIdProvider.notifier).clear();
      ref.read(authActiveBranchOverrideProvider.notifier).clear();

      ref.read(policyNotifierProvider.notifier).reset();
      ref.read(cashSessionViewModelProvider.notifier).reset();
      _notifyContextClearedResources();
      _isApplyingSession = false;
      return;
    }

    ref.read(authAccessTokenProvider.notifier).setToken(session.accessToken);
    final tenantId = (session.activeTenantId ?? session.user.tenantId).trim();
    ref.read(authTenantIdProvider.notifier).setTenantId(tenantId);

    _refreshBranchScopedStateIfNeeded(
      preferredTrigger: _resolveSessionTrigger(session),
    );
    _isApplyingSession = false;
  }

  void _refreshBranchScopedStateIfNeeded({SyncPullTrigger? preferredTrigger}) {
    final session = ref.read(loginControllerProvider).session;
    if (session == null) return;

    final token = ref.read(authAccessTokenProvider);
    final tenantId = ref.read(authTenantIdProvider);
    final branchId = ref.read(activeBranchContextIdProvider);
    final accountId = session.user.id.trim();

    if (token == null || token.isEmpty) return;
    if (tenantId == null || tenantId.isEmpty) return;

    if (branchId == null || branchId.isEmpty) {
      final needsReset =
          _lastHydrationBranchId != null ||
          _lastHydrationToken != token ||
          _lastHydrationTenantId != tenantId;
      _lastHydrationToken = token;
      _lastHydrationTenantId = tenantId;
      _lastHydrationBranchId = null;
      if (!needsReset) return;

      ref.read(policyNotifierProvider.notifier).reset();
      ref.read(cashSessionViewModelProvider.notifier).reset();
      _notifyContextClearedResources();
      return;
    }

    final needsRefresh =
        token != _lastHydrationToken ||
        tenantId != _lastHydrationTenantId ||
        branchId != _lastHydrationBranchId;
    if (!needsRefresh) return;

    final trigger =
        preferredTrigger ??
        _resolveSyncTrigger(
          token: token,
          tenantId: tenantId,
          branchId: branchId,
        );

    _lastHydrationToken = token;
    _lastHydrationTenantId = tenantId;
    _lastHydrationBranchId = branchId;

    _notifyContextChangedResources(
      accessToken: token,
      tenantId: tenantId,
      branchId: branchId,
    );

    unawaited(ref.read(policyNotifierProvider.notifier).load());
    unawaited(ref.read(cashSessionViewModelProvider.notifier).load());
    unawaited(
      _syncAndRecoverBranchWorkspace(
        trigger: trigger,
        tenantId: tenantId,
        branchId: branchId,
        accountId: accountId,
      ),
    );
  }

  SyncPullTrigger _resolveSyncTrigger({
    required String token,
    required String tenantId,
    required String branchId,
  }) {
    final previousToken = (_lastHydrationToken ?? '').trim();
    final previousTenantId = (_lastHydrationTenantId ?? '').trim();
    final previousBranchId = (_lastHydrationBranchId ?? '').trim();

    if (previousToken.isEmpty || token != previousToken) {
      return SyncPullTrigger.hydration;
    }
    if (tenantId != previousTenantId) {
      return SyncPullTrigger.tenantSwitch;
    }
    if (branchId != previousBranchId) {
      return SyncPullTrigger.branchSwitch;
    }
    return SyncPullTrigger.hydration;
  }

  SyncPullTrigger _resolveSessionTrigger(AuthSession session) {
    final nextToken = session.accessToken.trim();
    final nextTenantId = (session.activeTenantId ?? session.user.tenantId)
        .trim();
    final previousToken = (_lastHydrationToken ?? '').trim();
    final previousTenantId = (_lastHydrationTenantId ?? '').trim();

    if (previousToken.isEmpty || nextToken != previousToken) {
      return SyncPullTrigger.hydration;
    }
    if (nextTenantId != previousTenantId) {
      return SyncPullTrigger.tenantSwitch;
    }
    return SyncPullTrigger.branchSwitch;
  }

  Future<void> _triggerBranchWorkspaceSync({
    required SyncPullTrigger trigger,
    required String tenantId,
    required String branchId,
    required String accountId,
  }) async {
    try {
      final deviceId = await ref.read(syncResolvedDeviceIdProvider.future);
      if (!mounted) return;

      final currentTenantId = (ref.read(authTenantIdProvider) ?? '').trim();
      final currentBranchId = (ref.read(activeBranchContextIdProvider) ?? '')
          .trim();
      final currentAccountId =
          (ref.read(loginControllerProvider).session?.user.id ?? '').trim();
      if (currentTenantId != tenantId ||
          currentBranchId != branchId ||
          currentAccountId != accountId) {
        return;
      }

      await ref
          .read(syncPullTriggerControllerProvider)
          .triggerBranchWorkspace(
            trigger: trigger,
            contextOverride: SyncPullContext(
              deviceId: deviceId,
              tenantId: tenantId,
              branchId: branchId,
              accountId: accountId,
            ),
          );
    } catch (error, stackTrace) {
      AppLog.e(
        'Failed to trigger background sync/pull from hydration listener',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _syncAndRecoverBranchWorkspace({
    required SyncPullTrigger trigger,
    required String tenantId,
    required String branchId,
    required String accountId,
  }) async {
    await _triggerBranchWorkspaceSync(
      trigger: trigger,
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
    );
    if (!mounted) return;
    if (ref.read(appConnectivityStatusProvider) !=
        AppConnectivityStatus.online) {
      return;
    }
    await _recoverPendingSaleOutageClaims(
      trigger: SaleOutageRecoveryTrigger.contextChange,
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
    );
  }

  void _handleReconnect() {
    final session = ref.read(loginControllerProvider).session;
    if (session == null) return;

    final token = ref.read(authAccessTokenProvider);
    final tenantId = (ref.read(authTenantIdProvider) ?? '').trim();
    final branchId = (ref.read(activeBranchContextIdProvider) ?? '').trim();
    final accountId = session.user.id.trim();
    if ((token ?? '').trim().isEmpty ||
        tenantId.isEmpty ||
        branchId.isEmpty ||
        accountId.isEmpty) {
      return;
    }

    unawaited(
      _replayOfflineQueueThenSync(
        tenantId: tenantId,
        branchId: branchId,
        accountId: accountId,
      ),
    );
  }

  Future<void> _replayOfflineQueueThenSync({
    required String tenantId,
    required String branchId,
    required String accountId,
  }) async {
    try {
      final deviceId = await ref.read(syncResolvedDeviceIdProvider.future);
      if (!mounted) return;

      final currentTenantId = (ref.read(authTenantIdProvider) ?? '').trim();
      final currentBranchId = (ref.read(activeBranchContextIdProvider) ?? '')
          .trim();
      final currentAccountId =
          (ref.read(loginControllerProvider).session?.user.id ?? '').trim();
      if (currentTenantId != tenantId ||
          currentBranchId != branchId ||
          currentAccountId != accountId) {
        return;
      }

      final context = SyncPullContext(
        deviceId: deviceId,
        tenantId: tenantId,
        branchId: branchId,
        accountId: accountId,
      );
      await ref
          .read(saleOfflineCashQueueProvider)
          .repairQueuedCashReplayPayloads(
            scope: SaleOutageScope(
              tenantId: tenantId,
              branchId: branchId,
              accountId: accountId,
            ),
          );
      final pushResult = await ref
          .read(syncPushTriggerControllerProvider)
          .triggerBranchWorkspace(
            trigger: SyncPushTrigger.reconnect,
            contextOverride: context,
          );
      if (!mounted) return;
      if (pushResult.outcome == SyncPushTriggerOutcome.noPending) {
        await ref
            .read(syncPullTriggerControllerProvider)
            .triggerBranchWorkspace(
              trigger: SyncPullTrigger.reconnect,
              contextOverride: context,
            );
      }
      if (!mounted) return;
      await _recoverPendingSaleOutageClaims(
        trigger: SaleOutageRecoveryTrigger.reconnect,
        tenantId: tenantId,
        branchId: branchId,
        accountId: accountId,
      );
    } catch (error, stackTrace) {
      AppLog.e(
        'Failed to trigger reconnect replay/sync from hydration listener',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _recoverPendingSaleOutageClaims({
    required SaleOutageRecoveryTrigger trigger,
    required String tenantId,
    required String branchId,
    required String accountId,
  }) async {
    final currentTenantId = (ref.read(authTenantIdProvider) ?? '').trim();
    final currentBranchId = (ref.read(activeBranchContextIdProvider) ?? '')
        .trim();
    final currentAccountId =
        (ref.read(loginControllerProvider).session?.user.id ?? '').trim();
    if (currentTenantId != tenantId ||
        currentBranchId != branchId ||
        currentAccountId != accountId) {
      return;
    }

    await ref
        .read(saleOutageRecoveryControllerProvider)
        .recoverBranchWorkspace(
          trigger: trigger,
          scopeOverride: SaleOutageScope(
            tenantId: tenantId,
            branchId: branchId,
            accountId: accountId,
          ),
        );
  }

  void _notifyContextClearedResources() {
    final resources = ref.read(contextScopedRuntimeResourcesProvider);
    for (final resource in resources) {
      unawaited(
        Future<void>.sync(resource.onContextCleared).catchError((error, stack) {
          final stackTrace = stack is StackTrace ? stack : null;
          AppLog.e(
            'Failed to clear context-scoped runtime resource',
            error: error,
            stackTrace: stackTrace,
          );
        }),
      );
    }
  }

  void _notifyContextChangedResources({
    required String accessToken,
    required String tenantId,
    required String branchId,
  }) {
    final resources = ref.read(contextScopedRuntimeResourcesProvider);
    for (final resource in resources) {
      unawaited(
        Future<void>.sync(
          () => resource.onContextChanged(
            accessToken: accessToken,
            tenantId: tenantId,
            branchId: branchId,
          ),
        ).catchError((error, stack) {
          final stackTrace = stack is StackTrace ? stack : null;
          AppLog.e(
            'Failed to rebind context-scoped runtime resource',
            error: error,
            stackTrace: stackTrace,
          );
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
