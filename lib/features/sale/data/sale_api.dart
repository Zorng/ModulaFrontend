import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/dto/sale_api_envelope.dart';
import 'package:modular_pos/features/sale/data/dto/sale_dto.dart';

final saleApiProvider = Provider<SaleApi>((ref) {
  final dio = ref.watch(dioProvider);
  return SaleApi(dio);
});

class SaleApi {
  SaleApi(this._dio)
    : _prefix = AppEnv.salesApiPrefix,
      _receiptsPrefix = '/v0/receipts',
      _checkoutPrefix = '/v0/checkout',
      _khqrPaymentsPrefix = '/v0/payments/khqr';

  final Dio _dio;
  final String _prefix;
  final String _receiptsPrefix;
  final String _checkoutPrefix;
  final String _khqrPaymentsPrefix;

  Future<SaleDraftDto> createDraft(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/drafts',
      data: body,
    );
    return SaleDraftDto.fromJson(_unwrap(response.data));
  }

  Future<SaleDraftDto> getOrCreateDraft(String clientUuid) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/drafts/$clientUuid',
    );
    return SaleDraftDto.fromJson(_unwrap(response.data));
  }

  Future<SaleDraftDto> addItem(String saleId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/$saleId/items',
      data: body,
    );
    return SaleDraftDto.fromJson(_unwrap(response.data));
  }

  Future<SaleDraftDto> updateItemQuantity(
    String saleId,
    String itemId,
    int quantity,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/$saleId/items/$itemId/quantity',
      data: {'quantity': quantity},
    );
    return SaleDraftDto.fromJson(_unwrap(response.data));
  }

  Future<void> removeItem(String saleId, String itemId) async {
    await _dio.delete('$_prefix/$saleId/items/$itemId');
  }

  Future<SaleDraftDto> preCheckout(
    String saleId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/$saleId/pre-checkout',
      data: body,
    );
    return SaleDraftDto.fromJson(_unwrap(response.data));
  }

  Future<SaleDraftDto> finalize(String saleId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/$saleId/finalize',
    );
    return SaleDraftDto.fromJson(_unwrap(response.data));
  }

  Future<SaleCashCheckoutResponseDto> finalizeCashCheckout(
    Map<String, dynamic> body, {
    required IdempotencyRequest idempotency,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_checkoutPrefix/cash/finalize',
        data: body,
        options: withIdempotency(request: idempotency),
      );
      return SaleCashCheckoutResponseDto.fromJson(_unwrap(response.data));
    } on DioError catch (error) {
      throw _mapSaleDioError(
        error,
        fallbackMessage: 'Failed to finalize cash checkout.',
      );
    }
  }

  Future<SaleKhqrInitiateResponseDto> initiateKhqrIntent(
    Map<String, dynamic> body, {
    required IdempotencyRequest idempotency,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_checkoutPrefix/khqr/initiate',
        data: body,
        options: withIdempotency(request: idempotency),
      );
      return SaleKhqrInitiateResponseDto.fromJson(_unwrap(response.data));
    } on DioError catch (error) {
      throw _mapSaleDioError(
        error,
        fallbackMessage: 'Failed to initiate KHQR checkout.',
      );
    }
  }

  Future<SaleKhqrIntentStateDto> getKhqrIntentStatus(String intentId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_checkoutPrefix/khqr/intents/$intentId',
      );
      return SaleKhqrIntentStateDto.fromJson(_unwrap(response.data));
    } on DioError catch (error) {
      throw _mapSaleDioError(
        error,
        fallbackMessage: 'Failed to read KHQR intent status.',
      );
    }
  }

  Future<SaleKhqrIntentCancelDto> cancelKhqrIntent(
    String intentId, {
    required IdempotencyRequest idempotency,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_checkoutPrefix/khqr/intents/$intentId/cancel',
        options: withIdempotency(request: idempotency),
      );
      return SaleKhqrIntentCancelDto.fromJson(_unwrap(response.data));
    } on DioError catch (error) {
      throw _mapSaleDioError(
        error,
        fallbackMessage: 'Failed to cancel KHQR intent.',
      );
    }
  }

  Future<SaleFinalizeResponseDto> finalizeSaleContract(
    String saleId,
    Map<String, dynamic> body, {
    required IdempotencyRequest idempotency,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_prefix/$saleId/finalize',
        data: body,
        options: withIdempotency(request: idempotency),
      );
      return SaleFinalizeResponseDto.fromJson(_unwrap(response.data));
    } on DioError catch (error) {
      throw _mapSaleDioError(
        error,
        fallbackMessage: 'Failed to finalize sale.',
      );
    }
  }

  Future<SaleKhqrConfirmResponseDto> confirmKhqrPayment(
    String md5, {
    required IdempotencyRequest idempotency,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_khqrPaymentsPrefix/confirm',
        data: {'md5': md5},
        options: withIdempotency(request: idempotency),
      );
      return SaleKhqrConfirmResponseDto.fromJson(_unwrap(response.data));
    } on DioError catch (error) {
      throw _mapSaleDioError(
        error,
        fallbackMessage: 'Failed to confirm KHQR payment.',
      );
    }
  }

  Future<SaleDto> updateFulfillmentStatus(
    String saleId, {
    required String status,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/$saleId/fulfillment',
      data: {'status': status},
    );
    return SaleDto.fromJson(_unwrap(response.data));
  }

  Future<List<SaleDto>> listSales({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (startDate != null) 'startDate': _toUtcIso(startDate),
      if (endDate != null) 'endDate': _toUtcIso(endDate),
    };
    final response = await _dio.get<Map<String, dynamic>>(
      _prefix,
      queryParameters: query,
    );
    final data = response.data;
    if (data == null) return const [];

    List<dynamic>? pickList(Map<String, dynamic> root) {
      final value = root['data'];
      if (value is List) return value;
      final items = root['items'];
      if (items is List) return items;
      return null;
    }

    final list = pickList(data);
    if (list == null) return const [];

    return list
        .whereType<Map>()
        .map((e) => SaleDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<SaleDto> voidSale(String saleId, {required String reason}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/$saleId/void',
      data: {'reason': reason},
    );
    return SaleDto.fromJson(_unwrap(response.data));
  }

  Future<SaleReceiptReadDto> getReceiptBySaleId(String saleId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_receiptsPrefix/sales/$saleId',
      );
      return SaleReceiptReadDto.fromJson(_unwrap(response.data));
    } on DioError catch (error) {
      throw _mapSaleDioError(error, fallbackMessage: 'Failed to load receipt.');
    }
  }

  String _toUtcIso(DateTime dt) => dt.toUtc().toIso8601String();

  Map<String, dynamic> _unwrap(Map<String, dynamic>? payload) {
    return SaleApiEnvelope.unwrapDataMap(
      payload,
      fallbackMessage: 'Sale request failed.',
    );
  }
}

ApiClientException _mapSaleDioError(
  DioError error, {
  required String fallbackMessage,
}) {
  final isOfflineLike =
      error.response == null && error.type != DioErrorType.badResponse;
  if (isOfflineLike) {
    return const ApiClientException(
      message: 'This action requires online connectivity.',
      code: SaleCheckoutReasonCodes.offlineUnreachable,
    );
  }
  final mapped = ApiClientException.fromDio(
    error,
    fallbackMessage: fallbackMessage,
  );
  return ApiClientException(
    message: mapped.message,
    code: SaleCheckoutReasonCodes.normalize(mapped.code),
    statusCode: mapped.statusCode,
    details: mapped.details,
  );
}
