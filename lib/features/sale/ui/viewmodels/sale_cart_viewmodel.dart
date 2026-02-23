import 'dart:math';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/x_report_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_payload_builder.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';
import 'package:shared_preferences/shared_preferences.dart';

final saleCartProvider = NotifierProvider<SaleCartNotifier, SaleCartState>(
  SaleCartNotifier.new,
);

class SaleCheckoutResult {
  const SaleCheckoutResult({
    required this.summary,
    this.receiptId,
    required this.idempotentReplay,
  });

  final SaleCheckoutSummary summary;
  final String? receiptId;
  final bool idempotentReplay;
}

class SalePlaceOrderResult {
  const SalePlaceOrderResult({
    required this.openTicketId,
    required this.saleId,
    required this.idempotentReplay,
  });

  final String openTicketId;
  final String saleId;
  final bool idempotentReplay;
}

class SaleCartNotifier extends Notifier<SaleCartState> {
  SaleCartNotifier();

  late final SaleCheckoutRepository _repo = ref.read(saleRepositoryProvider);
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
    if (!gate.canAddToCart) {
      throw Exception(
        gate.blockingMessage ?? 'Sale action is currently blocked.',
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

  SaleCartState _readyKhqrState(SaleCartState source, {String? reason}) {
    return source.copyWith(
      khqrStatus: SaleKhqrUiStates.readyToGenerate,
      khqrAttemptId: null,
      khqrMd5: null,
      khqrQrPayload: null,
      khqrExpiresAt: null,
      khqrConfirmedAt: null,
      khqrErrorMessage: reason,
      isKhqrLoading: false,
    );
  }

  SaleCartState _supersededKhqrState(SaleCartState source, {String? reason}) {
    return source.copyWith(
      khqrStatus: SaleKhqrUiStates.superseded,
      khqrAttemptId: null,
      khqrMd5: null,
      khqrQrPayload: null,
      khqrExpiresAt: null,
      khqrConfirmedAt: null,
      khqrErrorMessage: reason,
      isKhqrLoading: false,
    );
  }

  SaleCartState _applyKhqrInvalidationOnCartChange(SaleCartState source) {
    if (source.lines.isEmpty) {
      return _readyKhqrState(source);
    }
    if (source.paymentMethod.toLowerCase() != 'qr') {
      return source;
    }
    final status = SaleKhqrUiStates.normalize(source.khqrStatus);
    final shouldSupersede =
        status == SaleKhqrUiStates.waitingForPayment ||
        status == SaleKhqrUiStates.paidConfirmed ||
        status == SaleKhqrUiStates.pendingConfirmation;
    if (!shouldSupersede) return source;
    return _supersededKhqrState(
      source,
      reason: 'Cart changed. Generate a new KHQR code.',
    );
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
        final newState = _applyKhqrInvalidationOnCartChange(
          state.copyWith(lines: lines),
        );
        state = newState;
        await _persistCart(newState);
        return;
      }
    }
    final newState = _applyKhqrInvalidationOnCartChange(
      state.copyWith(
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
      ),
    );
    state = newState;
    await _persistCart(newState);
  }

  void setTenderCurrency(String currency) {
    if (state.tenderCurrency.toLowerCase() == currency.toLowerCase()) return;
    var newState = state.copyWith(tenderCurrency: currency);
    if (state.paymentMethod.toLowerCase() == 'qr' && state.khqrMd5 != null) {
      newState = _supersededKhqrState(
        newState,
        reason: 'Currency changed. Generate a new KHQR code.',
      );
    }
    state = newState;
    _persistCart(newState);
  }

  void setPaymentMethod(String method) {
    if (state.paymentMethod.toLowerCase() == method.toLowerCase()) return;
    var newState = state.copyWith(
      paymentMethod: method,
      khqrErrorMessage: null,
    );
    if (method.toLowerCase() != 'qr') {
      newState = _readyKhqrState(newState);
    } else if (newState.khqrMd5 == null) {
      newState = newState.copyWith(
        khqrStatus: SaleKhqrUiStates.readyToGenerate,
        isKhqrLoading: false,
      );
    }
    state = newState;
    _persistCart(newState);
  }

  void setLines(List<CartLine> lines) {
    final newState = _applyKhqrInvalidationOnCartChange(
      state.copyWith(lines: lines),
    );
    state = newState;
    _persistCart(newState);
  }

  Future<void> setSaleType(String saleType) async {
    // If no draft or no lines yet, just update the sale type for future drafts.
    if (state.saleId == null || state.saleId!.isEmpty || state.lines.isEmpty) {
      final newState = _applyKhqrInvalidationOnCartChange(
        state.copyWith(saleType: saleType),
      );
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

    final newState = _applyKhqrInvalidationOnCartChange(
      state.copyWith(
        saleType: saleType,
        saleId: newSaleId,
        lines: rebuiltLines,
      ),
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
      final newState = _applyKhqrInvalidationOnCartChange(
        state.copyWith(lines: lines),
      );
      state = newState;
      await _persistCart(newState);
      await _removeRemote(target);
      return;
    }
    lines[index] = target.copyWith(quantity: quantity);
    final newState = _applyKhqrInvalidationOnCartChange(
      state.copyWith(lines: lines),
    );
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

  void clearCheckoutFeedback() {
    state = state.copyWith(
      checkoutErrorMessage: null,
      lastFinalizedSaleId: null,
      lastReceiptId: null,
      lastPlacedOpenTicketId: null,
      lastPlacedSaleId: null,
    );
  }

  Future<SaleReceiptDto> getReceipt({required String saleId}) {
    return _repo.getReceipt(saleId: saleId);
  }

  Future<SaleOpenTicketDetailDto> getOpenTicketDetail({
    required String saleId,
  }) {
    return _repo.getOpenTicketDetail(saleId: saleId);
  }

  Future<void> generateKhqrAttempt() async {
    _assertCanCreateDraftSale();
    await _ensureSaleId();
    final currentState = state;
    final saleId = currentState.saleId;
    if (saleId == null || saleId.isEmpty) {
      throw Exception('No sale draft');
    }
    if (currentState.lines.isEmpty) {
      throw Exception('Cannot generate KHQR for an empty cart.');
    }
    if (currentState.paymentMethod.toLowerCase() != 'qr') {
      throw Exception('KHQR can only be generated for QR payment method.');
    }

    final loadingState = currentState.copyWith(
      isKhqrLoading: true,
      khqrErrorMessage: null,
    );
    state = loadingState;
    await _persistCart(loadingState);

    try {
      final attempt = await _repo.generateKhqrAttempt(
        SaleGenerateKhqrAttemptCommand(
          saleId: saleId,
          tenderCurrency: currentState.tenderCurrency.toUpperCase(),
          clientOpId:
              'khqr-generate-$saleId-${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      final newState = state.copyWith(
        khqrStatus: SaleKhqrUiStates.normalize(attempt.status),
        khqrAttemptId: attempt.attemptId,
        khqrMd5: attempt.md5,
        khqrQrPayload: attempt.qrPayload,
        khqrExpiresAt: attempt.expiresAt,
        khqrConfirmedAt: null,
        khqrErrorMessage: attempt.reasonMessage,
        isKhqrLoading: false,
      );
      state = newState;
      await _persistCart(newState);
    } on SaleCheckoutRepositoryException catch (e) {
      final errorState = state.copyWith(
        isKhqrLoading: false,
        khqrErrorMessage: e.message,
      );
      state = errorState;
      await _persistCart(errorState);
      rethrow;
    } catch (e) {
      final errorState = state.copyWith(
        isKhqrLoading: false,
        khqrErrorMessage: e.toString(),
      );
      state = errorState;
      await _persistCart(errorState);
      rethrow;
    }
  }

  Future<void> checkKhqrStatus() async {
    final currentState = state;
    final saleId = currentState.saleId;
    final md5 = currentState.khqrMd5;
    if (saleId == null || saleId.isEmpty || md5 == null || md5.isEmpty) {
      throw Exception('KHQR attempt is not available.');
    }
    if (currentState.paymentMethod.toLowerCase() != 'qr') {
      throw Exception('Switch payment method to QR before checking KHQR.');
    }
    if (currentState.isKhqrLoading) return;

    final loadingState = currentState.copyWith(
      isKhqrLoading: true,
      khqrErrorMessage: null,
    );
    state = loadingState;
    await _persistCart(loadingState);

    try {
      final status = await _repo.checkKhqrStatus(
        SaleCheckKhqrStatusCommand(saleId: saleId, md5: md5),
      );
      final newState = state.copyWith(
        khqrStatus: SaleKhqrUiStates.normalize(status.status),
        khqrConfirmedAt: status.confirmedAt,
        khqrErrorMessage: status.reasonMessage,
        isKhqrLoading: false,
      );
      state = newState;
      await _persistCart(newState);
    } on SaleCheckoutRepositoryException catch (e) {
      final errorState = state.copyWith(
        isKhqrLoading: false,
        khqrErrorMessage: e.message,
      );
      state = errorState;
      await _persistCart(errorState);
      rethrow;
    } catch (e) {
      final errorState = state.copyWith(
        isKhqrLoading: false,
        khqrErrorMessage: e.toString(),
      );
      state = errorState;
      await _persistCart(errorState);
      rethrow;
    }
  }

  Future<SaleCheckoutResult> checkout() async {
    if (state.isFinalizing) {
      throw Exception('Finalize already in progress.');
    }

    _assertCanCreateDraftSale();
    final currentState = state;
    final saleId = currentState.saleId;
    if (saleId == null || saleId.isEmpty) throw Exception('No sale draft');
    if (currentState.lines.isEmpty) {
      throw Exception('Cannot finalize an empty cart.');
    }

    final gate = ref.read(saleAccessGateProvider);
    final branchId = gate.branchId;
    if (branchId == null || branchId.trim().isEmpty) {
      throw Exception('Branch context is missing. Please switch branch.');
    }

    final tenderCurrency = currentState.tenderCurrency.toUpperCase();
    final paymentMethod = currentState.paymentMethod.toLowerCase();
    final commandPaymentMethod = paymentMethod == 'qr' ? 'khqr' : paymentMethod;
    if (paymentMethod == 'qr' &&
        !saleKhqrCanFinalize(currentState.khqrStatus)) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.khqrNotConfirmed,
        message: 'KHQR payment is not confirmed yet.',
      );
    }
    if (paymentMethod == 'qr' &&
        (currentState.khqrMd5 == null || currentState.khqrMd5!.isEmpty)) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.khqrNotConfirmed,
        message: 'KHQR proof is missing. Generate KHQR again.',
      );
    }
    final cashUsd = paymentMethod == 'cash' && tenderCurrency == 'USD'
        ? currentState.cashUsd
        : 0.0;
    final cashKhr = paymentMethod == 'cash' && tenderCurrency == 'KHR'
        ? currentState.cashKhr
        : 0.0;
    final cashReceivedDto = (cashUsd > 0 || cashKhr > 0)
        ? SaleCashReceivedInputDto(
            usd: cashUsd > 0 ? cashUsd : null,
            khr: cashKhr > 0 ? cashKhr : null,
          )
        : null;

    state = currentState.copyWith(
      isFinalizing: true,
      checkoutErrorMessage: null,
      lastFinalizedSaleId: null,
      lastReceiptId: null,
    );

    try {
      final finalizeResult = await _repo.finalizeSale(
        SaleFinalizeSaleCommand(
          saleId: saleId,
          branchId: branchId,
          paymentMethod: commandPaymentMethod,
          tenderCurrency: tenderCurrency,
          clientOpId: 'sale-finalize-$saleId',
          cashReceived: commandPaymentMethod == 'cash' ? cashReceivedDto : null,
          khqrMd5: commandPaymentMethod == 'khqr' ? currentState.khqrMd5 : null,
        ),
      );

      final totalUsd = finalizeResult.totalUsdExact;
      final totalKhr = finalizeResult.totalKhrExact;
      final summary = SaleCheckoutSummary(
        saleId: finalizeResult.saleId,
        tenderCurrency: tenderCurrency.toLowerCase(),
        paymentMethod: paymentMethod,
        totalUsdExact: totalUsd,
        totalKhrExact: totalKhr,
        cashReceivedUsd: cashUsd,
        cashReceivedKhr: cashKhr,
        changeGivenUsd: tenderCurrency == 'USD'
            ? max<double>(0, cashUsd - totalUsd)
            : 0,
        changeGivenKhr: tenderCurrency == 'KHR'
            ? max<double>(0, cashKhr - totalKhr)
            : 0,
      );

      ref.invalidate(xReportEntriesProvider);
      ref.invalidate(xReportDetailProvider);

      await _clearPersistedCart();
      state = SaleCartState(
        lastFinalizedSaleId: finalizeResult.saleId,
        lastReceiptId: finalizeResult.receiptId,
      );

      return SaleCheckoutResult(
        summary: summary,
        receiptId: finalizeResult.receiptId,
        idempotentReplay: finalizeResult.idempotentReplay,
      );
    } on SaleCheckoutRepositoryException catch (e) {
      state = currentState.copyWith(
        isFinalizing: false,
        checkoutErrorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = currentState.copyWith(
        isFinalizing: false,
        checkoutErrorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<SalePlaceOrderResult> placeOrder() async {
    if (state.isFinalizing) {
      throw Exception('Order placement already in progress.');
    }

    _assertCanCreateDraftSale();
    final gate = ref.read(saleAccessGateProvider);
    if (!gate.canPlacePayLater) {
      throw Exception(
        gate.blockingMessage ?? 'Pay-later order is currently unavailable.',
      );
    }

    await _ensureSaleId();
    final currentState = state;
    final saleId = currentState.saleId;
    if (saleId == null || saleId.isEmpty) {
      throw Exception('No sale draft');
    }
    if (currentState.lines.isEmpty) {
      throw Exception('Cannot place an order with an empty cart.');
    }

    final branchId = gate.branchId;
    if (branchId == null || branchId.trim().isEmpty) {
      throw Exception('Branch context is missing. Please switch branch.');
    }

    final commandLines = currentState.lines.map((line) {
      final payload = SaleCartPayloadBuilder.fromLine(line);
      final modifiers = payload.modifiers
          .where(
            (entry) => entry['groupId'] is String && entry['optionIds'] is List,
          )
          .map(
            (entry) => SaleCartModifierInputDto(
              groupId: entry['groupId'] as String,
              optionIds: List<String>.from(
                (entry['optionIds'] as List).map((id) => id.toString()),
              ),
            ),
          )
          .toList();
      return SaleCartLineInputDto(
        menuItemId: line.item.id,
        quantity: line.quantity,
        modifiers: modifiers,
        unitPriceUsd: payload.unitPriceUsd,
        lineTotalUsdExact: payload.lineTotalUsdExact,
        addonTotalUsd: payload.addonTotalUsd,
        pricingSnapshot: payload.pricingSnapshot,
      );
    }).toList();

    state = currentState.copyWith(
      isFinalizing: true,
      checkoutErrorMessage: null,
      lastFinalizedSaleId: null,
      lastReceiptId: null,
      lastPlacedOpenTicketId: null,
      lastPlacedSaleId: null,
    );

    try {
      final result = await _repo.placeOrder(
        SalePlaceOrderCommand(
          saleId: saleId,
          branchId: branchId,
          saleType: currentState.saleType,
          clientOpId: 'sale-place-order-$saleId',
          cartLines: commandLines,
        ),
      );

      await _clearPersistedCart();
      state = SaleCartState(
        lastPlacedOpenTicketId: result.openTicketId,
        lastPlacedSaleId: result.saleId,
      );
      return SalePlaceOrderResult(
        openTicketId: result.openTicketId,
        saleId: result.saleId,
        idempotentReplay: result.idempotentReplay,
      );
    } on SaleCheckoutRepositoryException catch (e) {
      state = currentState.copyWith(
        isFinalizing: false,
        checkoutErrorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = currentState.copyWith(
        isFinalizing: false,
        checkoutErrorMessage: e.toString(),
      );
      rethrow;
    }
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
