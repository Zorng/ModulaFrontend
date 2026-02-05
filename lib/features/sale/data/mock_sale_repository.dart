import 'dart:math';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';

/// Mock implementation of SaleRepository for testing without backend
///
/// Enables testing add-to-cart, update quantity, remove items, and checkout flows
/// while backend mutations are incomplete or unavailable.
///
/// Mock data resets on app refresh.
class MockSaleRepository implements SaleRepository {
  // In-memory storage for mock sales
  final Map<String, _MockSale> _sales = {};

  @override
  Future<String> ensureDraft({
    String? clientUuid,
    required String saleType,
    double fxRateUsed = 4100,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    final uuid = clientUuid ?? _randomUuid();
    final saleId = 'mock_sale_$uuid';

    _sales[saleId] = _MockSale(
      id: saleId,
      saleType: saleType,
      fxRateUsed: fxRateUsed,
      items: [],
    );

    return saleId;
  }

  @override
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
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 150));

    final sale = _sales[saleId];
    if (sale == null) {
      throw Exception('Sale not found: $saleId');
    }

    // Generate a mock sale item ID
    final itemId = 'mock_item_${_randomUuid().substring(0, 8)}';

    // Check if item with same modifiers already exists
    final existingIndex = sale.items.indexWhere(
      (item) =>
          item.menuItemId == menuItemId &&
          _modifiersMatch(item.modifiers, selectedOptionIds),
    );

    if (existingIndex != -1) {
      // Update existing item quantity
      final existing = sale.items[existingIndex];
      sale.items[existingIndex] = _MockSaleItem(
        id: existing.id,
        menuItemId: menuItemId,
        quantity: existing.quantity + quantity,
        modifiers: modifiers,
        unitPriceUsd: unitPriceUsd ?? 0,
        lineTotalUsdExact: lineTotalUsdExact ?? 0,
      );
      return existing.id;
    } else {
      // Add new item
      final item = _MockSaleItem(
        id: itemId,
        menuItemId: menuItemId,
        quantity: quantity,
        modifiers: modifiers,
        unitPriceUsd: unitPriceUsd ?? 0,
        lineTotalUsdExact: lineTotalUsdExact ?? 0,
      );
      sale.items.add(item);
      return itemId;
    }
  }

  @override
  Future<void> updateItemQuantity({
    required String saleId,
    required String itemId,
    required int quantity,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    final sale = _sales[saleId];
    if (sale == null) {
      throw Exception('Sale not found: $saleId');
    }

    final itemIndex = sale.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      // Item not found - ignore (backend might not support this operation)
      return;
    }

    if (quantity <= 0) {
      sale.items.removeAt(itemIndex);
    } else {
      final item = sale.items[itemIndex];
      sale.items[itemIndex] = _MockSaleItem(
        id: item.id,
        menuItemId: item.menuItemId,
        quantity: quantity,
        modifiers: item.modifiers,
        unitPriceUsd: item.unitPriceUsd,
        lineTotalUsdExact: item.lineTotalUsdExact,
      );
    }
  }

  @override
  Future<void> removeItem({
    required String saleId,
    required String itemId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    final sale = _sales[saleId];
    if (sale == null) {
      throw Exception('Sale not found: $saleId');
    }

    sale.items.removeWhere((item) => item.id == itemId);
  }

  @override
  Future<SaleCheckoutSummary> preCheckout({
    required String saleId,
    required String tenderCurrency,
    required String paymentMethod,
    Map<String, num>? cashReceived,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final sale = _sales[saleId];
    if (sale == null) {
      throw Exception('Sale not found: $saleId');
    }

    // Calculate totals
    final subtotalUsd = sale.items.fold<double>(
      0,
      (sum, item) => sum + (item.lineTotalUsdExact * item.quantity),
    );
    final totalUsd = subtotalUsd; // No tax in mock
    final totalKhr = totalUsd * sale.fxRateUsed;

    // Calculate change
    final cashUsd = (cashReceived?['usd'])?.toDouble() ?? 0.0;
    final cashKhr = (cashReceived?['khr'])?.toDouble() ?? 0.0;

    final changeUsd = tenderCurrency.toUpperCase() == 'USD'
        ? max(0.0, cashUsd - totalUsd)
        : 0.0;
    final changeKhr = tenderCurrency.toUpperCase() == 'KHR'
        ? max(0.0, cashKhr - totalKhr)
        : 0.0;

    return SaleCheckoutSummary(
      saleId: saleId,
      tenderCurrency: tenderCurrency.toLowerCase(),
      paymentMethod: paymentMethod,
      totalUsdExact: totalUsd,
      totalKhrExact: totalKhr,
      cashReceivedUsd: cashUsd,
      cashReceivedKhr: cashKhr,
      changeGivenUsd: changeUsd,
      changeGivenKhr: changeKhr,
    );
  }

  @override
  Future<SaleCheckoutSummary> finalize(String saleId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final sale = _sales[saleId];
    if (sale == null) {
      throw Exception('Sale not found: $saleId');
    }

    // Mark as finalized (in real implementation, this would update state to 'completed')
    // For mock, we just return the summary
    final subtotalUsd = sale.items.fold<double>(
      0,
      (sum, item) => sum + (item.lineTotalUsdExact * item.quantity),
    );
    final totalUsd = subtotalUsd;
    final totalKhr = totalUsd * sale.fxRateUsed;

    // Remove from mock storage after finalization
    _sales.remove(saleId);

    return SaleCheckoutSummary(
      saleId: saleId,
      tenderCurrency: 'usd',
      paymentMethod: 'cash',
      totalUsdExact: totalUsd,
      totalKhrExact: totalKhr,
      cashReceivedUsd: 0,
      cashReceivedKhr: 0,
      changeGivenUsd: 0,
      changeGivenKhr: 0,
    );
  }

  @override
  Future<void> updateFulfillmentStatus({
    required String saleId,
    required String status,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Mock implementation - does nothing
    // In real implementation, this would update the sale's fulfillment status
  }

  @override
  Future<List<Sale>> listSales({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 150));

    // Return empty list for mock - could be extended to return mock sales
    return [];
  }

  @override
  Future<void> voidSale(String saleId, {required String reason}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Remove from mock storage
    _sales.remove(saleId);
  }

  // Helper methods

  bool _modifiersMatch(
    List<Map<String, dynamic>> modifiers,
    Map<String, List<String>> selectedOptionIds,
  ) {
    if (selectedOptionIds.isEmpty) return modifiers.isEmpty;

    final normalizedSelected = {
      for (final entry in selectedOptionIds.entries)
        entry.key: [...entry.value]..sort(),
    };

    for (final mod in modifiers) {
      final groupId = mod['groupId'] as String?;
      if (groupId == null || groupId.isEmpty) continue;

      final selected = normalizedSelected[groupId];
      if (selected == null) continue;

      final optIds =
          (mod['optionIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList()
            ?..sort();

      if (optIds == null || !_listsEqual(selected, optIds)) return false;
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

// Internal mock models

class _MockSale {
  _MockSale({
    required this.id,
    required this.saleType,
    required this.fxRateUsed,
    required this.items,
  });

  final String id;
  final String saleType;
  final double fxRateUsed;
  final List<_MockSaleItem> items;
}

class _MockSaleItem {
  _MockSaleItem({
    required this.id,
    required this.menuItemId,
    required this.quantity,
    required this.modifiers,
    required this.unitPriceUsd,
    required this.lineTotalUsdExact,
  });

  final String id;
  final String menuItemId;
  final int quantity;
  final List<Map<String, dynamic>> modifiers;
  final double unitPriceUsd;
  final double lineTotalUsdExact;
}

String _randomUuid() {
  final rand = Random();
  String fourHex() => rand.nextInt(0x10000).toRadixString(16).padLeft(4, '0');
  final part1 = '${fourHex()}${fourHex()}';
  final part2 = fourHex();
  final part3 = (int.parse(fourHex(), radix: 16) & 0x0fff | 0x4000)
      .toRadixString(16)
      .padLeft(4, '0');
  final part4 = (int.parse(fourHex(), radix: 16) & 0x3fff | 0x8000)
      .toRadixString(16)
      .padLeft(4, '0');
  final part5 = '${fourHex()}${fourHex()}${fourHex()}';
  return '$part1-$part2-$part3-$part4-$part5';
}
