import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';

final cashSessionApiProvider = Provider<CashSessionApi>((ref) {
  final dio = ref.watch(dioProvider);
  return CashSessionApi(dio);
});

class CashSessionApi {
  CashSessionApi(this._dio)
    : _prefix = dotenv.env['CASH_API_PREFIX'] ?? '/v1/cash';

  final Dio _dio;
  final String _prefix;

  Future<Map<String, dynamic>> openSession(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/sessions',
      data: body,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> forceCloseSession(
    String sessionId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/sessions/$sessionId/force-close',
      data: body,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> closeSession(
    String sessionId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/sessions/$sessionId/close',
      data: body,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> getActiveSession({
    String? registerId,
    String? branchId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/sessions/active',
        queryParameters:
            {
              if (registerId != null && registerId.isNotEmpty)
                'registerId': registerId,
              if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
            }.isEmpty
            ? null
            : {
                if (registerId != null && registerId.isNotEmpty)
                  'registerId': registerId,
                if (branchId != null && branchId.isNotEmpty)
                  'branchId': branchId,
              },
      );
      return response.data ?? const {};
    } on DioException catch (e) {
      // Treat 404 (no active session) as empty payload instead of an error.
      if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
        return const {};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> recordMovement(
    String sessionId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/sessions/$sessionId/movements',
      data: body,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> fetchZReport(String sessionId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/sessions/reports/z/$sessionId',
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> fetchXReport({String? registerId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/sessions/reports/x',
      queryParameters:
          registerId != null && registerId.isNotEmpty
              ? {'registerId': registerId}
              : null,
    );
    return response.data ?? const {};
  }

  Future<List<dynamic>> fetchRegisters({bool includeInactive = false}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/registers',
      queryParameters: includeInactive ? {'includeInactive': true} : null,
    );
    final data = response.data;
    if (data == null) return const [];
    if (data['data'] is List) return List<dynamic>.from(data['data'] as List);
    if (data['items'] is List) return List<dynamic>.from(data['items'] as List);
    return const [];
  }

  Future<Map<String, dynamic>> createRegister(String name) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/registers',
      data: {'name': name},
    );
    return response.data ?? const {};
  }
}
