import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.read(dioProvider);
  return AuthApi(dio);
});

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final authPrefix = dotenv.env['AUTH_API_PREFIX'] ?? '/v1/auth';
    final path = '$authPrefix/login';

    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: {
        'phone': username,
        'password': password,
      },
    );

    final data = response.data ?? {};
    final userJson = data['employee'] as Map<String, dynamic>? ?? {};
    final tokens = data['tokens'] as Map<String, dynamic>? ?? {};
    final assignments =
        (data['branch_assignments'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => e as Map<String, dynamic>)
            .toList();

    // Merge branch assignments into user payload for our model.
    userJson['branches'] = assignments;
    if (userJson['name'] == null) {
      final first = userJson['first_name']?.toString() ?? '';
      final last = userJson['last_name']?.toString() ?? '';
      userJson['name'] = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
    }

    // Infer role from assignments if not present.
    final roleFromAssignment =
        assignments.isNotEmpty ? assignments.first['role']?.toString() : null;
    userJson['role'] = userJson['role'] ?? roleFromAssignment ?? 'cashier';

    final accessToken = tokens['access_token']?.toString() ??
        tokens['accessToken']?.toString() ??
        '';
    final refreshToken = tokens['refresh_token']?.toString() ??
        tokens['refreshToken']?.toString() ??
        '';
    final expiresInSeconds =
        (tokens['expiresIn'] as num?)?.toInt() ?? (tokens['expires_in'] as num?)?.toInt();

    final accessExpiry = expiresInSeconds != null
        ? DateTime.now().add(Duration(seconds: expiresInSeconds))
        : DateTime.now().add(const Duration(minutes: 15));

    return AuthSession(
      user: User.fromJson(userJson),
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: accessExpiry,
      refreshTokenExpiresAt: DateTime.now().add(const Duration(hours: 72)),
    );
  }
}
