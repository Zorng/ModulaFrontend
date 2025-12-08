import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';

final saleApiProvider = Provider<SaleApi>((ref) {
  final dio = ref.watch(dioProvider);
  return SaleApi(dio);
});

class SaleApi {
  SaleApi(this._dio)
      : _prefix = dotenv.env['SALES_API_PREFIX'] ?? '/v1/sales';

  final Dio _dio;
  final String _prefix;

  Future<Map<String, dynamic>> createDraft(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>('$_prefix/drafts', data: body);
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> getOrCreateDraft(String clientUuid) async {
    final response = await _dio.get<Map<String, dynamic>>('$_prefix/drafts/$clientUuid');
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> addItem(
    String saleId,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _dio.post<Map<String, dynamic>>('$_prefix/$saleId/items', data: body);
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateItemQuantity(
    String saleId,
    String itemId,
    int quantity,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/$saleId/items/$itemId/quantity',
      data: {'quantity': quantity},
    );
    return response.data ?? const {};
  }

  Future<void> removeItem(String saleId, String itemId) async {
    await _dio.delete('$_prefix/$saleId/items/$itemId');
  }

  Future<Map<String, dynamic>> preCheckout(
    String saleId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/$saleId/pre-checkout',
      data: body,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> finalize(String saleId) async {
    final response = await _dio.post<Map<String, dynamic>>('$_prefix/$saleId/finalize');
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateFulfillmentStatus(
    String saleId, {
    required String status,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/$saleId/fulfillment',
      data: {'status': status},
    );
    return response.data ?? const {};
  }

  Future<List<dynamic>> listSales({
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
    final response =
        await _dio.get<Map<String, dynamic>>(_prefix, queryParameters: query);
    final data = response.data;
    if (data == null) return const [];
    if (data['data'] is List) return List<dynamic>.from(data['data'] as List);
    if (data['items'] is List) return List<dynamic>.from(data['items'] as List);
    return const [];
  }

  Future<Map<String, dynamic>> voidSale(String saleId, {required String reason}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/$saleId/void',
      data: {'reason': reason},
    );
    return response.data ?? const {};
  }

  String _toUtcIso(DateTime dt) => dt.toUtc().toIso8601String();
}
