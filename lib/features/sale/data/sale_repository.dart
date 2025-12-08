import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/sale/data/sale_api.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final api = ref.watch(saleApiProvider);
  return SaleRepository(api);
});

class SaleRepository {
  SaleRepository(this._api);

  final SaleApi _api;

  Future<String> ensureDraft({
    String? clientUuid,
    required String saleType,
    double fxRateUsed = 4100,
  }) async {
    final uuid = clientUuid ?? _randomUuid();

    Map<String, dynamic> unwrap(Map<String, dynamic> json) {
      final data = json['data'];
      return data is Map<String, dynamic> ? data : json;
    }

    // Always create explicit draft with required fields to avoid missing fxRate errors.
    final created = unwrap(await _api.createDraft({
      'clientUuid': uuid,
      'saleType': saleType,
      'fxRateUsed': fxRateUsed,
    }));
    final createdId = created['id']?.toString() ?? '';
    if (createdId.isEmpty) {
      throw Exception('Failed to create draft sale');
    }
    return createdId;
  }

  Future<Map<String, dynamic>> addItem({
    required String saleId,
    required String menuItemId,
    required int quantity,
    required List<Map<String, dynamic>> modifiers,
    double? unitPriceUsd,
    double? lineTotalUsdExact,
    double? addonTotalUsd,
    Map<String, dynamic>? pricingSnapshot,
  }) async {
    return _api.addItem(saleId, {
      'menuItemId': menuItemId,
      'quantity': quantity,
      'modifiers': modifiers,
      if (unitPriceUsd != null) 'unitPriceUsd': unitPriceUsd,
      if (lineTotalUsdExact != null) 'lineTotalUsdExact': lineTotalUsdExact,
      if (addonTotalUsd != null) 'addonTotalUsd': addonTotalUsd,
      if (pricingSnapshot != null) 'pricingSnapshot': pricingSnapshot,
    });
  }

  Future<void> updateItemQuantity({
    required String saleId,
    required String itemId,
    required int quantity,
  }) async {
    await _api.updateItemQuantity(saleId, itemId, quantity);
  }

  Future<void> removeItem({required String saleId, required String itemId}) async {
    await _api.removeItem(saleId, itemId);
  }

  Future<Map<String, dynamic>> preCheckout({
    required String saleId,
    required String tenderCurrency,
    required String paymentMethod,
    Map<String, num>? cashReceived,
  }) async {
    final body = {
      // API expects uppercase currency codes (see docs/apiSchema/saleSchema.ts).
      'tenderCurrency': tenderCurrency.toUpperCase(),
      'paymentMethod': paymentMethod,
      if (cashReceived != null && cashReceived.isNotEmpty) 'cashReceived': cashReceived,
    };
    return _api.preCheckout(saleId, body);
  }

  Future<Map<String, dynamic>> finalize(String saleId) => _api.finalize(saleId);

  Future<Map<String, dynamic>> updateFulfillmentStatus({
    required String saleId,
    required String status,
  }) {
    return _api.updateFulfillmentStatus(saleId, status: status);
  }

  Future<List<Map<String, dynamic>>> listSales({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final data = await _api.listSales(
      status: status,
      startDate: startDate,
      endDate: endDate,
      page: page,
      limit: limit,
    );
    return data.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      return {};
    }).toList();
  }

  Future<Map<String, dynamic>> voidSale(String saleId, {required String reason}) {
    return _api.voidSale(saleId, reason: reason);
  }
}

String _randomUuid() {
  final rand = Random();
  String fourHex() => rand.nextInt(0x10000).toRadixString(16).padLeft(4, '0');
  // Ensure correct UUID v4 structure.
  final part1 = '${fourHex()}${fourHex()}';
  final part2 = fourHex();
  final part3 = (int.parse(fourHex(), radix: 16) & 0x0fff | 0x4000)
      .toRadixString(16)
      .padLeft(4, '0'); // version 4
  final part4 = (int.parse(fourHex(), radix: 16) & 0x3fff | 0x8000)
      .toRadixString(16)
      .padLeft(4, '0'); // variant
  final part5 = '${fourHex()}${fourHex()}${fourHex()}';
  return '$part1-$part2-$part3-$part4-$part5';
}
