import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.read(dioProvider);
  return AuthApi(dio);
});

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'username': username,
        'password': password,
      },
    );

    return User.fromJson(response.data['user']);
  }
}