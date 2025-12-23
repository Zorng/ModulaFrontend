import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_token_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';

class LoginState {
  final bool isLoading;
  final AuthSession? session;
  final String? error;

  const LoginState({
    this.isLoading = false,
    this.session,
    this.error,
  });

  User? get user => session?.user;

  LoginState copyWith({
    bool? isLoading,
    AuthSession? session,
    String? error,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      error: error,
    );
  }
}

final loginControllerProvider = StateNotifierProvider<LoginController, LoginState>((ref) {
  final repository = ref.read(authRepositoryProvider);
  final store = ref.read(authSessionStoreProvider);
  final initialSession = ref.read(initialAuthSessionProvider);
  return LoginController(
    ref: ref,
    repository: repository,
    sessionStore: store,
    initialSession: initialSession,
  );
});

class LoginController extends StateNotifier<LoginState> {
  LoginController({
    required this.ref,
    required AuthRepository repository,
    required AuthSessionStore sessionStore,
    AuthSession? initialSession,
  })  : _repository = repository,
        _sessionStore = sessionStore,
        super(LoginState(session: initialSession)) {
    if (initialSession != null) {
      // Defer provider updates to avoid mutating providers during build.
      Future.microtask(() {
        _applySessionContext(initialSession);
        final branchId = _resolveBranchId(initialSession);
        _resetPolicies();
        _refreshPolicies(branchId: branchId);
        _refreshCashSession(initialSession, branchId: branchId);
      });
    }
  }

  final Ref ref;
  final AuthRepository _repository;
  final AuthSessionStore _sessionStore;

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final session = await _repository.login(username, password);
      // Only persist fully-established sessions.
      if (!session.requiresTenantSelection && session.accessToken.trim().isNotEmpty) {
        await _sessionStore.save(session);
      }
      _applySessionContext(session);
      final branchId = _resolveBranchId(session);
      _resetPolicies();
      _refreshPolicies(branchId: branchId);
      _refreshCashSession(session, branchId: branchId);

      state = state.copyWith(isLoading: false, session: session);
    } catch (e, st) {
      assert(() {
        // ignore: avoid_print
        print('Login failed: $e');
        // ignore: avoid_print
        print(st);
        return true;
      }());
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed', // you can inspect e for more details
      );
    }
  }

  void _applySessionContext(AuthSession session) {
    final token = session.accessToken.trim();
    ref.read(authAccessTokenProvider.notifier).state =
        token.isEmpty ? null : token;

    final tenantId = (session.activeTenantId ?? session.user.tenantId).trim();
    ref.read(authTenantIdProvider.notifier).state =
        tenantId.isEmpty ? null : tenantId;
  }

  void _resetPolicies() {
    try {
      ref.invalidate(policyNotifierProvider);
    } catch (err, st) {
      assert(() {
        // ignore: avoid_print
        print('Failed to reset policies: $err');
        // ignore: avoid_print
        print(st);
        return true;
      }());
    }
  }

  void _refreshPolicies({String? branchId}) {
    try {
      ref.read(policyNotifierProvider.notifier).load(branchId: branchId);
    } catch (err, st) {
      assert(() {
        // ignore: avoid_print
        print('Failed to refresh policies: $err');
        // ignore: avoid_print
        print(st);
        return true;
      }());
    }
  }

  void _refreshCashSession(AuthSession session, {String? branchId}) {
    if (session.accessToken.trim().isEmpty || session.requiresTenantSelection) {
      return;
    }
    try {
      ref.read(cashSessionViewModelProvider.notifier).load(
            branchIdOverride: branchId,
          );
    } catch (err, st) {
      assert(() {
        // ignore: avoid_print
        print('Failed to refresh cash session: $err');
        // ignore: avoid_print
        print(st);
        return true;
      }());
    }
  }

  String? _resolveBranchId(AuthSession session) {
    final branches = session.user.branches;
    if (branches.isEmpty) return null;
    final active = branches.firstWhere(
      (b) => b.active && (b.branchId.isNotEmpty || b.id.isNotEmpty),
      orElse: () => branches.first,
    );
    final id = active.branchId.isNotEmpty ? active.branchId : active.id;
    return id.isNotEmpty ? id : null;
  }

  Future<void> selectTenant(String tenantId) async {
    final current = state.session;
    if (current == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      if (current.tenantSelectionToken.trim().isNotEmpty) {
        final selected = await _repository.selectTenant(
          selectionToken: current.tenantSelectionToken,
          tenantId: tenantId,
        );

        final nextSession = selected.copyWith(
          memberships: current.memberships.isNotEmpty ? current.memberships : selected.memberships,
          activeTenantId: tenantId,
          tenantSelectionToken: '',
        );

        await _sessionStore.save(nextSession);
        _applySessionContext(nextSession);
        final branchId = _resolveBranchId(nextSession);
        _resetPolicies();
        _refreshPolicies(branchId: branchId);
        _refreshCashSession(nextSession, branchId: branchId);
        state = state.copyWith(isLoading: false, session: nextSession);
        return;
      }

      TenantMembership? membership;
      for (final m in current.memberships) {
        if (m.tenantId == tenantId) {
          membership = m;
          break;
        }
      }
      if (membership == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final nextUser = current.user.copyWith(
        tenantId: membership.tenantId,
        role: membership.role.isNotEmpty ? membership.role : current.user.role,
        branches: membership.branches,
      );
      final nextSession = current.copyWith(
        user: nextUser,
        activeTenantId: membership.tenantId,
      );

      await _sessionStore.save(nextSession);
      _applySessionContext(nextSession);
      final branchId = _resolveBranchId(nextSession);
      _resetPolicies();
      _refreshPolicies(branchId: branchId);
      _refreshCashSession(nextSession, branchId: branchId);
      state = state.copyWith(isLoading: false, session: nextSession);
    } catch (e, st) {
      assert(() {
        // ignore: avoid_print
        print('Tenant selection failed: $e');
        // ignore: avoid_print
        print(st);
        return true;
      }());
      state = state.copyWith(isLoading: false, error: 'Tenant selection failed');
    }
  }

  Future<void> logout() async {
    await _sessionStore.clear();
    ref.read(authAccessTokenProvider.notifier).state = null;
    ref.read(authTenantIdProvider.notifier).state = null;
    // Clear dependent state so a subsequent login always hydrates fresh data.
    _resetPolicies();
    try {
      ref.invalidate(cashSessionViewModelProvider);
    } catch (_) {}
    state = const LoginState();
  }
}
