import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/auth/domain/auth_token_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

const _retryAfterRefreshExtraKey = '__retry_after_refresh__';
const _explicitAuthHeaderExtraKey = '__explicit_auth_header__';

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = AppEnv.apiBaseUrl;
  final idempotencyKeyStore = ref.read(idempotencyKeyStoreProvider);
  Completer<String?>? refreshCompleter;

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: {Headers.acceptHeader: Headers.jsonContentType},
    ),
  );

  Future<String?> refreshAccessTokenSingleFlight() async {
    if (refreshCompleter != null) {
      return refreshCompleter!.future;
    }

    final completer = Completer<String?>();
    refreshCompleter = completer;
    try {
      final controller = ref.read(loginControllerProvider.notifier);
      final refreshed = await controller.refreshSessionForNetwork();
      final token = refreshed?.accessToken.trim();
      completer.complete((token ?? '').isEmpty ? null : token);
    } catch (_) {
      completer.complete(null);
    } finally {
      refreshCompleter = null;
    }
    return completer.future;
  }

  bool isRefreshProtectedPath(String path) {
    final p = path.toLowerCase();
    return p.contains('/auth/login') ||
        p.contains('/auth/register') ||
        p.contains('/auth/otp/send') ||
        p.contains('/auth/otp/verify') ||
        p.contains('/auth/refresh') ||
        p.contains('/auth/logout');
  }

  String authorizationHeaderValue(Map<String, dynamic> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toString().toLowerCase() != 'authorization') continue;
      return entry.value?.toString().trim() ?? '';
    }
    return '';
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final explicitAuthorization = authorizationHeaderValue(options.headers);
        final hasExplicitAuthorization = explicitAuthorization.isNotEmpty;
        options.extra[_explicitAuthHeaderExtraKey] = hasExplicitAuthorization;

        final token = ref.read(authAccessTokenProvider);
        if (!hasExplicitAuthorization && token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        final method = options.method.toUpperCase();
        final isWriteMethod =
            method == 'POST' ||
            method == 'PUT' ||
            method == 'PATCH' ||
            method == 'DELETE';

        final hasIdempotencyHeader =
            (options.headers[idempotencyHeaderName]?.toString().trim() ?? '')
                .isNotEmpty;
        final request = options.extra[idempotencyRequestExtraKey];
        if (isWriteMethod &&
            !hasIdempotencyHeader &&
            request is IdempotencyRequest) {
          final key = await idempotencyKeyStore.getOrCreateKey(request);
          options.headers[idempotencyHeaderName] = key;
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        final options = error.requestOptions;
        final alreadyRetried =
            options.extra[_retryAfterRefreshExtraKey] == true;
        final hasExplicitAuthorization =
            options.extra[_explicitAuthHeaderExtraKey] == true;
        if (statusCode != 401 ||
            alreadyRetried ||
            hasExplicitAuthorization ||
            isRefreshProtectedPath(options.path)) {
          handler.next(error);
          return;
        }

        final refreshedAccessToken = await refreshAccessTokenSingleFlight();
        if (refreshedAccessToken == null || refreshedAccessToken.isEmpty) {
          handler.next(error);
          return;
        }

        final nextHeaders = <String, dynamic>{...options.headers};
        nextHeaders['Authorization'] = 'Bearer $refreshedAccessToken';
        final nextExtra = <String, dynamic>{...options.extra}
          ..[_retryAfterRefreshExtraKey] = true;

        final nextOptions = options.copyWith(
          headers: nextHeaders,
          extra: nextExtra,
        );
        try {
          final response = await dio.fetch<dynamic>(nextOptions);
          handler.resolve(response);
        } on DioError catch (retryError) {
          handler.next(retryError);
        }
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(responseBody: false));
  }

  return dio;
});
