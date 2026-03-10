import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/core/printing/esc_pos_receipt_formatter.dart';
import 'package:modular_pos/core/printing/thermal_printer_controller.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/x_report_viewmodel.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
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
    this.receipt,
    required this.idempotentReplay,
  });

  final SaleCheckoutSummary summary;
  final String? receiptId;
  final SaleImmediateReceiptDto? receipt;
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

  late final SaleCartRepository _repo = ref.read(saleCartRepositoryProvider);
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
    return policies.branchPolicy.saleFxRateKhrPerUsd;
  }

  void _assertCanCreateDraftSale() {
    final gate = ref.read(saleAccessGateProvider);
    if (!gate.canAddToCart) {
      throw Exception(
        gate.blockingMessage ?? 'Sale action is currently blocked.',
      );
    }
  }

  SaleCheckoutRepositoryException _saleAccessException(
    SaleAccessGate gate, {
    required String fallbackCode,
    required String fallbackMessage,
  }) {
    return SaleCheckoutRepositoryException(
      reasonCode:
          SaleCheckoutReasonCodes.normalize(gate.reasonCode) ?? fallbackCode,
      message: gate.blockingMessage ?? fallbackMessage,
    );
  }

  String _checkoutMessageForCode(String? rawCode, {String? fallback}) {
    switch (SaleCheckoutReasonCodes.normalize(rawCode)) {
      case SaleCheckoutReasonCodes.unauthorized:
        return 'Your account no longer has access to sell.';
      case SaleCheckoutReasonCodes.branchRequired:
        return 'Branch context is missing. Please switch to an active branch.';
      case SaleCheckoutReasonCodes.branchFrozen:
        return 'This branch is frozen. Sale writes are currently blocked.';
      case SaleCheckoutReasonCodes.cashSessionRequired:
        return 'Open cash session is required before this action.';
      case SaleCheckoutReasonCodes.payLaterDisabled:
        return 'Pay-later is currently disabled for this branch.';
      case SaleCheckoutReasonCodes.khqrBranchReceiverNotConfigured:
        return 'Configure a Bakong receiver account for this branch before generating KHQR.';
      case SaleCheckoutReasonCodes.khqrNotConfirmed:
        return 'KHQR payment is not confirmed yet.';
      case SaleCheckoutReasonCodes.idempotencyConflict:
      case SaleCheckoutReasonCodes.duplicateOperation:
        return 'This checkout is already processing. Please wait before retrying.';
      case SaleCheckoutReasonCodes.offlineUnreachable:
        return 'This action requires online connectivity.';
      case SaleCheckoutReasonCodes.invalidRequest:
        return fallback?.trim().isNotEmpty == true
            ? fallback!.trim()
            : 'The checkout request is invalid. Review the cart and try again.';
      case SaleCheckoutReasonCodes.unknownError:
      case null:
        return fallback?.trim().isNotEmpty == true ? fallback!.trim() : '';
      default:
        return fallback?.trim().isNotEmpty == true ? fallback!.trim() : '';
    }
  }

  SaleCartState _applyCheckoutFailure(
    SaleCartState source, {
    required String? reasonCode,
    String? message,
  }) {
    final normalizedCode = SaleCheckoutReasonCodes.normalize(reasonCode);
    return source.copyWith(
      isFinalizing: false,
      checkoutErrorCode: normalizedCode,
      checkoutErrorMessage: _checkoutMessageForCode(
        normalizedCode,
        fallback: message,
      ),
    );
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
      khqrPayloadType: null,
      khqrDeepLinkUrl: null,
      khqrToAccountId: null,
      khqrAmount: null,
      khqrCurrency: null,
      khqrExpiresAt: null,
      khqrConfirmedAt: null,
      khqrErrorMessage: reason,
      khqrErrorCode: null,
      isKhqrLoading: false,
    );
  }

  SaleCartState _supersededKhqrState(SaleCartState source, {String? reason}) {
    return source.copyWith(
      khqrStatus: SaleKhqrUiStates.superseded,
      khqrAttemptId: null,
      khqrMd5: null,
      khqrQrPayload: null,
      khqrPayloadType: null,
      khqrDeepLinkUrl: null,
      khqrToAccountId: null,
      khqrAmount: null,
      khqrCurrency: null,
      khqrExpiresAt: null,
      khqrConfirmedAt: null,
      khqrErrorMessage: reason,
      khqrErrorCode: null,
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

  bool _shouldAutoGenerateKhqr(SaleCartState source) {
    if (source.lines.isEmpty) return false;
    if (source.paymentMethod.toLowerCase() != 'qr') return false;
    if (source.isKhqrLoading) return false;
    final normalizedStatus = SaleKhqrUiStates.normalize(source.khqrStatus);
    return normalizedStatus == SaleKhqrUiStates.readyToGenerate ||
        normalizedStatus == SaleKhqrUiStates.superseded ||
        (source.khqrMd5 == null || source.khqrMd5!.trim().isEmpty);
  }

  Future<void> _maybeAutoGenerateKhqr({SaleCartState? snapshot}) async {
    final currentState = snapshot ?? state;
    if (!_shouldAutoGenerateKhqr(currentState)) return;
    try {
      await generateKhqrAttempt();
    } catch (error, stackTrace) {
      _logIgnoredError('_maybeAutoGenerateKhqr', error, stackTrace);
    }
  }

  SaleCartState _applyKhqrStatusResult(
    SaleCartState source, {
    String? saleId,
    String? attemptId,
    String? md5,
    String? qrPayload,
    String? payloadType,
    String? deepLinkUrl,
    String? toAccountId,
    double? amount,
    String? currency,
    DateTime? expiresAt,
    DateTime? confirmedAt,
    required String status,
    String? reasonCode,
    String? reasonMessage,
  }) {
    final normalizedStatus = SaleKhqrUiStates.normalize(status);
    final nextSaleId = saleId != null && saleId.trim().isNotEmpty
        ? saleId
        : source.saleId;

    switch (normalizedStatus) {
      case SaleKhqrUiStates.waitingForPayment:
      case SaleKhqrUiStates.pendingConfirmation:
        return source.copyWith(
          saleId: nextSaleId,
          khqrStatus: normalizedStatus,
          khqrAttemptId: attemptId ?? source.khqrAttemptId,
          khqrMd5: md5 ?? source.khqrMd5,
          khqrQrPayload: qrPayload ?? source.khqrQrPayload,
          khqrPayloadType: payloadType ?? source.khqrPayloadType,
          khqrDeepLinkUrl: deepLinkUrl ?? source.khqrDeepLinkUrl,
          khqrToAccountId: toAccountId ?? source.khqrToAccountId,
          khqrAmount: amount ?? source.khqrAmount,
          khqrCurrency: currency ?? source.khqrCurrency,
          khqrExpiresAt: expiresAt ?? source.khqrExpiresAt,
          khqrConfirmedAt: null,
          khqrErrorMessage: reasonMessage,
          khqrErrorCode: reasonCode,
          isKhqrLoading: false,
        );
      case SaleKhqrUiStates.paidConfirmed:
        return source.copyWith(
          saleId: nextSaleId,
          khqrStatus: normalizedStatus,
          khqrAttemptId: attemptId ?? source.khqrAttemptId,
          khqrMd5: md5 ?? source.khqrMd5,
          khqrQrPayload: qrPayload ?? source.khqrQrPayload,
          khqrPayloadType: payloadType ?? source.khqrPayloadType,
          khqrDeepLinkUrl: deepLinkUrl ?? source.khqrDeepLinkUrl,
          khqrToAccountId: toAccountId ?? source.khqrToAccountId,
          khqrAmount: amount ?? source.khqrAmount,
          khqrCurrency: currency ?? source.khqrCurrency,
          khqrExpiresAt: expiresAt ?? source.khqrExpiresAt,
          khqrConfirmedAt: confirmedAt ?? source.khqrConfirmedAt,
          khqrErrorMessage: reasonMessage,
          khqrErrorCode: reasonCode,
          isKhqrLoading: false,
        );
      case SaleKhqrUiStates.cancelled:
      case SaleKhqrUiStates.superseded:
        return source.copyWith(
          saleId: nextSaleId,
          khqrStatus: normalizedStatus,
          khqrAttemptId: null,
          khqrMd5: null,
          khqrQrPayload: null,
          khqrPayloadType: null,
          khqrDeepLinkUrl: null,
          khqrToAccountId: null,
          khqrAmount: null,
          khqrCurrency: null,
          khqrExpiresAt: null,
          khqrConfirmedAt: null,
          khqrErrorMessage: reasonMessage,
          khqrErrorCode: reasonCode,
          isKhqrLoading: false,
        );
      case SaleKhqrUiStates.expired:
        return source.copyWith(
          saleId: nextSaleId,
          khqrStatus: normalizedStatus,
          khqrAttemptId: null,
          khqrMd5: null,
          khqrQrPayload: null,
          khqrPayloadType: null,
          khqrDeepLinkUrl: null,
          khqrToAccountId: null,
          khqrAmount: null,
          khqrCurrency: null,
          khqrExpiresAt: expiresAt ?? source.khqrExpiresAt,
          khqrConfirmedAt: null,
          khqrErrorMessage: reasonMessage,
          khqrErrorCode: reasonCode,
          isKhqrLoading: false,
        );
      case SaleKhqrUiStates.readyToGenerate:
        return _readyKhqrState(
          source.copyWith(saleId: nextSaleId),
          reason: reasonMessage,
        );
      default:
        return source.copyWith(
          saleId: nextSaleId,
          khqrStatus: normalizedStatus,
          khqrErrorMessage: reasonMessage,
          khqrErrorCode: reasonCode,
          isKhqrLoading: false,
        );
    }
  }

  Future<void> addSelection(SaleItemSelectionResult selection) async {
    _assertCanCreateDraftSale();
    final saleId = state.saleId;

    String? saleItemId;
    if (saleId != null && saleId.isNotEmpty) {
      final addPayload = SaleCartPayloadBuilder.fromSelection(selection);
      saleItemId = await _repo.addItem(saleId: saleId, item: addPayload);
    }
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
        await _maybeAutoGenerateKhqr(snapshot: newState);
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
    await _maybeAutoGenerateKhqr(snapshot: newState);
  }

  Future<void> setTenderCurrency(String currency) async {
    if (state.tenderCurrency.toLowerCase() == currency.toLowerCase()) return;
    var newState = state.copyWith(tenderCurrency: currency);
    if (state.paymentMethod.toLowerCase() == 'qr' && state.khqrMd5 != null) {
      newState = _supersededKhqrState(
        newState,
        reason: 'Currency changed. Generate a new KHQR code.',
      );
    }
    state = newState;
    await _persistCart(newState);
    await _maybeAutoGenerateKhqr(snapshot: newState);
  }

  Future<void> setPaymentMethod(String method) async {
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
    await _persistCart(newState);
    await _maybeAutoGenerateKhqr(snapshot: newState);
  }

  void setLines(List<CartLine> lines) {
    final newState = _applyKhqrInvalidationOnCartChange(
      state.copyWith(lines: lines),
    );
    state = newState;
    _persistCart(newState);
    unawaited(_maybeAutoGenerateKhqr(snapshot: newState));
  }

  Future<void> setSaleType(String saleType) async {
    // If no draft or no lines yet, just update the sale type for future drafts.
    if (state.saleId == null || state.saleId!.isEmpty || state.lines.isEmpty) {
      final newState = _applyKhqrInvalidationOnCartChange(
        state.copyWith(saleType: saleType),
      );
      state = newState;
      await _persistCart(newState);
      await _maybeAutoGenerateKhqr(snapshot: newState);
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
    await _maybeAutoGenerateKhqr(snapshot: newState);
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
      await _maybeAutoGenerateKhqr(snapshot: newState);
      await _removeRemote(target);
      return;
    }
    lines[index] = target.copyWith(quantity: quantity);
    final newState = _applyKhqrInvalidationOnCartChange(
      state.copyWith(lines: lines),
    );
    state = newState;
    await _persistCart(newState);
    await _maybeAutoGenerateKhqr(snapshot: newState);
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
      checkoutErrorCode: null,
      lastFinalizedSaleId: null,
      lastReceiptId: null,
      lastReceipt: null,
      lastPrintableReceipt: null,
      lastPrintableReceiptData: null,
      lastPlacedOpenTicketId: null,
      lastPlacedSaleId: null,
    );
  }

  Future<SaleReceiptDto> getReceipt({
    required String saleId,
    bool forceRemote = false,
  }) async {
    final lookupId = _resolveReceiptLookupId(saleId);
    if (!forceRemote) {
      final cachedReceipt = _cachedReceiptForSale(lookupId);
      if (cachedReceipt != null) {
        return cachedReceipt;
      }
    }
    if (lookupId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Receipt identifier is missing for this sale.',
      );
    }
    return _repo.getReceipt(saleId: lookupId);
  }

  Future<bool> printReceipt({required String saleId}) async {
    final lookupId = _resolveReceiptLookupId(saleId);
    final cachedThermalReceipt = _cachedThermalReceiptForSale(lookupId);
    final receipt = await getReceipt(saleId: saleId, forceRemote: true);
    return ref
        .read(thermalPrinterControllerProvider.notifier)
        .printReceipt(
          _toThermalReceiptPrintData(receipt, fallback: cachedThermalReceipt),
        );
  }

  Future<bool> _printCheckoutSnapshot({required String saleId}) async {
    final cachedThermalReceipt = _cachedThermalReceiptForSale(saleId);
    if (cachedThermalReceipt == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Checkout receipt data is not available for printing.',
      );
    }
    return ref
        .read(thermalPrinterControllerProvider.notifier)
        .printReceipt(cachedThermalReceipt);
  }

  Future<SaleOpenTicketDetailDto> getOpenTicketDetail({
    required String saleId,
  }) {
    return _repo.getOpenTicketDetail(saleId: saleId);
  }

  Future<void> generateKhqrAttempt() async {
    _assertCanCreateDraftSale();
    final currentState = state;
    if (currentState.lines.isEmpty) {
      throw Exception('Cannot generate KHQR for an empty cart.');
    }
    if (currentState.paymentMethod.toLowerCase() != 'qr') {
      throw Exception('KHQR can only be generated for QR payment method.');
    }

    final commandLines = _buildCommandLines(currentState.lines);

    final loadingState = currentState.copyWith(
      isKhqrLoading: true,
      khqrErrorMessage: null,
      khqrErrorCode: null,
    );
    state = loadingState;
    await _persistCart(loadingState);

    try {
      final attempt = await _repo.generateKhqrAttempt(
        SaleGenerateKhqrAttemptCommand(
          saleId: currentState.saleId ?? '',
          tenderCurrency: currentState.tenderCurrency.toUpperCase(),
          clientOpId:
              'khqr-generate-${currentState.saleId ?? 'local-cart'}-${DateTime.now().millisecondsSinceEpoch}',
          saleType: currentState.saleType,
          cartLines: commandLines,
          expiresInSeconds: 180,
        ),
      );
      final newState = _applyKhqrStatusResult(
        state,
        saleId: attempt.saleId,
        attemptId: attempt.attemptId,
        md5: attempt.md5,
        qrPayload: attempt.qrPayload,
        payloadType: attempt.payloadType,
        deepLinkUrl: attempt.deepLinkUrl,
        toAccountId: attempt.toAccountId,
        amount: attempt.amount,
        currency: attempt.currency,
        expiresAt: attempt.expiresAt,
        status: attempt.status,
        reasonCode: attempt.reasonCode,
        reasonMessage: attempt.reasonMessage,
      );
      state = newState;
      await _persistCart(newState);
    } on SaleCheckoutRepositoryException catch (e) {
      final errorState = state.copyWith(
        isKhqrLoading: false,
        khqrErrorMessage: e.message,
        khqrErrorCode: e.reasonCode,
      );
      state = errorState;
      await _persistCart(errorState);
      rethrow;
    } catch (e) {
      final errorState = state.copyWith(
        isKhqrLoading: false,
        khqrErrorMessage: e.toString(),
        khqrErrorCode: SaleCheckoutReasonCodes.unknownError,
      );
      state = errorState;
      await _persistCart(errorState);
      rethrow;
    }
  }

  Future<void> checkKhqrStatus({bool silent = false}) async {
    final currentState = state;
    final saleId = currentState.saleId;
    final intentId = currentState.khqrAttemptId;
    final md5 = currentState.khqrMd5;
    if (intentId == null || intentId.isEmpty || md5 == null || md5.isEmpty) {
      throw Exception('KHQR attempt is not available.');
    }
    if (currentState.paymentMethod.toLowerCase() != 'qr') {
      throw Exception('Switch payment method to QR before checking KHQR.');
    }
    if (currentState.isKhqrLoading) return;

    if (!silent) {
      final loadingState = currentState.copyWith(
        isKhqrLoading: true,
        khqrErrorMessage: null,
        khqrErrorCode: null,
      );
      state = loadingState;
      await _persistCart(loadingState);
    }

    try {
      final status = await _repo.checkKhqrStatus(
        SaleCheckKhqrStatusCommand(
          saleId: saleId ?? '',
          md5: md5,
          intentId: intentId,
        ),
      );
      final newState = _applyKhqrStatusResult(
        silent ? currentState : state,
        saleId: status.saleId,
        status: status.status,
        confirmedAt: status.confirmedAt,
        reasonCode: status.reasonCode,
        reasonMessage: status.reasonMessage,
      );
      state = newState;
      await _persistCart(newState);
    } on SaleCheckoutRepositoryException catch (e) {
      final errorState = (silent ? currentState : state).copyWith(
        isKhqrLoading: false,
        khqrErrorMessage: e.message,
        khqrErrorCode: e.reasonCode,
      );
      state = errorState;
      await _persistCart(errorState);
      rethrow;
    } catch (e) {
      final errorState = (silent ? currentState : state).copyWith(
        isKhqrLoading: false,
        khqrErrorMessage: e.toString(),
        khqrErrorCode: SaleCheckoutReasonCodes.unknownError,
      );
      state = errorState;
      await _persistCart(errorState);
      rethrow;
    }
  }

  Future<void> cancelKhqrAttempt() async {
    final currentState = state;
    final saleId = currentState.saleId ?? '';
    final intentId = currentState.khqrAttemptId;
    final md5 = currentState.khqrMd5;
    if (intentId == null || intentId.isEmpty || md5 == null || md5.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'KHQR attempt is not available.',
      );
    }
    if (currentState.paymentMethod.toLowerCase() != 'qr') {
      throw Exception('Switch payment method to QR before cancelling KHQR.');
    }
    if (currentState.isKhqrLoading) return;

    final loadingState = currentState.copyWith(
      isKhqrLoading: true,
      khqrErrorMessage: null,
      khqrErrorCode: null,
    );
    state = loadingState;
    await _persistCart(loadingState);

    try {
      final status = await _repo.cancelKhqrAttempt(
        SaleCancelKhqrAttemptCommand(
          saleId: saleId,
          md5: md5,
          intentId: intentId,
          clientOpId: 'khqr-cancel-$intentId',
        ),
      );
      final newState = _applyKhqrStatusResult(
        state,
        saleId: status.saleId,
        status: status.status,
        confirmedAt: status.confirmedAt,
        reasonCode: status.reasonCode,
        reasonMessage: status.reasonMessage,
      );
      state = newState;
      await _persistCart(newState);
    } on SaleCheckoutRepositoryException catch (e) {
      final errorState = state.copyWith(
        isKhqrLoading: false,
        khqrErrorMessage: e.message,
        khqrErrorCode: e.reasonCode,
      );
      state = errorState;
      await _persistCart(errorState);
      rethrow;
    } catch (e) {
      final errorState = state.copyWith(
        isKhqrLoading: false,
        khqrErrorMessage: e.toString(),
        khqrErrorCode: SaleCheckoutReasonCodes.unknownError,
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
    if (currentState.lines.isEmpty) {
      throw Exception('Cannot finalize an empty cart.');
    }

    final gate = ref.read(saleAccessGateProvider);
    if (!gate.canCheckout) {
      final error = _saleAccessException(
        gate,
        fallbackCode: SaleCheckoutReasonCodes.unknownError,
        fallbackMessage: 'Checkout is currently unavailable.',
      );
      state = _applyCheckoutFailure(
        currentState,
        reasonCode: error.reasonCode,
        message: error.message,
      );
      throw error;
    }

    final tenderCurrency = currentState.tenderCurrency.toUpperCase();
    final paymentMethod = currentState.paymentMethod.toLowerCase();
    final commandPaymentMethod = paymentMethod == 'qr' ? 'khqr' : paymentMethod;
    if (paymentMethod == 'qr' &&
        !saleKhqrCanFinalize(currentState.khqrStatus)) {
      const error = SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.khqrNotConfirmed,
        message: 'KHQR payment is not confirmed yet.',
      );
      state = _applyCheckoutFailure(
        currentState,
        reasonCode: error.reasonCode,
        message: error.message,
      );
      throw error;
    }
    if (paymentMethod == 'qr' &&
        (currentState.khqrMd5 == null || currentState.khqrMd5!.isEmpty)) {
      const error = SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.khqrNotConfirmed,
        message: 'KHQR proof is missing. Generate KHQR again.',
      );
      state = _applyCheckoutFailure(
        currentState,
        reasonCode: error.reasonCode,
        message: error.message,
      );
      throw error;
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
    final commandLines = _buildCommandLines(currentState.lines);

    state = currentState.copyWith(
      isFinalizing: true,
      checkoutErrorMessage: null,
      checkoutErrorCode: null,
      lastFinalizedSaleId: null,
      lastReceiptId: null,
      lastReceipt: null,
      lastPrintableReceipt: null,
      lastPrintableReceiptData: null,
    );

    try {
      final finalizeResult = await _repo.finalizeSale(
        SaleFinalizeSaleCommand(
          saleId: currentState.saleId ?? '',
          paymentMethod: commandPaymentMethod,
          tenderCurrency: tenderCurrency,
          clientOpId: 'sale-finalize-${currentState.saleId ?? 'local-cart'}',
          cashReceived: commandPaymentMethod == 'cash' ? cashReceivedDto : null,
          khqrMd5: commandPaymentMethod == 'khqr' ? currentState.khqrMd5 : null,
          saleType: currentState.saleType,
          cartLines: commandLines,
        ),
      );

      final summary = SaleCheckoutSummary(
        saleId: _resolveFinalizeSaleId(finalizeResult),
        tenderCurrency: tenderCurrency.toLowerCase(),
        paymentMethod: paymentMethod,
        totalUsdExact: finalizeResult.totalUsdExact,
        totalKhrExact: finalizeResult.totalKhrExact,
        cashReceivedUsd: finalizeResult.cashReceivedUsd ?? 0,
        cashReceivedKhr: finalizeResult.cashReceivedKhr ?? 0,
        changeGivenUsd: finalizeResult.changeGivenUsd ?? 0,
        changeGivenKhr: finalizeResult.changeGivenKhr ?? 0,
      );

      ref.invalidate(xReportEntriesProvider);
      ref.invalidate(xReportDetailProvider);

      await _clearPersistedCart();
      final resolvedSaleId = _resolveFinalizeSaleId(finalizeResult);
      final printableReceipt = _buildCheckoutReceiptSnapshot(
        previousState: currentState,
        finalizeResult: finalizeResult,
      );
      final printableReceiptData = _buildCheckoutPrintData(
        previousState: currentState,
        finalizeResult: finalizeResult,
        receiptNumber: printableReceipt.receiptNumber,
        issuedAt: printableReceipt.issuedAt,
      );
      state = SaleCartState(
        lastFinalizedSaleId: resolvedSaleId,
        lastReceiptId: finalizeResult.receiptId,
        lastReceipt: finalizeResult.receipt,
        lastPrintableReceipt: printableReceipt,
        lastPrintableReceiptData: printableReceiptData,
      );
      unawaited(_attemptAutoPrint(resolvedSaleId));

      return SaleCheckoutResult(
        summary: summary,
        receiptId: finalizeResult.receiptId,
        receipt: finalizeResult.receipt,
        idempotentReplay: finalizeResult.idempotentReplay,
      );
    } on SaleCheckoutRepositoryException catch (e) {
      state = _applyCheckoutFailure(
        currentState,
        reasonCode: e.reasonCode,
        message: e.message,
      );
      rethrow;
    } catch (e) {
      state = _applyCheckoutFailure(
        currentState,
        reasonCode: SaleCheckoutReasonCodes.unknownError,
        message: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> _attemptAutoPrint(String saleId) async {
    final printerState = ref.read(thermalPrinterControllerProvider);
    if (!printerState.isConnected) return;

    try {
      await _printCheckoutSnapshot(saleId: saleId);
    } catch (error, stackTrace) {
      AppLog.e(
        '[SaleCartNotifier] Auto-print failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  ThermalReceiptPrintData _toThermalReceiptPrintData(
    SaleReceiptDto receipt, {
    ThermalReceiptPrintData? fallback,
  }) {
    return ThermalReceiptPrintData(
      receiptNumber: receipt.receiptNumber,
      tenantName: _resolveTenantName(ref.read(loginControllerProvider).session),
      branchName: _activeBranchName(),
      cashierName: _cashierName(),
      paymentMethod: receipt.paymentMethod,
      issuedAt: receipt.issuedAt,
      subtotalUsd: receipt.subtotalUsdExact,
      taxUsd: receipt.taxUsdExact,
      totalUsd: receipt.totalUsdExact,
      totalKhr: receipt.totalKhrExact,
      items: receipt.lines
          .toList(growable: false)
          .asMap()
          .entries
          .map(
            (entry) => ThermalReceiptItemLine(
              name: entry.value.name,
              quantity: entry.value.quantity,
              basePriceUsd: entry.value.unitPriceUsd,
              modifiers: entry.value.modifiers.isNotEmpty
                  ? entry.value.modifiers
                        .map(
                          (modifier) => ThermalReceiptModifierLine(
                            name: modifier.name,
                            priceDeltaUsd: modifier.priceDeltaUsd,
                          ),
                        )
                        .toList(growable: false)
                  : _fallbackModifiersForIndex(
                      fallback,
                      index: entry.key,
                      itemName: entry.value.name,
                    ),
            ),
          )
          .toList(growable: false),
      paidAmount: fallback?.paidAmount,
      paidAmountCurrency: fallback?.paidAmountCurrency,
      changeKhr: fallback?.changeKhr,
    );
  }

  SaleReceiptDto? _cachedReceiptForSale(String saleId) {
    final cachedReceipt = state.lastPrintableReceipt;
    if (cachedReceipt == null) {
      return null;
    }

    final normalizedSaleId = saleId.trim();
    if (normalizedSaleId.isEmpty) {
      return cachedReceipt;
    }

    if (state.lastFinalizedSaleId?.trim() == normalizedSaleId) {
      return cachedReceipt;
    }

    return cachedReceipt.saleId.trim() == normalizedSaleId
        ? cachedReceipt
        : null;
  }

  ThermalReceiptPrintData? _cachedThermalReceiptForSale(String saleId) {
    final cachedReceipt = state.lastPrintableReceiptData;
    if (cachedReceipt == null) {
      return null;
    }

    final normalizedSaleId = saleId.trim();
    if (normalizedSaleId.isEmpty) {
      return cachedReceipt;
    }

    if (state.lastFinalizedSaleId?.trim() == normalizedSaleId) {
      return cachedReceipt;
    }

    return state.lastPrintableReceipt?.saleId.trim() == normalizedSaleId
        ? cachedReceipt
        : null;
  }

  String _resolveReceiptLookupId(String saleId) {
    final normalizedSaleId = saleId.trim();
    if (normalizedSaleId.isNotEmpty) {
      return normalizedSaleId;
    }

    final lastFinalizedSaleId = state.lastFinalizedSaleId?.trim() ?? '';
    if (lastFinalizedSaleId.isNotEmpty) {
      return lastFinalizedSaleId;
    }

    final receiptSaleId = state.lastReceipt?.saleId.trim() ?? '';
    if (receiptSaleId.isNotEmpty) {
      return receiptSaleId;
    }

    final cachedReceiptSaleId = state.lastPrintableReceipt?.saleId.trim() ?? '';
    if (cachedReceiptSaleId.isNotEmpty) {
      return cachedReceiptSaleId;
    }

    return state.lastReceiptId?.trim() ?? '';
  }

  String _resolveFinalizeSaleId(SaleFinalizeSaleResultDto finalizeResult) {
    final normalizedSaleId = finalizeResult.saleId.trim();
    if (normalizedSaleId.isNotEmpty) {
      return normalizedSaleId;
    }

    final receiptSaleId = finalizeResult.receipt?.saleId.trim() ?? '';
    if (receiptSaleId.isNotEmpty) {
      return receiptSaleId;
    }

    return finalizeResult.receiptId?.trim() ?? '';
  }

  ThermalReceiptPrintData _buildCheckoutPrintData({
    required SaleCartState previousState,
    required SaleFinalizeSaleResultDto finalizeResult,
    required String receiptNumber,
    required DateTime issuedAt,
  }) {
    final subtotalUsd = _cartSubtotalUsd(previousState);
    final taxUsd = _checkoutTaxUsd(
      subtotalUsd: subtotalUsd,
      totalUsdExact: finalizeResult.totalUsdExact,
    );
    final tenderCurrency = previousState.tenderCurrency.trim().toUpperCase();
    final paymentMethod = previousState.paymentMethod.trim().toLowerCase();
    final paidAmount = paymentMethod == 'cash'
        ? tenderCurrency == 'KHR'
              ? previousState.cashKhr
              : previousState.cashUsd
        : null;
    final changeKhr = paymentMethod == 'cash'
        ? _resolvedCashChangeKhr(
            finalizeResult: finalizeResult,
            previousState: previousState,
            tenderCurrency: tenderCurrency,
          )
        : null;

    return ThermalReceiptPrintData(
      receiptNumber: receiptNumber,
      tenantName: _resolveTenantName(ref.read(loginControllerProvider).session),
      branchName: _activeBranchName(),
      cashierName: _cashierName(),
      paymentMethod: paymentMethod == 'qr' ? 'khqr' : paymentMethod,
      issuedAt: issuedAt,
      subtotalUsd: subtotalUsd,
      taxUsd: taxUsd,
      totalUsd: finalizeResult.totalUsdExact,
      totalKhr: finalizeResult.totalKhrExact,
      items: previousState.lines
          .map(_toThermalReceiptItemLine)
          .toList(growable: false),
      paidAmount: paidAmount,
      paidAmountCurrency: paymentMethod == 'cash' ? tenderCurrency : null,
      changeKhr: changeKhr,
    );
  }

  SaleReceiptDto _buildCheckoutReceiptSnapshot({
    required SaleCartState previousState,
    required SaleFinalizeSaleResultDto finalizeResult,
  }) {
    final issuedAt = finalizeResult.receipt?.issuedAt ?? DateTime.now();
    final resolvedSaleId = _resolveFinalizeSaleId(finalizeResult);
    final receiptNumber = finalizeResult.receiptId?.trim().isNotEmpty == true
        ? finalizeResult.receiptId!.trim()
        : resolvedSaleId;
    final subtotalUsd = _cartSubtotalUsd(previousState);
    final taxUsd = _checkoutTaxUsd(
      subtotalUsd: subtotalUsd,
      totalUsdExact: finalizeResult.totalUsdExact,
    );

    return SaleReceiptDto(
      saleId: resolvedSaleId,
      receiptNumber: receiptNumber,
      paymentMethod: previousState.paymentMethod,
      subtotalUsdExact: subtotalUsd,
      taxUsdExact: taxUsd,
      totalUsdExact: finalizeResult.totalUsdExact,
      totalKhrExact: finalizeResult.totalKhrExact,
      issuedAt: issuedAt,
      lines: previousState.lines.map(_toCachedReceiptLine).toList(),
    );
  }

  ThermalReceiptItemLine _toThermalReceiptItemLine(CartLine line) {
    return ThermalReceiptItemLine(
      name: line.item.name,
      quantity: line.quantity,
      basePriceUsd: line.item.price,
      modifiers: _toThermalReceiptModifiers(line),
    );
  }

  List<ThermalReceiptModifierLine> _toThermalReceiptModifiers(CartLine line) {
    final zeroPriceModifiers = <ThermalReceiptModifierLine>[];
    final pricedModifiers = <ThermalReceiptModifierLine>[];

    for (final options in line.selectedOptions.values) {
      for (final option in options) {
        final name = option.name.trim();
        if (name.isEmpty) continue;
        final modifier = ThermalReceiptModifierLine(
          name: name,
          priceDeltaUsd: option.price,
        );
        if (modifier.hasPriceDelta) {
          pricedModifiers.add(modifier);
        } else {
          zeroPriceModifiers.add(modifier);
        }
      }
    }

    return <ThermalReceiptModifierLine>[
      ...zeroPriceModifiers,
      ...pricedModifiers,
    ];
  }

  SaleReceiptLineDto _toCachedReceiptLine(CartLine line) {
    final payload = SaleCartPayloadBuilder.fromLine(line);
    return SaleReceiptLineDto(
      name: _receiptLineName(line),
      quantity: line.quantity,
      unitPriceUsd: payload.unitPriceUsd ?? 0,
      lineTotalUsdExact: payload.lineTotalUsdExact ?? 0,
      modifiers: _toReceiptModifierLines(line),
    );
  }

  List<SaleReceiptModifierLineDto> _toReceiptModifierLines(CartLine line) {
    return _toThermalReceiptModifiers(line)
        .map(
          (modifier) => SaleReceiptModifierLineDto(
            name: modifier.name,
            priceDeltaUsd: modifier.priceDeltaUsd,
          ),
        )
        .toList(growable: false);
  }

  String _receiptLineName(CartLine line) {
    final optionNames = line.selectedOptions.values
        .expand((options) => options)
        .map((option) => option.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (optionNames.isEmpty) {
      return line.item.name;
    }
    return '${line.item.name} (${optionNames.join(', ')})';
  }

  double _cartSubtotalUsd(SaleCartState state) {
    return state.lines.fold<double>(
      0,
      (sum, line) =>
          sum + (SaleCartPayloadBuilder.fromLine(line).lineTotalUsdExact ?? 0),
    );
  }

  double _checkoutTaxUsd({
    required double subtotalUsd,
    required double totalUsdExact,
  }) {
    if (totalUsdExact <= subtotalUsd) {
      return 0;
    }
    return (totalUsdExact - subtotalUsd).toDouble();
  }

  double _resolvedCashChangeKhr({
    required SaleFinalizeSaleResultDto finalizeResult,
    required SaleCartState previousState,
    required String tenderCurrency,
  }) {
    final backendChangeKhr = finalizeResult.changeGivenKhr;
    if (backendChangeKhr != null && backendChangeKhr > 0) {
      return backendChangeKhr;
    }
    return _cashChangeKhr(
      tenderCurrency: tenderCurrency,
      cashUsd: previousState.cashUsd,
      cashKhr: previousState.cashKhr,
      totalKhr: finalizeResult.totalKhrExact,
    );
  }

  double _cashChangeKhr({
    required String tenderCurrency,
    required double cashUsd,
    required double cashKhr,
    required double totalKhr,
  }) {
    final fxRate = _fxRate();
    final tenderKhr = tenderCurrency == 'KHR'
        ? cashKhr
        : cashUsd * (fxRate == 0 ? 1 : fxRate);
    final change = tenderKhr - totalKhr;
    return change > 0 ? change : 0;
  }

  String _cashierName() {
    final cashierName =
        ref.read(loginControllerProvider).session?.user.name.trim() ?? '';
    return cashierName.isNotEmpty ? cashierName : 'Cashier';
  }

  List<ThermalReceiptModifierLine> _fallbackModifiersForIndex(
    ThermalReceiptPrintData? fallback, {
    required int index,
    required String itemName,
  }) {
    if (fallback == null || index >= fallback.items.length) {
      return const <ThermalReceiptModifierLine>[];
    }

    final fallbackItem = fallback.items[index];
    if (fallbackItem.name.trim() == itemName.trim()) {
      return fallbackItem.modifiers;
    }

    for (final item in fallback.items) {
      if (item.name.trim() == itemName.trim()) {
        return item.modifiers;
      }
    }

    return const <ThermalReceiptModifierLine>[];
  }

  String _activeBranchName() {
    final session = ref.read(loginControllerProvider).session;
    return _resolveBranchName(
      ref.read(authActiveBranchProvider),
      session?.user.branches ?? const <UserBranch>[],
      activeBranchId: ref.read(activeBranchContextIdProvider),
      activeBranchNameOverride: ref.read(authActiveBranchNameOverrideProvider),
    );
  }

  String _resolveTenantName(AuthSession? session) {
    if (session == null || session.memberships.isEmpty) {
      return 'Tenant name';
    }

    final activeTenantId = (session.activeTenantId ?? '').trim();
    for (final membership in session.memberships) {
      if (membership.tenantId == activeTenantId &&
          membership.tenantName.trim().isNotEmpty) {
        return membership.tenantName.trim();
      }
    }

    final firstTenantName = session.memberships.first.tenantName.trim();
    return firstTenantName.isNotEmpty ? firstTenantName : 'Tenant name';
  }

  String _resolveBranchName(
    UserBranch? active,
    List<UserBranch> branches, {
    required String? activeBranchId,
    required String? activeBranchNameOverride,
  }) {
    final overriddenName = (activeBranchNameOverride ?? '').trim();
    if (overriddenName.isNotEmpty) {
      return overriddenName;
    }

    final activeName = active?.name.trim() ?? '';
    if (activeName.isNotEmpty) {
      return activeName;
    }

    final normalizedActiveId = (activeBranchId ?? '').trim();
    if (normalizedActiveId.isNotEmpty) {
      for (final branch in branches) {
        final matchesId =
            branch.branchId.trim() == normalizedActiveId ||
            branch.id.trim() == normalizedActiveId;
        if (matchesId && branch.name.trim().isNotEmpty) {
          return branch.name.trim();
        }
      }
    }

    return 'No branch selected';
  }

  Future<SalePlaceOrderResult> placeOrder() async {
    if (state.isFinalizing) {
      throw Exception('Order placement already in progress.');
    }

    _assertCanCreateDraftSale();
    final gate = ref.read(saleAccessGateProvider);
    if (!gate.canPlacePayLater) {
      final error = _saleAccessException(
        gate,
        fallbackCode: SaleCheckoutReasonCodes.payLaterDisabled,
        fallbackMessage: 'Pay-later order is currently unavailable.',
      );
      state = _applyCheckoutFailure(
        state,
        reasonCode: error.reasonCode,
        message: error.message,
      );
      throw error;
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
      final error = _saleAccessException(
        gate,
        fallbackCode: SaleCheckoutReasonCodes.branchRequired,
        fallbackMessage: 'Branch context is missing. Please switch branch.',
      );
      state = _applyCheckoutFailure(
        currentState,
        reasonCode: error.reasonCode,
        message: error.message,
      );
      throw error;
    }

    final commandLines = _buildCommandLines(currentState.lines);

    state = currentState.copyWith(
      isFinalizing: true,
      checkoutErrorMessage: null,
      checkoutErrorCode: null,
      lastFinalizedSaleId: null,
      lastReceiptId: null,
      lastReceipt: null,
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
      state = _applyCheckoutFailure(
        currentState,
        reasonCode: e.reasonCode,
        message: e.message,
      );
      rethrow;
    } catch (e) {
      state = _applyCheckoutFailure(
        currentState,
        reasonCode: SaleCheckoutReasonCodes.unknownError,
        message: e.toString(),
      );
      rethrow;
    }
  }

  Future<CartLine> _replayLineToSale(String saleId, CartLine line) async {
    final payload = SaleCartPayloadBuilder.fromLine(line);
    final saleItemId = await _repo.addItem(saleId: saleId, item: payload);
    return line.copyWith(saleItemId: saleItemId);
  }

  List<SaleCartLineInputDto> _buildCommandLines(List<CartLine> lines) {
    return lines.map((line) {
      final payload = SaleCartPayloadBuilder.fromLine(line);
      final modifiers = payload.modifiers
          .map(
            (entry) => SaleCartModifierInputDto(
              groupId: entry.groupId,
              optionIds: entry.optionIds,
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
        pricingSnapshot: payload.pricingSnapshot?.toJson(),
      );
    }).toList();
  }
}
