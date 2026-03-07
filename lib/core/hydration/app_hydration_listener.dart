import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/hydration/context_scoped_runtime_resource.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/workspace_context.dart';
import 'package:modular_pos/features/auth/domain/workspace_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_token_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';

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
  String? _lastWorkspaceHydrationKey;

  ProviderSubscription<AuthSession?>? _sessionSubscription;
  ProviderSubscription<String?>? _tenantSubscription;
  ProviderSubscription<String?>? _branchSubscription;
  ProviderSubscription<WorkspaceContext?>? _workspaceSubscription;

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

    _tenantSubscription = ref.listenManual<String?>(
      authTenantIdProvider,
      (_, __) => _refreshBranchScopedStateIfNeeded(),
    );

    _branchSubscription = ref.listenManual<String?>(
      activeBranchContextIdProvider,
      (_, __) => _refreshBranchScopedStateIfNeeded(),
    );

    _workspaceSubscription = ref.listenManual<WorkspaceContext?>(
      workspaceContextProvider,
      (_, __) => _refreshBranchScopedStateIfNeeded(),
    );
  }

  @override
  void dispose() {
    _sessionSubscription?.close();
    _tenantSubscription?.close();
    _branchSubscription?.close();
    _workspaceSubscription?.close();
    super.dispose();
  }

  void _applySession(AuthSession? session) {
    if (session == null) {
      _lastHydrationToken = null;
      _lastHydrationTenantId = null;
      _lastHydrationBranchId = null;
      _lastWorkspaceHydrationKey = null;

      ref.read(authAccessTokenProvider.notifier).clear();
      ref.read(authTenantIdProvider.notifier).clear();
      ref.read(authActiveBranchOverrideProvider.notifier).clear();
      ref.read(workspaceContextProvider.notifier).clear();

      ref.read(policyNotifierProvider.notifier).reset();
      ref.read(cashSessionViewModelProvider.notifier).reset();
      _notifyContextClearedResources();
      return;
    }

    ref.read(authAccessTokenProvider.notifier).setToken(session.accessToken);
    final tenantId = (session.activeTenantId ?? session.user.tenantId).trim();
    ref.read(authTenantIdProvider.notifier).setTenantId(tenantId);

    _refreshBranchScopedStateIfNeeded();
  }

  void _refreshBranchScopedStateIfNeeded() {
    final token = ref.read(authAccessTokenProvider);
    final tenantId = ref.read(authTenantIdProvider);
    final workspaceContext = ref.read(workspaceContextProvider);
    final branchId = ref.read(activeBranchContextIdProvider);
    final workspaceHydrationKey = workspaceContext == null
        ? 'none'
        : '${workspaceContext.scope.name}:${workspaceContext.mode.name}';

    if (token == null || token.isEmpty) return;
    if (tenantId == null || tenantId.isEmpty) return;

    if (workspaceContext?.scope == WorkspaceScope.global) {
      final needsReset =
          _lastHydrationBranchId != null ||
          _lastHydrationToken != token ||
          _lastHydrationTenantId != tenantId ||
          _lastWorkspaceHydrationKey != workspaceHydrationKey;
      _lastHydrationToken = token;
      _lastHydrationTenantId = tenantId;
      _lastHydrationBranchId = null;
      _lastWorkspaceHydrationKey = workspaceHydrationKey;
      if (!needsReset) return;

      ref.read(policyNotifierProvider.notifier).reset();
      ref.read(cashSessionViewModelProvider.notifier).reset();
      _notifyContextClearedResources();
      return;
    }
    if (branchId == null || branchId.isEmpty) return;

    final needsRefresh =
        token != _lastHydrationToken ||
        tenantId != _lastHydrationTenantId ||
        branchId != _lastHydrationBranchId ||
        workspaceHydrationKey != _lastWorkspaceHydrationKey;
    if (!needsRefresh) return;

    _lastHydrationToken = token;
    _lastHydrationTenantId = tenantId;
    _lastHydrationBranchId = branchId;
    _lastWorkspaceHydrationKey = workspaceHydrationKey;

    _notifyContextChangedResources(
      accessToken: token,
      tenantId: tenantId,
      branchId: branchId,
    );

    unawaited(ref.read(policyNotifierProvider.notifier).load());
    unawaited(
      ref
          .read(cashSessionViewModelProvider.notifier)
          .load(branchIdOverride: branchId),
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
