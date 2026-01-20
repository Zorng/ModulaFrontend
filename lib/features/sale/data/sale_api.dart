import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/sale/data/dto/sale_dto.dart';

final saleApiProvider = Provider<SaleApi>((ref) {
  final dio = ref.watch(dioProvider);
  return SaleApi(dio);
});

class SaleApi {
  SaleApi(this._dio)
      : _prefix = dotenv.env['SALES_API_PREFIX'] ?? '/v1/sales';

  final Dio _dio;
  final String _prefix;

  Future<SaleDto> createDraft(Map<String, dynamic> body) async {
    final response =
        await _dio.post<Map<String, dynamic>>('$_prefix/drafts', data: body);
    return SaleDto.fromJson(_unwrap(response.data));
  }

  Future<SaleDto> getOrCreateDraft(String clientUuid) async {
    final response =
        await _dio.get<Map<String, dynamic>>('$_prefix/drafts/$clientUuid');
    return SaleDto.fromJson(_unwrap(response.data));
  }

  Future<SaleDto> addItem(
    String saleId,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _dio.post<Map<String, dynamic>>('$_prefix/$saleId/items', data: body);
    return SaleDto.fromJson(_unwrap(response.data));
  }

  Future<SaleDto> updateItemQuantity(
    String saleId,
    String itemId,
    int quantity,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/$saleId/items/$itemId/quantity',
      data: {'quantity': quantity},
    );
    return SaleDto.fromJson(_unwrap(response.data));
  }

  Future<void> removeItem(String saleId, String itemId) async {
    await _dio.delete('$_prefix/$saleId/items/$itemId');
  }

  Future<SaleDto> preCheckout(
    String saleId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/$saleId/pre-checkout',
      data: body,
    );
    return SaleDto.fromJson(_unwrap(response.data));
  }

  Future<SaleDto> finalize(String saleId) async {
    final response =
        await _dio.post<Map<String, dynamic>>('$_prefix/$saleId/finalize');
    return SaleDto.fromJson(_unwrap(response.data));
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
    final response =
        await _dio.get<Map<String, dynamic>>(_prefix, queryParameters: query);
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

  String _toUtcIso(DateTime dt) => dt.toUtc().toIso8601String();

  Map<String, dynamic> _unwrap(Map<String, dynamic>? payload) {
    final json = payload ?? const <String, dynamic>{};
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
}
