import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/x_report_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_payload_builder.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

final saleCartProvider = NotifierProvider<SaleCartNotifier, SaleCartState>(
  SaleCartNotifier.new,
);

class SaleCartNotifier extends Notifier<SaleCartState> {
  SaleCartNotifier();

  late final SaleRepository _repo = ref.read(saleRepositoryProvider);
  static const String _cartStorageKey = 'sale_cart_state';

  void _logIgnoredError(String context, Object error, StackTrace stackTrace) {
    AppLog.e(
      '[SaleCartNotifier] Ignored error: $context',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  SaleCartState build() {
    // Try to restore persisted cart on initialization
    _loadPersistedCart();
    return const SaleCartState();
  }

  Future<void> _loadPersistedCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartStorageKey);
      if (cartJson != null && cartJson.isNotEmpty) {
        final json = jsonDecode(cartJson) as Map<String, dynamic>;
        final restoredState = SaleCartState.fromJson(json);
        // Only restore if cart has items
        if (restoredState.lines.isNotEmpty) {
          state = restoredState;
          AppLog.d(
            '[SaleCartNotifier] Cart restored with ${restoredState.lines.length} items',
          );
        }
      }
    } catch (e, st) {
      _logIgnoredError('_loadPersistedCart', e, st);
      // If restoration fails, start with empty cart
      state = const SaleCartState();
    }
  }

  Future<void> _persistCart(SaleCartState cartState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(cartState.toJson());
      await prefs.setString(_cartStorageKey, cartJson);
    } catch (e, st) {
      _logIgnoredError('_persistCart', e, st);
    }
  }

  Future<void> _clearPersistedCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartStorageKey);
    } catch (e, st) {
      _logIgnoredError('_clearPersistedCart', e, st);
    }
  }

  double _fxRate() {
    final policies = ref.read(policyNotifierProvider);
    return policies.salesPolicy.saleFxRateKhrPerUsd;
  }

  void _assertCanCreateDraftSale() {
    final gate = ref.read(saleAccessGateProvider);
    if (gate.cashSessionLoading) {
      throw Exception('Loading cash session status. Please wait.');
    }
    if (!gate.canCreateDraftSale) {
      throw Exception(
        gate.blockingMessage ??
            'No active cash session. Please start one to begin selling.',
      );
    }
  }

  Future<void> _ensureSaleId() async {
    if (state.saleId != null && state.saleId!.isNotEmpty) return;
    _assertCanCreateDraftSale();
    final id = await _repo.ensureDraft(
      saleType: state.saleType,
      fxRateUsed: _fxRate(),
    );
    final newState = state.copyWith(saleId: id);
    state = newState;
    await _persistCart(newState);
  }

  Future<void> addSelection(SaleItemSelectionResult selection) async {
    _assertCanCreateDraftSale();
    await _ensureSaleId();
    final saleId = state.saleId;
    if (saleId == null) return;

    final addPayload = SaleCartPayloadBuilder.fromSelection(selection);
    final saleItemId = await _repo.addItem(
      saleId: saleId,
      menuItemId: selection.item.id,
      quantity: selection.quantity,
      modifiers: addPayload.modifiers,
      selectedOptionIds: selection.selectedOptionIds,
      unitPriceUsd: addPayload.unitPriceUsd,
      lineTotalUsdExact: addPayload.lineTotalUsdExact,
      addonTotalUsd: addPayload.addonTotalUsd,
      pricingSnapshot: addPayload.pricingSnapshot,
    );
    // Only update local state after successful sync.
    final lines = [...state.lines];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.item.id == selection.item.id &&
          SaleCartPayloadBuilder.mapsEqual(
            line.selectedOptionIds,
            selection.selectedOptionIds,
          )) {
        lines[i] = line.copyWith(
          quantity: line.quantity + selection.quantity,
          saleItemId: line.saleItemId ?? saleItemId,
          selectedOptions: line.selectedOptions.isNotEmpty
              ? line.selectedOptions
              : selection.selectedOptions,
        );
        final newState = state.copyWith(lines: lines);
        state = newState;
        await _persistCart(newState);
        return;
      }
    }
    final newState = state.copyWith(
      lines: [
        ...lines,
        CartLine(
          item: selection.item,
          quantity: selection.quantity,
          selectedOptionIds: selection.selectedOptionIds,
          selectedOptions: selection.selectedOptions,
          saleItemId: saleItemId,
        ),
      ],
    );
    state = newState;
    await _persistCart(newState);
  }

  void setTenderCurrency(String currency) {
    final newState = state.copyWith(tenderCurrency: currency);
    state = newState;
    _persistCart(newState);
  }

  void setPaymentMethod(String method) {
    final newState = state.copyWith(paymentMethod: method);
    state = newState;
    _persistCart(newState);
  }

  void setLines(List<CartLine> lines) {
    final newState = state.copyWith(lines: lines);
    state = newState;
    _persistCart(newState);
  }

  Future<void> setSaleType(String saleType) async {
    // If no draft or no lines yet, just update the sale type for future drafts.
    if (state.saleId == null || state.saleId!.isEmpty || state.lines.isEmpty) {
      final newState = state.copyWith(saleType: saleType);
      state = newState;
      await _persistCart(newState);
      return;
    }

    // If changing sale type mid-cart, recreate the draft with the new type and re-sync items.
    if (state.saleType == saleType) return;
    _assertCanCreateDraftSale();
    final currentLines = state.lines;
    final newSaleId = await _repo.ensureDraft(
      saleType: saleType,
      fxRateUsed: _fxRate(),
    );
    final rebuiltLines = <CartLine>[];

    for (final line in currentLines) {
      final rebuilt = _replayLineToSale(newSaleId, line);
      rebuiltLines.add(await rebuilt);
    }

    final newState = state.copyWith(
      saleType: saleType,
      saleId: newSaleId,
      lines: rebuiltLines,
    );
    state = newState;
    await _persistCart(newState);
  }

  void setCashReceived({double? usd, double? khr}) {
    final newState = state.copyWith(
      cashUsd: usd ?? state.cashUsd,
      cashKhr: khr ?? state.cashKhr,
    );
    state = newState;
    _persistCart(newState);
  }

  Future<void> updateQuantity(int index, int quantity) async {
    if (index < 0 || index >= state.lines.length) return;
    _assertCanCreateDraftSale();
    final lines = [...state.lines];
    final target = lines[index];
    if (quantity <= 0) {
      lines.removeAt(index);
      final newState = state.copyWith(lines: lines);
      state = newState;
      await _persistCart(newState);
      await _removeRemote(target);
      return;
    }
    lines[index] = target.copyWith(quantity: quantity);
    final newState = state.copyWith(lines: lines);
    state = newState;
    await _persistCart(newState);
    await _updateRemoteQuantity(target, quantity);
  }

  Future<void> _updateRemoteQuantity(CartLine line, int quantity) async {
    final saleId = state.saleId;
    if (saleId == null) return;
    // backend expects itemId, but we don't have sale item id mapping;
    // send menuItemId to update; if unsupported backend will ignore.
    try {
      await _repo.updateItemQuantity(
        saleId: saleId,
        itemId: line.saleItemId ?? line.item.id,
        quantity: quantity,
      );
    } catch (e, st) {
      _logIgnoredError('_updateRemoteQuantity', e, st);
    }
  }

  Future<void> _removeRemote(CartLine line) async {
    final saleId = state.saleId;
    if (saleId == null) return;
    try {
      await _repo.removeItem(
        saleId: saleId,
        itemId: line.saleItemId ?? line.item.id,
      );
    } catch (e, st) {
      _logIgnoredError('_removeRemote', e, st);
    }
  }

  void clear() {
    state = const SaleCartState();
    _clearPersistedCart();
  }

  Future<SaleCheckoutSummary> checkout() async {
    _assertCanCreateDraftSale();
    final saleId = state.saleId;
    if (saleId == null) throw Exception('No sale draft');
    final cashReceived = <String, num>{};
    if (state.tenderCurrency.toUpperCase() == 'USD' && state.cashUsd > 0) {
      cashReceived['usd'] = state.cashUsd;
    } else if (state.tenderCurrency.toUpperCase() == 'KHR' &&
        state.cashKhr > 0) {
      cashReceived['khr'] = state.cashKhr;
    }
    await _repo.preCheckout(
      saleId: saleId,
      tenderCurrency: state.tenderCurrency,
      paymentMethod: state.paymentMethod,
      cashReceived: cashReceived.isEmpty ? null : cashReceived,
    );
    final finalized = await _repo.finalize(saleId);
    ref.invalidate(xReportEntriesProvider);
    ref.invalidate(xReportDetailProvider);
    // Reset state so subsequent carts start with a fresh draft.
    clear(); // This now also clears persisted cart
    return finalized;
  }

  Future<CartLine> _replayLineToSale(String saleId, CartLine line) async {
    final payload = SaleCartPayloadBuilder.fromLine(line);
    final saleItemId = await _repo.addItem(
      saleId: saleId,
      menuItemId: line.item.id,
      quantity: line.quantity,
      modifiers: payload.modifiers,
      selectedOptionIds: line.selectedOptionIds,
      unitPriceUsd: payload.unitPriceUsd,
      lineTotalUsdExact: payload.lineTotalUsdExact,
      addonTotalUsd: payload.addonTotalUsd,
      pricingSnapshot: payload.pricingSnapshot,
    );
    return line.copyWith(saleItemId: saleItemId);
  }
}
