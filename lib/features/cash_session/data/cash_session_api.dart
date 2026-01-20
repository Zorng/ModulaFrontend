import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_register_dto.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_dto.dart';

final cashSessionApiProvider = Provider<CashSessionApi>((ref) {
  final dio = ref.watch(dioProvider);
  return CashSessionApi(dio);
});

class CashSessionApi {
  CashSessionApi(this._dio)
    : _prefix = dotenv.env['CASH_API_PREFIX'] ?? '/v1/cash';

  final Dio _dio;
  final String _prefix;

  Future<CashSessionDto> openSession(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/sessions',
      data: body,
    );
    return CashSessionDto.fromJson(_unwrapMap(response.data));
  }

  Future<CashSessionDto> forceCloseSession(
    String sessionId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/sessions/$sessionId/force-close',
      data: body,
    );
    return CashSessionDto.fromJson(_unwrapMap(response.data));
  }

  Future<CashSessionDto> closeSession(
    String sessionId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/sessions/$sessionId/close',
      data: body,
    );
    return CashSessionDto.fromJson(_unwrapMap(response.data));
  }

  Future<CashSessionDto?> getActiveSession({
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
      final json = _unwrapMap(response.data);
      if (json.isEmpty) return null;
      final id = json['id']?.toString() ?? json['sessionId']?.toString() ?? '';
      if (id.isEmpty) return null;
      return CashSessionDto.fromJson(json);
    } on DioException catch (e) {
      // Treat 404 (no active session) as empty payload instead of an error.
      if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> recordMovement(
    String sessionId,
    Map<String, dynamic> body,
  ) async {
    await _dio.post<Map<String, dynamic>>(
      '$_prefix/sessions/$sessionId/movements',
      data: body,
    );
  }

  Future<List<CashRegisterDto>> fetchRegisters({
    bool includeInactive = false,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/registers',
      queryParameters: includeInactive ? {'includeInactive': true} : null,
    );
    final data = response.data;
    if (data == null) return const [];
    final list =
        (data['data'] is List)
            ? (data['data'] as List)
            : (data['items'] is List)
                ? (data['items'] as List)
                : const [];
    return list
        .whereType<Map>()
        .map((e) => CashRegisterDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CashRegisterDto> createRegister(String name) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/registers',
      data: {'name': name},
    );
    return CashRegisterDto.fromJson(_unwrapMap(response.data));
  }

  Map<String, dynamic> _unwrapMap(Map<String, dynamic>? payload) {
    final json = payload ?? const <String, dynamic>{};
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
}
