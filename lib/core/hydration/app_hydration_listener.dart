import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
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

  ProviderSubscription<AuthSession?>? _sessionSubscription;
  ProviderSubscription<String?>? _tenantSubscription;
  ProviderSubscription<String?>? _branchSubscription;

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
      authActiveBranchIdProvider,
      (_, __) => _refreshBranchScopedStateIfNeeded(),
    );
  }

  @override
  void dispose() {
    _sessionSubscription?.close();
    _tenantSubscription?.close();
    _branchSubscription?.close();
    super.dispose();
  }

  void _applySession(AuthSession? session) {
    if (session == null) {
      _lastHydrationToken = null;
      _lastHydrationTenantId = null;
      _lastHydrationBranchId = null;

      ref.read(authAccessTokenProvider.notifier).clear();
      ref.read(authTenantIdProvider.notifier).clear();
      ref.read(authActiveBranchOverrideProvider.notifier).clear();

      ref.read(policyNotifierProvider.notifier).reset();
      ref.read(cashSessionViewModelProvider.notifier).reset();
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
    final branchId = ref.read(authActiveBranchIdProvider);

    if (token == null || token.isEmpty) return;
    if (tenantId == null || tenantId.isEmpty) return;
    if (branchId == null || branchId.isEmpty) return;

    final needsRefresh =
        token != _lastHydrationToken ||
        tenantId != _lastHydrationTenantId ||
        branchId != _lastHydrationBranchId;
    if (!needsRefresh) return;

    _lastHydrationToken = token;
    _lastHydrationTenantId = tenantId;
    _lastHydrationBranchId = branchId;

    unawaited(
      ref.read(policyNotifierProvider.notifier).load(branchId: branchId),
    );
    unawaited(
      ref
          .read(cashSessionViewModelProvider.notifier)
          .load(branchIdOverride: branchId),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
