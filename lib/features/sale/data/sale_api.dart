import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
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
      _ordersPrefix = '/v0/orders',
      _receiptsPrefix = '/v0/receipts',
      _checkoutPrefix = '/v0/checkout',
      _khqrPaymentsPrefix = '/v0/payments/khqr';

  final Dio _dio;
  final String _prefix;
  final String _ordersPrefix;
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

  Future<SaleOrderPlacementResponseDto> placeOrder(
    Map<String, dynamic> body, {
    required IdempotencyRequest idempotency,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _ordersPrefix,
        data: body,
        options: withIdempotency(request: idempotency),
      );
      return SaleOrderPlacementResponseDto.fromJson(_unwrap(response.data));
    } on DioError catch (error) {
      throw _mapSaleDioError(error, fallbackMessage: 'Failed to place order.');
    }
  }

  Future<String> uploadManualPaymentProofImage({
    required List<int> imageBytes,
  }) async {
    if (imageBytes.isEmpty) {
      throw const ApiClientException(
        message: 'Proof image is required before creating a manual claim.',
        code: 'UPLOAD_FILE_REQUIRED',
      );
    }
    try {
      final response = await _dio.post<dynamic>(
        '/v0/media/images/upload',
        data: FormData.fromMap({
          'image': MultipartFile.fromBytes(
            imageBytes,
            filename: _paymentProofFilename(imageBytes),
            contentType: _paymentProofContentType(imageBytes),
          ),
          'area': 'payment-proof',
        }),
      );
      final raw = _unwrap(response.data);
      final imageUrl = raw['imageUrl']?.toString().trim() ?? '';
      if (imageUrl.isEmpty) {
        throw const ApiClientException(
          message: 'Image upload failed: imageUrl is missing.',
          code: 'IMAGE_UPLOAD_FAILED',
        );
      }
      return imageUrl;
    } on DioError catch (error) {
      throw _mapSaleDioError(
        error,
        fallbackMessage: 'Failed to upload payment proof image.',
      );
    }
  }

  Future<SaleManualPaymentClaimResponseDto> createManualPaymentClaim(
    String orderId,
    Map<String, dynamic> body, {
    required IdempotencyRequest idempotency,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_ordersPrefix/$orderId/manual-payment-claims',
        data: body,
        options: withIdempotency(request: idempotency),
      );
      return SaleManualPaymentClaimResponseDto.fromJson(_unwrap(response.data));
    } on DioError catch (error) {
      throw _mapSaleDioError(
        error,
        fallbackMessage: 'Failed to create manual payment claim.',
      );
    }
  }

  Future<SaleApproveManualPaymentClaimResponseDto> approveManualPaymentClaim(
    String orderId,
    String claimId,
    Map<String, dynamic> body, {
    required IdempotencyRequest idempotency,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_ordersPrefix/$orderId/manual-payment-claims/$claimId/approve',
        data: body,
        options: withIdempotency(request: idempotency),
      );
      return SaleApproveManualPaymentClaimResponseDto.fromJson(
        _unwrap(response.data),
      );
    } on DioError catch (error) {
      throw _mapSaleDioError(
        error,
        fallbackMessage: 'Failed to approve manual payment claim.',
      );
    }
  }

  Future<SaleRejectManualPaymentClaimResponseDto> rejectManualPaymentClaim(
    String orderId,
    String claimId,
    Map<String, dynamic> body, {
    required IdempotencyRequest idempotency,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_ordersPrefix/$orderId/manual-payment-claims/$claimId/reject',
        data: body,
        options: withIdempotency(request: idempotency),
      );
      return SaleRejectManualPaymentClaimResponseDto.fromJson(
        _unwrap(response.data),
      );
    } on DioError catch (error) {
      throw _mapSaleDioError(
        error,
        fallbackMessage: 'Failed to reject manual payment claim.',
      );
    }
  }

  Future<SaleOrderFulfillmentUpdateResponseDto> updateOrderFulfillmentStatus(
    String orderId, {
    required String status,
    String? note,
    required IdempotencyRequest idempotency,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_ordersPrefix/$orderId/fulfillment',
      data: {
        'status': status,
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      },
      options: withIdempotency(request: idempotency),
    );
    return SaleOrderFulfillmentUpdateResponseDto.fromJson(
      _unwrap(response.data),
    );
  }

  Future<SaleOrdersListResponseDto> listOrders({
    String? status,
    String? view,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (status != null) 'status': status,
      if (view != null) 'view': view,
      if (from != null) 'from': _toUtcIso(from),
      if (to != null) 'to': _toUtcIso(to),
    };
    final response = await _dio.get<Map<String, dynamic>>(
      _ordersPrefix,
      queryParameters: query,
    );
    return SaleOrdersListResponseDto.fromJson(_unwrap(response.data));
  }

  Future<SaleOrderDetailResponseDto> getOrderDetail(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_ordersPrefix/$orderId',
    );
    return SaleOrderDetailResponseDto.fromJson(_unwrap(response.data));
  }

  Future<SaleCashCheckoutResponseDto> checkoutOrder(
    String orderId,
    Map<String, dynamic> body, {
    required IdempotencyRequest idempotency,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_ordersPrefix/$orderId/checkout',
        data: body,
        options: withIdempotency(request: idempotency),
      );
      return SaleCashCheckoutResponseDto.fromJson(_unwrap(response.data));
    } on DioError catch (error) {
      throw _mapSaleDioError(
        error,
        fallbackMessage: 'Failed to checkout order.',
      );
    }
  }

  Future<SaleDto> getSaleDetail(String saleId) async {
    final response = await _dio.get<Map<String, dynamic>>('$_prefix/$saleId');
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

    final root = ApiContract.asJsonMap(ApiContract.unwrapData(data));
    List<dynamic>? list = root['items'] as List<dynamic>?;
    list ??= root['sales'] as List<dynamic>?;
    list ??= root['data'] as List<dynamic>?;
    if (list == null && data['data'] is List) {
      list = data['data'] as List<dynamic>;
    }
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

MediaType? _paymentProofContentType(List<int> imageBytes) {
  final subtype = _paymentProofSubtype(imageBytes);
  if (subtype == null) return null;
  return MediaType('image', subtype);
}

String _paymentProofFilename(List<int> imageBytes) {
  final subtype = _paymentProofSubtype(imageBytes);
  switch (subtype) {
    case 'png':
      return 'payment-proof.png';
    case 'webp':
      return 'payment-proof.webp';
    case 'jpeg':
    default:
      return 'payment-proof.jpg';
  }
}

String? _paymentProofSubtype(List<int> imageBytes) {
  if (imageBytes.length >= 3 &&
      imageBytes[0] == 0xFF &&
      imageBytes[1] == 0xD8 &&
      imageBytes[2] == 0xFF) {
    return 'jpeg';
  }
  if (imageBytes.length >= 8 &&
      imageBytes[0] == 0x89 &&
      imageBytes[1] == 0x50 &&
      imageBytes[2] == 0x4E &&
      imageBytes[3] == 0x47 &&
      imageBytes[4] == 0x0D &&
      imageBytes[5] == 0x0A &&
      imageBytes[6] == 0x1A &&
      imageBytes[7] == 0x0A) {
    return 'png';
  }
  if (imageBytes.length >= 12 &&
      imageBytes[0] == 0x52 &&
      imageBytes[1] == 0x49 &&
      imageBytes[2] == 0x46 &&
      imageBytes[3] == 0x46 &&
      imageBytes[8] == 0x57 &&
      imageBytes[9] == 0x45 &&
      imageBytes[10] == 0x42 &&
      imageBytes[11] == 0x50) {
    return 'webp';
  }
  return null;
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
