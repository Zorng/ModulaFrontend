import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/data/mock_cash_session_repository.dart';
import 'package:modular_pos/features/sale/data/sale_api.dart';
import 'package:modular_pos/features/sale/data/dto/sale_dto.dart';
import 'package:modular_pos/features/sale/data/mock_sale_repository.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';

/// Sale data source mode is config-driven (no runtime UI toggle).
/// Defaults to mock mode until API integration is enabled.
final useMockSaleRepositoryProvider = Provider<bool>(
  (ref) => AppEnv.useMockSaleRepository,
);

final saleRepositoryProvider = Provider<SaleCheckoutRepository>((ref) {
  final useMock = ref.watch(useMockSaleRepositoryProvider);
  if (useMock) {
    final useMockCashSession = ref.watch(useMockCashSessionProvider);
    if (useMockCashSession) {
      final mockCashSessionRepo = ref.watch(mockCashSessionRepositoryProvider);
      return MockSaleRepository(
        cashSessionOpenReader: () => mockCashSessionRepo.isSessionOpen,
      );
    }
    return MockSaleRepository();
  }
  final api = ref.watch(saleApiProvider);
  return SaleRepository(api);
});

class SaleRepository implements SaleCheckoutRepository {
  SaleRepository(this._api);

  final SaleApi _api;

  @override
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

  @override
  Future<void> updateItemQuantity({
    required String saleId,
    required String itemId,
    required int quantity,
  }) async {
    await _api.updateItemQuantity(saleId, itemId, quantity);
  }

  @override
  Future<void> removeItem({
    required String saleId,
    required String itemId,
  }) async {
    await _api.removeItem(saleId, itemId);
  }

  @override
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

  @override
  Future<SaleCheckoutSummary> finalize(String saleId) async {
    final sale = await _api.finalize(saleId);
    return _toCheckoutSummary(sale);
  }

  @override
  Future<void> updateFulfillmentStatus({
    required String saleId,
    required String status,
  }) async {
    await _api.updateFulfillmentStatus(saleId, status: status);
  }

  @override
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

  @override
  Future<void> voidSale(String saleId, {required String reason}) async {
    await _api.voidSale(saleId, reason: reason);
  }

  @override
  Future<SaleContextDto> getSaleContext({required String branchId}) async {
    throw UnimplementedError(
      'FE-SALE-04 will implement getSaleContext in API repository.',
    );
  }

  @override
  Future<SaleCheckoutPreviewDto> computeCheckoutPreview(
    SaleComputeCheckoutPreviewCommand command,
  ) async {
    final preview = await preCheckout(
      saleId: command.saleId,
      tenderCurrency: command.tenderCurrency,
      paymentMethod: command.paymentMethod,
      cashReceived: command.cashReceived?.toJson().cast<String, num>(),
    );
    return SaleCheckoutPreviewDto(
      saleId: preview.saleId,
      tenderCurrency: preview.tenderCurrency,
      paymentMethod: preview.paymentMethod,
      subtotalUsdExact: preview.totalUsdExact,
      subtotalKhrExact: preview.totalKhrExact,
      totalUsdExact: preview.totalUsdExact,
      totalKhrExact: preview.totalKhrExact,
      cashReceivedUsd: preview.cashReceivedUsd,
      cashReceivedKhr: preview.cashReceivedKhr,
      changeGivenUsd: preview.changeGivenUsd,
      changeGivenKhr: preview.changeGivenKhr,
    );
  }

  @override
  Future<SaleKhqrAttemptDto> generateKhqrAttempt(
    SaleGenerateKhqrAttemptCommand command,
  ) async {
    throw UnimplementedError(
      'FE-SALE-07 will implement KHQR generation in API repository.',
    );
  }

  @override
  Future<SaleKhqrStatusDto> checkKhqrStatus(
    SaleCheckKhqrStatusCommand command,
  ) async {
    throw UnimplementedError(
      'FE-SALE-07 will implement KHQR status checks in API repository.',
    );
  }

  @override
  Future<SaleFinalizeSaleResultDto> finalizeSale(
    SaleFinalizeSaleCommand command,
  ) async {
    final finalized = await finalize(command.saleId);
    return SaleFinalizeSaleResultDto(
      saleId: finalized.saleId,
      status: 'FINALIZED',
      totalUsdExact: finalized.totalUsdExact,
      totalKhrExact: finalized.totalKhrExact,
      idempotentReplay: false,
    );
  }

  @override
  Future<SalePlaceOrderResultDto> placeOrder(
    SalePlaceOrderCommand command,
  ) async {
    throw UnimplementedError(
      'FE-SALE-09 will implement pay-later place order in API repository.',
    );
  }

  @override
  Future<SaleAddItemsToOpenTicketResultDto> addItemsToOpenTicket(
    SaleAddItemsToOpenTicketCommand command,
  ) async {
    throw UnimplementedError(
      'FE-SALE-10 will implement add-items to open ticket in API repository.',
    );
  }

  @override
  Future<SaleCheckoutOpenTicketResultDto> checkoutOpenTicket(
    SaleCheckoutOpenTicketCommand command,
  ) async {
    throw UnimplementedError(
      'FE-SALE-11 will implement checkout open ticket in API repository.',
    );
  }

  @override
  Future<SaleCancelOpenTicketResultDto> cancelOpenTicket(
    SaleCancelOpenTicketCommand command,
  ) async {
    throw UnimplementedError(
      'FE-SALE-12 will implement cancel open ticket in API repository.',
    );
  }

  @override
  Future<SaleOrdersPageDto> getOrders(SaleOrdersQueryDto query) async {
    final sales = await listSales(
      status: query.status,
      startDate: query.from,
      endDate: query.to,
      page: query.page,
      limit: query.limit,
    );
    final items = sales
        .map(
          (sale) => SaleOrderSummaryDto(
            saleId: sale.id,
            orderId: sale.id,
            ticketStatus: sale.state,
            fulfillmentStatus: sale.fulfillmentStatus,
            totalUsdExact: sale.totalUsdExact,
            totalKhrExact: sale.totalKhrExact,
            placedAt: sale.createdAt,
          ),
        )
        .toList();
    return SaleOrdersPageDto(
      items: items,
      page: query.page,
      limit: query.limit,
      total: items.length,
    );
  }

  @override
  Future<SaleOpenTicketDetailDto> getOpenTicketDetail({
    required String saleId,
  }) async {
    throw UnimplementedError(
      'FE-SALE-13 will implement open ticket detail in API repository.',
    );
  }

  @override
  Future<SaleReceiptDto> getReceipt({required String saleId}) async {
    throw UnimplementedError(
      'FE-SALE-14 will implement receipt retrieval in API repository.',
    );
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
