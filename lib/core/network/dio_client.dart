import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_token_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authAccessTokenProvider);
        final tenantId = ref.read(authTenantIdProvider);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (tenantId != null && tenantId.isNotEmpty) {
          options.headers['X-Tenant-Id'] = tenantId;
        }
        handler.next(options);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(responseBody: false));
  }

  return dio;
});
