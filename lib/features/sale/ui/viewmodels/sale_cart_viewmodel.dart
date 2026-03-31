import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/printing/esc_pos_receipt_formatter.dart';
import 'package:modular_pos/core/printing/thermal_printer_controller.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/current_session_summary_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/x_report_viewmodel.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_discount_resolver.dart';
import 'package:modular_pos/features/sale/data/sale_offline_cash_queue.dart';
import 'package:modular_pos/features/sale/data/sale_outage_store.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';
import 'package:modular_pos/features/sale/domain/models/sale_resolved_discount.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_pricing.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_payload_builder.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final saleCartProvider = NotifierProvider<SaleCartNotifier, SaleCartState>(
  SaleCartNotifier.new,
);

BranchListItem? _resolveActiveBranchKhqrProfile(Ref ref) {
  final activeBranchId =
      (ref.watch(activeBranchContextIdProvider) ??
              ref.watch(
                saleAccessGateProvider.select((gate) => gate.branchId),
              ) ??
              '')
          .trim();
  if (activeBranchId.isEmpty) return null;

  final branchState = ref.watch(branchControllerProvider);
  final currentBranchProfile = branchState.currentBranchProfile;
  if (currentBranchProfile != null &&
      currentBranchProfile.branchId.trim() == activeBranchId) {
    return currentBranchProfile;
  }

  for (final branch in branchState.branches) {
    if (branch.branchId.trim() == activeBranchId) {
      return branch;
    }
  }

  return null;
}

final saleKhqrActiveBranchProfileProvider = Provider<BranchListItem?>(
  (ref) => _resolveActiveBranchKhqrProfile(ref),
);

final saleKhqrReceiverConfiguredProvider = Provider<bool?>((ref) {
  final branchProfile = ref.watch(saleKhqrActiveBranchProfileProvider);
  if (branchProfile == null) return null;
  return (branchProfile.khqrReceiverAccountId ?? '').trim().isNotEmpty;
});

class SaleCheckoutResult {
  const SaleCheckoutResult({
    required this.summary,
    this.orderId,
    this.receiptId,
    this.receipt,
    required this.idempotentReplay,
  });

  final SaleCheckoutSummary summary;
  final String? orderId;
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

class SaleOfflineCaptureResult {
  const SaleOfflineCaptureResult({
    required this.localIntentId,
    required this.orderNumber,
  });

  final String localIntentId;
  final String orderNumber;
}

class SaleCartNotifier extends Notifier<SaleCartState> {
  SaleCartNotifier();

  late final SaleCartRepository _repo = ref.read(saleCartRepositoryProvider);
  late final SaleDiscountResolver _discountResolver = ref.read(
    saleDiscountResolverProvider,
  );
  final Uuid _uuid = const Uuid();
  static const String _cartStorageKey = 'sale_cart_state';
  int _discountResolutionEpoch = 0;

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
        final restoredState = _sanitizeRestoredCartState(
          SaleCartState.fromJson(json),
        );
        // Only restore if cart has items
        if (restoredState.lines.isNotEmpty) {
          state = restoredState;
          AppLog.d(
            '[SaleCartNotifier] Cart restored with ${restoredState.lines.length} items',
          );
          _scheduleDiscountRefresh();
        }
      }
    } catch (e, st) {
      _logIgnoredError('_loadPersistedCart', e, st);
      // If restoration fails, start with empty cart
      state = const SaleCartState();
    }
  }

  SaleCartState _sanitizeRestoredCartState(SaleCartState restoredState) {
    final sanitizedLines = restoredState.lines
        .map(
          (line) => CartLine(
            item: line.item,
            quantity: line.quantity,
            selectedOptionIds: line.selectedOptionIds,
            selectedOptions: line.selectedOptions,
          ),
        )
        .toList(growable: false);
    return restoredState.copyWith(saleId: null, lines: sanitizedLines);
  }

  String _activeBranchIdForDiscountResolution() {
    final activeBranchId =
        (ref.read(activeBranchContextIdProvider) ??
                ref.read(saleAccessGateProvider).branchId ??
                '')
            .trim();
    return activeBranchId;
  }

  List<SaleDiscountResolveLine> _buildDiscountResolveLines(
    List<CartLine> lines,
  ) {
    final quantitiesByMenuItem = <String, int>{};
    for (final line in lines) {
      final menuItemId = line.item.id.trim();
      if (menuItemId.isEmpty || line.quantity <= 0) continue;
      quantitiesByMenuItem.update(
        menuItemId,
        (quantity) => quantity + line.quantity,
        ifAbsent: () => line.quantity,
      );
    }
    return quantitiesByMenuItem.entries
        .map(
          (entry) => SaleDiscountResolveLine(
            menuItemId: entry.key,
            quantity: entry.value,
          ),
        )
        .toList(growable: false);
  }

  void _scheduleDiscountRefresh() {
    unawaited(refreshDiscountEligibility());
  }

  Future<void> refreshDiscountEligibility() async {
    final session = ref.read(loginControllerProvider).session;
    final branchId = _activeBranchIdForDiscountResolution();
    final lines = _buildDiscountResolveLines(state.lines);
    final requestEpoch = ++_discountResolutionEpoch;

    if (session == null ||
        !session.hasEstablishedTenantContext ||
        branchId.isEmpty ||
        lines.isEmpty) {
      state = state.copyWith(
        resolvedDiscounts: null,
        isResolvingDiscounts: false,
        discountResolutionError: null,
      );
      return;
    }

    state = state.copyWith(
      isResolvingDiscounts: true,
      discountResolutionError: null,
    );

    try {
      final resolvedDiscounts = await _discountResolver.resolveForCart(
        branchId: branchId,
        occurredAt: DateTime.now().toUtc(),
        lines: lines,
      );
      if (requestEpoch != _discountResolutionEpoch) return;
      state = state.copyWith(
        resolvedDiscounts: resolvedDiscounts,
        isResolvingDiscounts: false,
        discountResolutionError: null,
      );
    } catch (error, stackTrace) {
      _logIgnoredError('refreshDiscountEligibility', error, stackTrace);
      if (requestEpoch != _discountResolutionEpoch) return;
      state = state.copyWith(
        isResolvingDiscounts: false,
        discountResolutionError:
            'Failed to resolve active discounts for this cart.',
      );
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

  Map<String, ModifierGroup> _groupLookup() {
    final menuState = ref.read(menuViewModelProvider);
    return {
      for (final group in menuState.modifierGroups) group.id: group,
      for (final entry in menuState.hydratedModifierGroups.entries)
        entry.key: entry.value,
    };
  }

  List<String> _modifierLabels(
    CartLine line,
    Map<String, ModifierGroup> groupLookup,
  ) {
    final labels = <String>[];
    for (final entry in line.selectedOptionIds.entries) {
      final group = groupLookup[entry.key];
      if (group == null) continue;
      for (final optionId in entry.value) {
        final option = group.options.where(
          (candidate) => candidate.id == optionId,
        );
        if (option.isNotEmpty) {
          labels.add(option.first.name);
        }
      }
    }
    return labels;
  }

  SaleCartPricing _cartPricingForState(
    SaleCartState cartState, {
    Map<String, ModifierGroup>? groupLookup,
    BranchPolicy? branchPolicy,
  }) {
    return SaleCartPricingCalculator.calculate(
      lines: cartState.lines,
      groupLookup: groupLookup ?? _groupLookup(),
      branchPolicy:
          branchPolicy ?? ref.read(policyNotifierProvider).branchPolicy,
      resolvedDiscounts: cartState.resolvedDiscounts,
    );
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
      case SaleCheckoutReasonCodes.khqrFinalizationPending:
        return 'KHQR payment is confirmed, but backend finalization is still pending.';
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

  SaleCartState _readyKhqrState(SaleCartState source, {String? reason}) {
    return source.copyWith(
      khqrStatus: SaleKhqrUiStates.readyToGenerate,
      khqrAttemptId: null,
      khqrMd5: null,
      khqrQrPayload: null,
      khqrPayloadType: null,
      khqrDeepLinkUrl: null,
      khqrToAccountId: null,
      khqrReceiverName: null,
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
      khqrReceiverName: null,
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
      return _readyKhqrState(source.copyWith(saleId: null));
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
      source.copyWith(saleId: null),
      reason: 'Cart changed. Generate a new KHQR code.',
    );
  }

  BranchListItem? _activeBranchKhqrProfile() {
    return ref.read(saleKhqrActiveBranchProfileProvider);
  }

  SaleCheckoutRepositoryException? _khqrReceiverPreconditionError() {
    final activeBranchProfile = _activeBranchKhqrProfile();
    if (activeBranchProfile == null) return null;

    final receiverAccountId = (activeBranchProfile.khqrReceiverAccountId ?? '')
        .trim();
    if (receiverAccountId.isNotEmpty) return null;

    return const SaleCheckoutRepositoryException(
      reasonCode: SaleCheckoutReasonCodes.khqrBranchReceiverNotConfigured,
      message:
          'Configure a Bakong receiver account for this branch before generating KHQR.',
    );
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
    String? receiverName,
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
          khqrReceiverName: receiverName ?? source.khqrReceiverName,
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
          khqrReceiverName: receiverName ?? source.khqrReceiverName,
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
          khqrReceiverName: null,
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
          khqrReceiverName: null,
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
          selectedOptions: line.selectedOptions.isNotEmpty
              ? line.selectedOptions
              : selection.selectedOptions,
        );
        final newState = _applyKhqrInvalidationOnCartChange(
          state.copyWith(saleId: null, lines: lines),
        );
        state = newState;
        await _persistCart(newState);
        _scheduleDiscountRefresh();
        return;
      }
    }
    final newState = _applyKhqrInvalidationOnCartChange(
      state.copyWith(
        saleId: null,
        lines: [
          ...lines,
          CartLine(
            item: selection.item,
            quantity: selection.quantity,
            selectedOptionIds: selection.selectedOptionIds,
            selectedOptions: selection.selectedOptions,
          ),
        ],
      ),
    );
    state = newState;
    await _persistCart(newState);
    _scheduleDiscountRefresh();
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
  }

  void setLines(List<CartLine> lines) {
    final newState = _applyKhqrInvalidationOnCartChange(
      state.copyWith(saleId: null, lines: lines),
    );
    state = newState;
    _persistCart(newState);
    _scheduleDiscountRefresh();
  }

  Future<void> setSaleType(String saleType) async {
    if (state.saleType == saleType) return;
    final newState = _applyKhqrInvalidationOnCartChange(
      state.copyWith(saleId: null, saleType: saleType),
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
        state.copyWith(saleId: null, lines: lines),
      );
      state = newState;
      await _persistCart(newState);
      _scheduleDiscountRefresh();
      return;
    }
    lines[index] = target.copyWith(quantity: quantity);
    final newState = _applyKhqrInvalidationOnCartChange(
      state.copyWith(saleId: null, lines: lines),
    );
    state = newState;
    await _persistCart(newState);
    _scheduleDiscountRefresh();
  }

  void clear() {
    _discountResolutionEpoch++;
    state = const SaleCartState();
    _clearPersistedCart();
  }

  void clearCheckoutFeedback() {
    state = state.copyWith(
      checkoutErrorMessage: null,
      checkoutErrorCode: null,
      lastFinalizedSaleId: null,
      lastFinalizedOrderId: null,
      lastReceiptId: null,
      lastReceipt: null,
      lastPrintableReceipt: null,
      lastPrintableReceiptData: null,
      lastPlacedOpenTicketId: null,
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
    required String orderId,
  }) {
    return _repo.getOpenTicketDetail(orderId: orderId);
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

    final receiverPreconditionError = _khqrReceiverPreconditionError();
    if (receiverPreconditionError != null) {
      final errorState = currentState.copyWith(
        khqrStatus: SaleKhqrUiStates.readyToGenerate,
        isKhqrLoading: false,
        khqrErrorMessage: receiverPreconditionError.message,
        khqrErrorCode: receiverPreconditionError.reasonCode,
      );
      state = errorState;
      await _persistCart(errorState);
      throw receiverPreconditionError;
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
          saleId: '',
          tenderCurrency: currentState.tenderCurrency.toUpperCase(),
          clientOpId:
              'khqr-generate-local-cart-${DateTime.now().millisecondsSinceEpoch}',
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
        receiverName: attempt.receiverName,
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
          saleId: currentState.saleId ?? '',
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
          saleId: currentState.saleId ?? '',
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

  String _buildLocalOutageOrderNumber(DateTime timestamp) {
    final compact = timestamp
        .toUtc()
        .millisecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase();
    return 'LOCAL-$compact';
  }

  List<SaleOutageLineSnapshot> _buildOutageLineSnapshots(
    List<CartLine> lines,
    Map<String, ModifierGroup> groupLookup,
    SaleCartPricing cartPricing,
  ) {
    return lines
        .asMap()
        .entries
        .map(
          (entry) => SaleOutageLineSnapshot(
            menuItemId: entry.value.item.id,
            name: entry.value.item.name,
            quantity: entry.value.quantity,
            selectedOptionIds: {
              for (final selected in entry.value.selectedOptionIds.entries)
                selected.key: List<String>.from(selected.value),
            },
            modifierLabels: _modifierLabels(entry.value, groupLookup),
            unitPriceUsd: cartPricing
                .pricingForIndex(entry.key)
                .discountedUnitPriceUsd,
            lineTotalUsdExact: cartPricing
                .pricingForIndex(entry.key)
                .lineTotalUsd,
          ),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _cartDiscountSnapshot(
    SaleCartPricing cartPricing, {
    required double subtotalKhr,
    required double discountKhr,
    required double taxKhr,
  }) {
    return <String, dynamic>{
      'subtotalUsd': cartPricing.preDiscountSubtotalUsd,
      'subtotalAfterDiscountUsd': cartPricing.subtotalUsd,
      'itemDiscountUsd': cartPricing.itemDiscountUsd,
      'branchWideDiscountUsd': cartPricing.branchWideDiscountUsd,
      'discountUsd': cartPricing.discountUsd,
      'subtotalKhr': subtotalKhr,
      'discountKhr': discountKhr,
      'vatUsd': cartPricing.taxUsd,
      'vatKhr': taxKhr,
      'grandTotalUsd': cartPricing.grandTotalUsd,
      'grandTotalKhr': cartPricing.grandTotalKhr,
      if ((cartPricing.discountResolutionBranchId ?? '').trim().isNotEmpty)
        'discountResolutionBranchId': cartPricing.discountResolutionBranchId,
      if (cartPricing.branchWideRules.isNotEmpty)
        'branchWideDiscounts': cartPricing.branchWideRules
            .map(
              (rule) => <String, dynamic>{
                'ruleId': rule.ruleId,
                'percentage': rule.percentage,
                'scope': rule.scope,
              },
            )
            .toList(growable: false),
    };
  }

  Future<SaleOfflineCaptureResult> _captureOfflineOutageOrder({
    required String requiredPaymentMethod,
    required String sourceMode,
    required String offlineOnlyMessage,
    required String invalidMethodMessage,
    bool enqueueCashReplay = false,
    bool enqueueManualClaimCapture = false,
    bool requiresOpenCashSession = false,
  }) async {
    if (state.isFinalizing) {
      throw Exception('Offline order capture already in progress.');
    }

    final connectivityStatus = ref.read(appConnectivityStatusProvider);
    if (connectivityStatus != AppConnectivityStatus.offline) {
      throw SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: offlineOnlyMessage,
      );
    }

    _assertCanCreateDraftSale();
    final currentState = state;
    if (currentState.lines.isEmpty) {
      throw Exception('Cannot capture an empty cart.');
    }
    if (currentState.paymentMethod.toLowerCase() != requiredPaymentMethod) {
      throw SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: invalidMethodMessage,
      );
    }

    final gate = ref.read(saleAccessGateProvider);
    if (!gate.canCreateDraftSale) {
      final error = _saleAccessException(
        gate,
        fallbackCode: SaleCheckoutReasonCodes.unknownError,
        fallbackMessage: 'Offline order capture is currently unavailable.',
      );
      state = _applyCheckoutFailure(
        currentState,
        reasonCode: error.reasonCode,
        message: error.message,
      );
      throw error;
    }
    if (requiresOpenCashSession && !gate.cashSessionOpen) {
      const error = SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.cashSessionRequired,
        message:
            'Open a cash session before capturing an external payment claim.',
      );
      state = _applyCheckoutFailure(
        currentState,
        reasonCode: error.reasonCode,
        message: error.message,
      );
      throw error;
    }

    final scope = ref.read(saleOutageScopeProvider);
    if (scope == null) {
      const error = SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.branchRequired,
        message: 'Tenant, branch, or account context is missing.',
      );
      state = _applyCheckoutFailure(
        currentState,
        reasonCode: error.reasonCode,
        message: error.message,
      );
      throw error;
    }

    final groupLookup = _groupLookup();
    final branchPolicy = ref.read(policyNotifierProvider).branchPolicy;
    final cartPricing = _cartPricingForState(
      currentState,
      groupLookup: groupLookup,
      branchPolicy: branchPolicy,
    );
    final subtotalUsd = cartPricing.preDiscountSubtotalUsd;
    final discountUsd = cartPricing.discountUsd;
    final taxUsd = cartPricing.taxUsd;
    final totalUsd = cartPricing.grandTotalUsd;
    final totalKhr = cartPricing.grandTotalKhr;
    final subtotalKhr = _roundKhr(
      subtotalUsd * _fxRate(),
      enabled: branchPolicy.saleKhrRoundingEnabled,
      mode: BranchPolicyRoundingModes.normalize(
        branchPolicy.saleKhrRoundingMode,
      ),
      granularity: BranchPolicyRoundingGranularities.asAmount(
        branchPolicy.saleKhrRoundingGranularity,
      ),
    );
    final discountKhr = _roundKhr(
      discountUsd * _fxRate(),
      enabled: branchPolicy.saleKhrRoundingEnabled,
      mode: BranchPolicyRoundingModes.normalize(
        branchPolicy.saleKhrRoundingMode,
      ),
      granularity: BranchPolicyRoundingGranularities.asAmount(
        branchPolicy.saleKhrRoundingGranularity,
      ),
    );
    final taxKhr = _roundKhr(
      taxUsd * _fxRate(),
      enabled: branchPolicy.saleKhrRoundingEnabled,
      mode: BranchPolicyRoundingModes.normalize(
        branchPolicy.saleKhrRoundingMode,
      ),
      granularity: BranchPolicyRoundingGranularities.asAmount(
        branchPolicy.saleKhrRoundingGranularity,
      ),
    );
    final timestamp = DateTime.now().toUtc();
    final localIntentId = _uuid.v4();
    final orderNumber = _buildLocalOutageOrderNumber(timestamp);
    final normalizedTenderCurrency = currentState.tenderCurrency
        .trim()
        .toUpperCase();
    final double cashReceivedUsd = normalizedTenderCurrency == 'USD'
        ? (currentState.cashUsd > 0 ? currentState.cashUsd : totalUsd)
        : 0;
    final double cashReceivedKhr = normalizedTenderCurrency == 'KHR'
        ? (currentState.cashKhr > 0 ? currentState.cashKhr : totalKhr)
        : 0;
    final cashReceivedTenderAmount = normalizedTenderCurrency == 'KHR'
        ? cashReceivedKhr
        : cashReceivedUsd;
    final replayItems = (enqueueCashReplay || enqueueManualClaimCapture)
        ? _buildOfflineCashReplayItems(
            currentState.lines,
            groupLookup,
            cartPricing,
          )
        : const <Map<String, dynamic>>[];

    final record = SaleOutageOrderRecord(
      localIntentId: localIntentId,
      orderNumber: orderNumber,
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      accountId: scope.accountId,
      saleType: currentState.saleType,
      paymentMethodRequested: currentState.paymentMethod.toLowerCase(),
      tenderCurrency: normalizedTenderCurrency,
      cashReceivedUsd: cashReceivedUsd,
      cashReceivedKhr: cashReceivedKhr,
      totalUsd: totalUsd,
      totalKhr: totalKhr,
      lines: _buildOutageLineSnapshots(
        currentState.lines,
        groupLookup,
        cartPricing,
      ),
      state: enqueueCashReplay
          ? SaleOutageOrderStates.awaitingSettlement
          : SaleOutageOrderStates.localOpenOrderCaptured,
      sourceMode: sourceMode,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    final outageStore = ref.read(saleOutageStoreProvider);
    await outageStore.write(record);
    if (enqueueCashReplay || enqueueManualClaimCapture) {
      try {
        final replayQueue = ref.read(saleOfflineCashQueueProvider);
        if (enqueueCashReplay) {
          final replayPayload = <String, dynamic>{
            'orderId': _uuid.v4(),
            'saleId': _uuid.v4(),
            'items': replayItems,
            'saleType': _normalizeCheckoutSaleType(currentState.saleType),
            'tenderCurrency': normalizedTenderCurrency,
            'cashReceivedTenderAmount': cashReceivedTenderAmount,
            'pricingSnapshot': <String, dynamic>{
              ..._cartDiscountSnapshot(
                cartPricing,
                subtotalKhr: subtotalKhr,
                discountKhr: discountKhr,
                taxKhr: taxKhr,
              ),
              'saleFxRateKhrPerUsd': branchPolicy.saleFxRateKhrPerUsd,
              'saleKhrRoundingEnabled': branchPolicy.saleKhrRoundingEnabled,
              'saleKhrRoundingMode': branchPolicy.saleKhrRoundingMode,
              'saleKhrRoundingGranularity':
                  branchPolicy.saleKhrRoundingGranularity,
            },
          };
          await replayQueue.enqueueCheckoutCashFinalize(
            scope: scope,
            localIntentId: localIntentId,
            occurredAt: timestamp,
            payload: replayPayload,
          );
        }
        if (enqueueManualClaimCapture) {
          final replayPayload = <String, dynamic>{
            'orderId': _uuid.v4(),
            'items': replayItems,
            'pricingSnapshot': _cartDiscountSnapshot(
              cartPricing,
              subtotalKhr: subtotalKhr,
              discountKhr: discountKhr,
              taxKhr: taxKhr,
            ),
          };
          await replayQueue.enqueueManualExternalPaymentClaimCapture(
            scope: scope,
            localIntentId: localIntentId,
            occurredAt: timestamp,
            payload: replayPayload,
          );
        }
      } catch (_) {
        await outageStore.deleteByLocalIntentId(
          scope: scope,
          localIntentId: localIntentId,
        );
        rethrow;
      }
    }
    await _clearPersistedCart();
    state = const SaleCartState();
    return SaleOfflineCaptureResult(
      localIntentId: localIntentId,
      orderNumber: orderNumber,
    );
  }

  Future<SaleOfflineCaptureResult> captureOfflineCashOrder() {
    return _captureOfflineOutageOrder(
      requiredPaymentMethod: 'cash',
      sourceMode: SaleOutageSourceModes.standardOpenOrder,
      offlineOnlyMessage:
          'Offline cash replay is only available while offline.',
      invalidMethodMessage:
          'Only cash orders can be queued offline in this slice.',
      enqueueCashReplay: true,
    );
  }

  Future<SaleOfflineCaptureResult> captureOfflineManualClaimOrder() async {
    return _captureOfflineOutageOrder(
      requiredPaymentMethod: 'qr',
      sourceMode: SaleOutageSourceModes.manualExternalPaymentClaim,
      offlineOnlyMessage:
          'Manual claim capture is only available while offline.',
      invalidMethodMessage:
          'Manual external-payment claim capture requires QR payment selection.',
      requiresOpenCashSession: true,
    );
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
      lastFinalizedOrderId: null,
      lastReceiptId: null,
      lastReceipt: null,
      lastPrintableReceipt: null,
      lastPrintableReceiptData: null,
    );

    try {
      final finalizeResult = await _repo.finalizeSale(
        SaleFinalizeSaleCommand(
          saleId: commandPaymentMethod == 'cash'
              ? ''
              : (currentState.saleId ?? ''),
          paymentMethod: commandPaymentMethod,
          tenderCurrency: tenderCurrency,
          clientOpId:
              'sale-finalize-local-cart-${DateTime.now().millisecondsSinceEpoch}',
          cashReceived: commandPaymentMethod == 'cash' ? cashReceivedDto : null,
          khqrIntentId: commandPaymentMethod == 'khqr'
              ? currentState.khqrAttemptId
              : null,
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
      ref.invalidate(currentSessionSummaryProvider);
      unawaited(ref.read(cashSessionViewModelProvider.notifier).load());

      await _clearPersistedCart();
      final resolvedSaleId = _resolveFinalizeSaleId(finalizeResult);
      final printableReceipt = _buildCheckoutReceiptSnapshot(
        previousState: currentState,
        finalizeResult: finalizeResult,
      );
      final printableReceiptData = _buildCheckoutPrintData(
        previousState: currentState,
        receiptNumber: printableReceipt.receiptNumber,
        issuedAt: printableReceipt.issuedAt,
      );
      state = SaleCartState(
        lastFinalizedSaleId: resolvedSaleId,
        lastFinalizedOrderId: finalizeResult.orderId,
        lastReceiptId: finalizeResult.receiptId,
        lastReceipt: finalizeResult.receipt,
        lastPrintableReceipt: printableReceipt,
        lastPrintableReceiptData: printableReceiptData,
      );
      unawaited(_attemptAutoPrint(resolvedSaleId));

      return SaleCheckoutResult(
        summary: summary,
        orderId: finalizeResult.orderId,
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
      discountUsd: receipt.discountUsdExact,
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
                  ? _toThermalReceiptReceiptModifiers(
                      entry.value.modifiers,
                      fallback: _fallbackModifiersForIndex(
                        fallback,
                        index: entry.key,
                        itemName: entry.value.name,
                      ),
                    )
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
    required String receiptNumber,
    required DateTime issuedAt,
  }) {
    final totals = _checkoutCartTotals(previousState);
    final tenderCurrency = previousState.tenderCurrency.trim().toUpperCase();
    final paymentMethod = previousState.paymentMethod.trim().toLowerCase();
    final paidAmount = paymentMethod == 'cash'
        ? tenderCurrency == 'KHR'
              ? previousState.cashKhr
              : previousState.cashUsd
        : null;
    final changeKhr = paymentMethod == 'cash'
        ? _resolvedCashChangeKhr(
            previousState: previousState,
            tenderCurrency: tenderCurrency,
            totalKhr: totals.totalKhr,
          )
        : null;

    return ThermalReceiptPrintData(
      receiptNumber: receiptNumber,
      tenantName: _resolveTenantName(ref.read(loginControllerProvider).session),
      branchName: _activeBranchName(),
      cashierName: _cashierName(),
      paymentMethod: paymentMethod == 'qr' ? 'khqr' : paymentMethod,
      issuedAt: issuedAt,
      subtotalUsd: totals.subtotalUsd,
      discountUsd: totals.discountUsd,
      taxUsd: totals.taxUsd,
      totalUsd: totals.totalUsd,
      totalKhr: totals.totalKhr,
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
    final receiptNumber =
        finalizeResult.receipt?.receiptNumber.trim().isNotEmpty == true
        ? finalizeResult.receipt!.receiptNumber.trim()
        : resolvedSaleId;
    final totals = _checkoutCartTotals(previousState);
    final cartPricing = _cartPricingForState(previousState);

    return SaleReceiptDto(
      saleId: resolvedSaleId,
      receiptNumber: receiptNumber,
      paymentMethod: previousState.paymentMethod,
      subtotalUsdExact: totals.subtotalUsd,
      discountUsdExact: totals.discountUsd,
      taxUsdExact: totals.taxUsd,
      totalUsdExact: totals.totalUsd,
      totalKhrExact: totals.totalKhr,
      issuedAt: issuedAt,
      lines: previousState.lines
          .asMap()
          .entries
          .map(
            (entry) => _toCachedReceiptLine(
              entry.value,
              linePricing: cartPricing.pricingForIndex(entry.key),
              cartPricing: cartPricing,
            ),
          )
          .toList(growable: false),
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
    final groupLookup = _modifierGroupLookup();
    final zeroPriceModifiers = <ThermalReceiptModifierLine>[];
    final pricedModifiers = <ThermalReceiptModifierLine>[];

    for (final entry in line.selectedOptionIds.entries) {
      final group = groupLookup[entry.key];
      final options = _resolveModifierOptions(
        line: line,
        groupId: entry.key,
        optionIds: entry.value,
        group: group,
      );
      for (final option in options) {
        final name = option.name.trim();
        if (name.isEmpty) continue;
        final modifier = ThermalReceiptModifierLine(
          name: name,
          groupName: _groupNameForModifier(group),
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

  SaleReceiptLineDto _toCachedReceiptLine(
    CartLine line, {
    required SaleCartLinePricing linePricing,
    required SaleCartPricing cartPricing,
  }) {
    final payload = SaleCartPayloadBuilder.fromLine(
      line,
      pricing: linePricing,
      cartPricing: cartPricing,
    );
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
            name: modifier.displayName,
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

  ({
    double subtotalUsd,
    double discountUsd,
    double taxUsd,
    double totalUsd,
    double totalKhr,
  })
  _checkoutCartTotals(SaleCartState state) {
    final cartPricing = _cartPricingForState(state);
    return (
      subtotalUsd: cartPricing.preDiscountSubtotalUsd,
      discountUsd: cartPricing.discountUsd,
      taxUsd: cartPricing.taxUsd,
      totalUsd: cartPricing.grandTotalUsd,
      totalKhr: cartPricing.grandTotalKhr,
    );
  }

  double _resolvedCashChangeKhr({
    required SaleCartState previousState,
    required String tenderCurrency,
    required double totalKhr,
  }) {
    return _cashChangeKhr(
      tenderCurrency: tenderCurrency,
      cashUsd: previousState.cashUsd,
      cashKhr: previousState.cashKhr,
      totalKhr: totalKhr,
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

  double _roundKhr(
    double amount, {
    required bool enabled,
    required String mode,
    required double granularity,
  }) {
    if (!enabled) {
      return amount;
    }
    final step = granularity <= 0 ? 100.0 : granularity;
    final ratio = amount / step;
    switch (mode.toUpperCase()) {
      case BranchPolicyRoundingModes.up:
        return ratio.ceil() * step;
      case BranchPolicyRoundingModes.down:
        return ratio.floor() * step;
      default:
        return ratio.round() * step;
    }
  }

  String _cashierName() {
    final cashierName =
        ref.read(loginControllerProvider).session?.user.name.trim() ?? '';
    return cashierName.isNotEmpty ? cashierName : 'Cashier';
  }

  Map<String, ModifierGroup> _modifierGroupLookup() {
    final menuState = ref.read(menuViewModelProvider);
    return <String, ModifierGroup>{
      for (final group in menuState.modifierGroups) group.id: group,
      for (final entry in menuState.hydratedModifierGroups.entries)
        entry.key: entry.value,
    };
  }

  List<ModifierOption> _resolveModifierOptions({
    required CartLine line,
    required String groupId,
    required List<String> optionIds,
    required ModifierGroup? group,
  }) {
    final selectedOptions = line.selectedOptions[groupId];
    if (selectedOptions != null && selectedOptions.isNotEmpty) {
      return selectedOptions;
    }
    if (group == null) {
      return const <ModifierOption>[];
    }

    final resolved = <ModifierOption>[];
    for (final optionId in optionIds) {
      final option = group.options.firstWhere(
        (candidate) => candidate.id == optionId,
        orElse: () => const ModifierOption(id: '', name: '', price: 0),
      );
      if (option.id.isNotEmpty) {
        resolved.add(option);
      }
    }
    return resolved;
  }

  String? _groupNameForModifier(ModifierGroup? group) {
    final name = group?.name.trim() ?? '';
    return name.isEmpty ? null : name;
  }

  List<ThermalReceiptModifierLine> _toThermalReceiptReceiptModifiers(
    List<SaleReceiptModifierLineDto> modifiers, {
    required List<ThermalReceiptModifierLine> fallback,
  }) {
    return modifiers
        .map((modifier) {
          final fallbackModifier = _matchFallbackModifier(modifier, fallback);
          final fallbackGroupName = fallbackModifier?.groupName;
          return ThermalReceiptModifierLine(
            name: modifier.name,
            groupName:
                _shouldApplyFallbackGroupName(modifier.name, fallbackGroupName)
                ? fallbackGroupName
                : null,
            priceDeltaUsd: modifier.priceDeltaUsd,
          );
        })
        .toList(growable: false);
  }

  ThermalReceiptModifierLine? _matchFallbackModifier(
    SaleReceiptModifierLineDto modifier,
    List<ThermalReceiptModifierLine> fallback,
  ) {
    final normalizedName = modifier.name.trim().toLowerCase();
    for (final fallbackModifier in fallback) {
      if (fallbackModifier.name.trim().toLowerCase() != normalizedName) {
        continue;
      }
      if ((fallbackModifier.priceDeltaUsd - modifier.priceDeltaUsd).abs() <
          0.005) {
        return fallbackModifier;
      }
    }
    return null;
  }

  bool _shouldApplyFallbackGroupName(String name, String? groupName) {
    final normalizedGroupName = (groupName ?? '').trim();
    if (normalizedGroupName.isEmpty) {
      return false;
    }
    final normalizedName = name.trim().toLowerCase();
    return !normalizedName.startsWith('${normalizedGroupName.toLowerCase()}:');
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
    final currentState = state;
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
      lastFinalizedOrderId: null,
      lastReceiptId: null,
      lastReceipt: null,
      lastPlacedOpenTicketId: null,
    );

    try {
      final result = await _repo.placeOrder(
        SalePlaceOrderCommand(
          saleId: '',
          branchId: branchId,
          saleType: currentState.saleType,
          clientOpId:
              'sale-place-order-local-cart-${DateTime.now().millisecondsSinceEpoch}',
          cartLines: commandLines,
        ),
      );

      await _clearPersistedCart();
      state = SaleCartState(lastPlacedOpenTicketId: result.openTicketId);
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

  List<SaleCartLineInputDto> _buildCommandLines(List<CartLine> lines) {
    final cartPricing = _cartPricingForState(state.copyWith(lines: lines));
    return lines
        .asMap()
        .entries
        .map((entry) {
          final line = entry.value;
          final payload = SaleCartPayloadBuilder.fromLine(
            line,
            pricing: cartPricing.pricingForIndex(entry.key),
            cartPricing: cartPricing,
          );
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
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildOfflineCashReplayItems(
    List<CartLine> lines,
    Map<String, ModifierGroup> groupLookup,
    SaleCartPricing cartPricing,
  ) {
    return lines
        .asMap()
        .entries
        .map((entry) {
          final line = entry.value;
          final payload = SaleCartPayloadBuilder.fromLine(
            line,
            pricing: cartPricing.pricingForIndex(entry.key),
            cartPricing: cartPricing,
          );
          final modifierSelections = payload.modifiers
              .map(
                (entry) => <String, dynamic>{
                  'groupId': entry.groupId,
                  'optionIds': List<String>.from(entry.optionIds)..sort(),
                },
              )
              .toList(growable: false);
          return <String, dynamic>{
            'menuItemId': line.item.id,
            'menuItemNameSnapshot': line.item.name,
            'unitPrice': payload.unitPriceUsd ?? 0,
            'quantity': line.quantity,
            'lineSubtotal': payload.lineTotalUsdExact ?? 0,
            'modifierSnapshot': _modifierSnapshot(line, groupLookup),
            if (modifierSelections.isNotEmpty)
              'modifierSelections': modifierSelections,
            if (payload.pricingSnapshot != null)
              'pricingSnapshot': payload.pricingSnapshot!.toJson(),
          };
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _modifierSnapshot(
    CartLine line,
    Map<String, ModifierGroup> groupLookup,
  ) {
    final snapshot = <Map<String, dynamic>>[];
    final sortedGroupIds = line.selectedOptionIds.keys.toList()..sort();
    for (final groupId in sortedGroupIds) {
      final selectedIds = List<String>.from(
        line.selectedOptionIds[groupId] ?? [],
      )..sort();
      if (selectedIds.isEmpty) continue;

      final selectedOptions =
          line.selectedOptions[groupId] ?? const <ModifierOption>[];
      final selectedById = {
        for (final option in selectedOptions) option.id: option,
      };
      final group = groupLookup[groupId];

      for (final optionId in selectedIds) {
        ModifierOption? option = selectedById[optionId];
        if (option == null && group != null) {
          for (final candidate in group.options) {
            if (candidate.id == optionId) {
              option = candidate;
              break;
            }
          }
        }
        final label = option?.name.trim() ?? '';
        if (label.isEmpty) continue;
        snapshot.add(<String, dynamic>{
          'label': label,
          'priceAdjustmentUsd': option?.priceDelta ?? option?.price ?? 0,
        });
      }
    }
    return snapshot;
  }

  String _normalizeCheckoutSaleType(String saleType) {
    switch (saleType.trim().toLowerCase()) {
      case 'dine_in':
        return 'DINE_IN';
      case 'delivery':
        return 'DELIVERY';
      case 'take_away':
      default:
        return 'TAKEAWAY';
    }
  }
}
