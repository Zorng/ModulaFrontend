import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_token_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

class LoginState {
  final bool isLoading;
  final AuthSession? session;
  final String? error;

  const LoginState({this.isLoading = false, this.session, this.error});

  User? get user => session?.user;

  LoginState copyWith({bool? isLoading, AuthSession? session, String? error}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      error: error,
    );
  }
}

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

class LoginController extends Notifier<LoginState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  AuthSessionStore get _sessionStore => ref.read(authSessionStoreProvider);

  @override
  LoginState build() {
    final initialSession = ref.read(initialAuthSessionProvider);
    if (initialSession != null) {
      Future.microtask(() => _applySessionContext(initialSession));
    } else {
      Future.microtask(_clearSessionContext);
    }
    return LoginState(session: initialSession);
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final session = await _repository.login(username, password);
      // Only persist fully-established sessions.
      if (!session.requiresTenantSelection &&
          session.accessToken.trim().isNotEmpty) {
        await _sessionStore.save(session);
      }
      _applySessionContext(session);

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
    ref.read(authAccessTokenProvider.notifier).setToken(session.accessToken);

    final tenantId = (session.activeTenantId ?? session.user.tenantId).trim();
    ref.read(authTenantIdProvider.notifier).setTenantId(tenantId);
  }

  void _clearSessionContext() {
    ref.read(authAccessTokenProvider.notifier).clear();
    ref.read(authTenantIdProvider.notifier).clear();
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
          memberships: current.memberships.isNotEmpty
              ? current.memberships
              : selected.memberships,
          activeTenantId: tenantId,
          tenantSelectionToken: '',
        );

        await _sessionStore.save(nextSession);
        _applySessionContext(nextSession);
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
      state = state.copyWith(isLoading: false, session: nextSession);
    } catch (e, st) {
      assert(() {
        // ignore: avoid_print
        print('Tenant selection failed: $e');
        // ignore: avoid_print
        print(st);
        return true;
      }());
      state = state.copyWith(
        isLoading: false,
        error: 'Tenant selection failed',
      );
    }
  }

  Future<void> logout() async {
    await _sessionStore.clear();
    _clearSessionContext();
    state = const LoginState();
  }
}
