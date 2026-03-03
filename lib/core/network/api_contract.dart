import 'dart:convert';

import 'package:dio/dio.dart';

typedef JsonMap = Map<String, dynamic>;

/// Parses canonical backend envelope fields and provides a single
/// exception shape for data-layer callers.
class ApiContract {
  const ApiContract._();

  static JsonMap asJsonMap(dynamic value) {
    if (value is JsonMap) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return asJsonMap(decoded);
      } catch (_) {
        return const <String, dynamic>{};
      }
    }
    return const <String, dynamic>{};
  }

  static dynamic unwrapData(dynamic body) {
    final map = asJsonMap(body);
    if (map['success'] == true && map.containsKey('data')) {
      return map['data'];
    }
    return body;
  }

  static String? errorCode(dynamic body) {
    final raw = asJsonMap(body);
    final details = asJsonMap(raw['details']);
    final candidates = <dynamic>[
      raw['code'],
      raw['reasonCode'],
      raw['reason_code'],
      details['code'],
      details['reasonCode'],
      details['reason_code'],
    ];
    for (final candidate in candidates) {
      final code = candidate?.toString().trim() ?? '';
      if (code.isNotEmpty) return code;
    }
    return null;
  }

  static String? errorMessage(dynamic body) {
    return asJsonMap(body)['error']?.toString();
  }

  static JsonMap? errorDetails(dynamic body) {
    final details = asJsonMap(body)['details'];
    if (details is Map) {
      return details.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }
}

class ApiClientException implements Exception {
  const ApiClientException({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  factory ApiClientException.fromDio(
    DioError exception, {
    String fallbackMessage = 'Request failed.',
  }) {
    final data = exception.response?.data;
    final message = ApiContract.errorMessage(data);
    final code = ApiContract.errorCode(data);
    return ApiClientException(
      message: message?.trim().isNotEmpty == true ? message! : fallbackMessage,
      code: code,
      statusCode: exception.response?.statusCode,
      details: ApiContract.errorDetails(data),
    );
  }

  final String message;
  final String? code;
  final int? statusCode;
  final JsonMap? details;

  @override
  String toString() {
    return 'ApiClientException('
        'statusCode: $statusCode, '
        'code: $code, '
        'message: $message'
        ')';
  }
}
