import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_register_dto.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_api_envelope.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_dto.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_envelope_dto.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_error_codes.dart';

final cashSessionApiProvider = Provider<CashSessionApi>((ref) {
  final dio = ref.watch(dioProvider);
  return CashSessionApi(dio);
});

class CashSessionApi {
  CashSessionApi(this._dio) : _prefix = AppEnv.cashApiPrefix;

  final Dio _dio;
  final String _prefix;

  Future<CashSessionDto> openSession(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_prefix/sessions',
        data: body,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'cashSession.open',
            payload: body,
          ),
        ),
      );
      final data = CashSessionApiEnvelope.unwrapRequiredSessionMap(
        response.data,
        fallbackMessage: 'Failed to open cash session.',
      );
      return CashSessionDto.fromJson(data);
    } on DioError catch (error) {
      throw _mapCashSessionDioError(
        error,
        fallbackMessage: 'Failed to open cash session.',
      );
    }
  }

  Future<CashSessionDto> forceCloseSession(
    String sessionId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_prefix/sessions/$sessionId/force-close',
        data: body,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'cashSession.forceClose',
            payload: {'sessionId': sessionId, ...body},
          ),
        ),
      );
      final data = CashSessionApiEnvelope.unwrapRequiredSessionMap(
        response.data,
        fallbackMessage: 'Failed to force close cash session.',
      );
      return CashSessionDto.fromJson(data);
    } on DioError catch (error) {
      throw _mapCashSessionDioError(
        error,
        fallbackMessage: 'Failed to force close cash session.',
      );
    }
  }

  Future<CashSessionDto> closeSession(
    String sessionId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_prefix/sessions/$sessionId/close',
        data: body,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'cashSession.close',
            payload: {'sessionId': sessionId, ...body},
          ),
        ),
      );
      final data = CashSessionApiEnvelope.unwrapRequiredSessionMap(
        response.data,
        fallbackMessage: 'Failed to close cash session.',
      );
      return CashSessionDto.fromJson(data);
    } on DioError catch (error) {
      throw _mapCashSessionDioError(
        error,
        fallbackMessage: 'Failed to close cash session.',
      );
    }
  }

  Future<CashSessionDto?> getActiveSession() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/sessions/active',
      );
      final data = CashSessionApiEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to load active cash session.',
      );
      return CashSessionEnvelopeDto.fromJson(data).session;
    } on DioError catch (error) {
      throw _mapCashSessionDioError(
        error,
        fallbackMessage: 'Failed to load active cash session.',
      );
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
    final list = (data['data'] is List)
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
    final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
    return CashRegisterDto.fromJson(data);
  }
}

ApiClientException _mapCashSessionDioError(
  DioError error, {
  required String fallbackMessage,
}) {
  final isOfflineLike =
      error.response == null && error.type != DioErrorType.badResponse;
  if (isOfflineLike) {
    return const ApiClientException(
      message: 'This action requires online connectivity.',
      code: CashSessionErrorCodes.offlineUnreachable,
    );
  }
  final mapped = ApiClientException.fromDio(
    error,
    fallbackMessage: fallbackMessage,
  );
  return ApiClientException(
    message: mapped.message,
    code: CashSessionErrorCodes.normalize(mapped.code),
    statusCode: mapped.statusCode,
    details: mapped.details,
  );
}
