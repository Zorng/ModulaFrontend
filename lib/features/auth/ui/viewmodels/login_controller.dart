import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_token_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

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
      Future.microtask(() => _applySessionContext(initialSession));
    }
  }

  final Ref ref;
  final AuthRepository _repository;
  final AuthSessionStore _sessionStore;

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final session = await _repository.login(username, password);
      await _sessionStore.save(session);
      _applySessionContext(session);

      state = state.copyWith(isLoading: false, session: session);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed', // you can inspect e for more details
      );
    }
  }

  void _applySessionContext(AuthSession session) {
    ref.read(authAccessTokenProvider.notifier).state = session.accessToken;
    ref.read(authTenantIdProvider.notifier).state = session.user.tenantId;
  }
}
