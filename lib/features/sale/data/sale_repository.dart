import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/sale/data/sale_api.dart';
import 'package:modular_pos/features/sale/data/dto/sale_dto.dart';
import 'package:modular_pos/features/sale/data/mock_sale_repository.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';

/// Provider to control whether to use mock or real repository
/// Set to true for testing without backend
final useMockSaleRepositoryProvider = NotifierProvider<_UseMockNotifier, bool>(
  _UseMockNotifier.new,
);

class _UseMockNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final useMock = ref.watch(useMockSaleRepositoryProvider);
  if (useMock) {
    return MockSaleRepository();
  }
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

    // Always create explicit draft with required fields to avoid missing fxRate errors.
    final created = await _api.createDraft({
      'clientUuid': uuid,
      'saleType': saleType,
      'fxRateUsed': fxRateUsed,
    });
    final createdId = created.id;
    if (createdId.isEmpty) {
      throw Exception('Failed to create draft sale');
    }
    return createdId;
  }

  Future<String?> addItem({
    required String saleId,
    required String menuItemId,
    required int quantity,
    required List<Map<String, dynamic>> modifiers,
    required Map<String, List<String>> selectedOptionIds,
    double? unitPriceUsd,
    double? lineTotalUsdExact,
    double? addonTotalUsd,
    Map<String, dynamic>? pricingSnapshot,
  }) async {
    final sale = await _api.addItem(saleId, {
      'menuItemId': menuItemId,
      'quantity': quantity,
      'modifiers': modifiers,
      if (unitPriceUsd != null) 'unitPriceUsd': unitPriceUsd,
      if (lineTotalUsdExact != null) 'lineTotalUsdExact': lineTotalUsdExact,
      if (addonTotalUsd != null) 'addonTotalUsd': addonTotalUsd,
      if (pricingSnapshot != null) 'pricingSnapshot': pricingSnapshot,
    });

    // Best-effort: find the most recently-added matching item.
    for (final item in sale.items.reversed) {
      if (item.menuItemId != menuItemId) continue;
      if (_modifiersMatch(item.modifiers, selectedOptionIds)) {
        if (item.id.isNotEmpty) return item.id;
      }
    }
    return null;
  }

  Future<void> updateItemQuantity({
    required String saleId,
    required String itemId,
    required int quantity,
  }) async {
    await _api.updateItemQuantity(saleId, itemId, quantity);
  }

  Future<void> removeItem({
    required String saleId,
    required String itemId,
  }) async {
    await _api.removeItem(saleId, itemId);
  }

  Future<SaleCheckoutSummary> preCheckout({
    required String saleId,
    required String tenderCurrency,
    required String paymentMethod,
    Map<String, num>? cashReceived,
  }) async {
    final body = {
      // API expects uppercase currency codes (see docs/apiSchema/saleSchema.ts).
      'tenderCurrency': tenderCurrency.toUpperCase(),
      'paymentMethod': paymentMethod,
      if (cashReceived != null && cashReceived.isNotEmpty)
        'cashReceived': cashReceived,
    };
    final sale = await _api.preCheckout(saleId, body);
    return _toCheckoutSummary(sale);
  }

  Future<SaleCheckoutSummary> finalize(String saleId) async {
    final sale = await _api.finalize(saleId);
    return _toCheckoutSummary(sale);
  }

  Future<void> updateFulfillmentStatus({
    required String saleId,
    required String status,
  }) async {
    await _api.updateFulfillmentStatus(saleId, status: status);
  }

  Future<List<Sale>> listSales({
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
    return data.map(_toDomain).where((sale) => sale.id.isNotEmpty).toList();
  }

  Future<void> voidSale(String saleId, {required String reason}) async {
    await _api.voidSale(saleId, reason: reason);
  }

  Sale _toDomain(SaleDto dto) {
    return Sale(
      id: dto.id,
      saleType: dto.saleType,
      state: dto.state,
      fulfillmentStatus: dto.fulfillmentStatus,
      paymentMethod: dto.paymentMethod,
      tenderCurrency: dto.tenderCurrency,
      fxRateUsed: dto.fxRateUsed,
      subtotalUsdExact: dto.subtotalUsdExact,
      subtotalKhrExact: dto.subtotalKhrExact,
      totalUsdExact: dto.totalUsdExact,
      totalKhrExact: dto.totalKhrExact,
      cashReceivedUsd: dto.cashReceivedUsd,
      cashReceivedKhr: dto.cashReceivedKhr,
      changeGivenUsd: dto.changeGivenUsd,
      changeGivenKhr: dto.changeGivenKhr,
      createdAt: dto.createdAt.toLocal(),
      updatedAt: dto.updatedAt.toLocal(),
      items: dto.items
          .map(
            (item) => SaleItem(
              id: item.id,
              menuItemId: item.menuItemId,
              menuItemName: item.menuItemName,
              quantity: item.quantity,
              modifiers: item.modifiers
                  .map(
                    (m) => SaleModifier(
                      groupId: m.groupId,
                      optionIds: m.optionIds,
                      optionLabels: m.options
                          .map((o) => o.label)
                          .where((label) => label.isNotEmpty)
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  SaleCheckoutSummary _toCheckoutSummary(SaleDto dto) {
    final tender = (dto.tenderCurrency.isEmpty ? 'USD' : dto.tenderCurrency)
        .toLowerCase();
    return SaleCheckoutSummary(
      saleId: dto.id,
      tenderCurrency: tender,
      paymentMethod: dto.paymentMethod,
      totalUsdExact: dto.totalUsdExact,
      totalKhrExact: dto.totalKhrExact,
      cashReceivedUsd: dto.cashReceivedUsd ?? 0,
      cashReceivedKhr: dto.cashReceivedKhr ?? 0,
      changeGivenUsd: dto.changeGivenUsd ?? 0,
      changeGivenKhr: dto.changeGivenKhr ?? 0,
    );
  }

  bool _modifiersMatch(
    List<SaleModifierDto> modifiers,
    Map<String, List<String>> selectedOptionIds,
  ) {
    if (selectedOptionIds.isEmpty) return true;
    final normalizedSelected = {
      for (final entry in selectedOptionIds.entries)
        entry.key: [...entry.value]..sort(),
    };
    for (final mod in modifiers) {
      final groupId = mod.groupId;
      if (groupId.isEmpty) continue;
      final selected = normalizedSelected[groupId];
      if (selected == null) continue;
      final optIds = [...mod.optionIds]..sort();
      if (!_listsEqual(selected, optIds)) return false;
    }
    return true;
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
