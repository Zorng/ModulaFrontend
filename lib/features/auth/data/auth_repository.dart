import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/data/auth_api.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.read(authApiProvider);
  return AuthRepository(api);
});

class AuthRepository {
  AuthRepository(this._api);

  final AuthApi _api;

  Future<User> login(String username, String password) {
    return _api.login(username: username, password: password);
  }
}