import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:flutter_riverpod/legacy.dart'; 

class LoginState {
  final bool isLoading;
  final User? user;
  final String? error;

  const LoginState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  LoginState copyWith({
    bool? isLoading,
    User? user,
    String? error,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return LoginController(repo);
});

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._repo) : super(const LoginState());

  final AuthRepository _repo;

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _repo.login(username, password);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed', // you can inspect e for more details
      );
    }
  }
}