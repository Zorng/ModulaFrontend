import 'dart:convert';
import 'dart:math';

import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';

/// Mock implementation of [SaleCheckoutRepository] for flow-driven development.
///
/// FE-SALE-02 goals:
/// - deterministic behavior for pay-first, KHQR, and pay-later flows
/// - API-shaped reason_code failures
/// - idempotency semantics for mutation commands
///
/// Existing sale screens still use legacy methods (ensureDraft/addItem/preCheckout/finalize).
class MockSaleRepository implements SaleCheckoutRepository {
  MockSaleRepository({
    DateTime Function()? nowFactory,
    bool Function()? cashSessionOpenReader,
  }) : _nowFactory = nowFactory ?? DateTime.now,
       _cashSessionOpenReader = cashSessionOpenReader;

  final DateTime Function() _nowFactory;
  final bool Function()? _cashSessionOpenReader;

  final Map<String, _MockSaleDraft> _drafts = <String, _MockSaleDraft>{};
  final Map<String, _MockFinalizedSale> _finalizedSales =
      <String, _MockFinalizedSale>{};
  final Map<String, _MockFinalizedSale> _voidedSales =
      <String, _MockFinalizedSale>{};
  final Map<String, _MockOpenTicket> _openTicketsById =
      <String, _MockOpenTicket>{};
  final Map<String, String> _openTicketIdBySaleId = <String, String>{};
  final Map<String, _MockManualPaymentClaim> _manualClaimsById =
      <String, _MockManualPaymentClaim>{};
  final Map<String, List<String>> _manualClaimIdsByOrderId =
      <String, List<String>>{};
  final Map<String, _MockKhqrAttempt> _khqrByMd5 = <String, _MockKhqrAttempt>{};
  final Map<String, String> _latestKhqrMd5BySaleId = <String, String>{};
  final Map<String, SaleReceiptDto> _receiptsBySaleId =
      <String, SaleReceiptDto>{};
  final Map<String, String> _cartFingerprintBySaleId = <String, String>{};
  final Map<String, _IdempotencyRecord> _idempotencyRecords =
      <String, _IdempotencyRecord>{};

  int _idCounter = 1;

  String _activeBranchId = 'mock-branch-001';
  bool _branchActive = true;
  bool _branchFrozen = false;
  bool _cashSessionOpen = true;
  bool _payLaterEnabled = true;
  bool _khqrReceiverConfigured = true;
  bool _online = true;
  bool _authorized = true;

  bool get _isCashSessionOpen =>
      _cashSessionOpenReader?.call() ?? _cashSessionOpen;

  /// Test hook to control repository guard behavior.
  void configureContext({
    String? activeBranchId,
    bool? branchActive,
    bool? branchFrozen,
    bool? cashSessionOpen,
    bool? payLaterEnabled,
    bool? khqrReceiverConfigured,
    bool? online,
    bool? authorized,
  }) {
    if (activeBranchId != null && activeBranchId.isNotEmpty) {
      _activeBranchId = activeBranchId;
    }
    if (branchActive != null) _branchActive = branchActive;
    if (branchFrozen != null) _branchFrozen = branchFrozen;
    if (cashSessionOpen != null) _cashSessionOpen = cashSessionOpen;
    if (payLaterEnabled != null) _payLaterEnabled = payLaterEnabled;
    if (khqrReceiverConfigured != null) {
      _khqrReceiverConfigured = khqrReceiverConfigured;
    }
    if (online != null) _online = online;
    if (authorized != null) _authorized = authorized;
  }

  /// Test hook to reset all in-memory state.
  void reset() {
    _drafts.clear();
    _finalizedSales.clear();
    _voidedSales.clear();
    _openTicketsById.clear();
    _openTicketIdBySaleId.clear();
    _manualClaimsById.clear();
    _manualClaimIdsByOrderId.clear();
    _khqrByMd5.clear();
    _latestKhqrMd5BySaleId.clear();
    _receiptsBySaleId.clear();
    _cartFingerprintBySaleId.clear();
    _idempotencyRecords.clear();
    _idCounter = 1;
  }

  @override
  Future<String> ensureDraft({
    String? clientUuid,
    required String saleType,
    double fxRateUsed = 4100,
  }) async {
    final uuid = clientUuid ?? _nextId('sale');
    final saleId = 'mock_sale_$uuid';
    final now = _now();

    _drafts[saleId] = _MockSaleDraft(
      saleId: saleId,
      saleType: saleType,
      fxRateUsed: fxRateUsed,
      items: <_MockSaleItem>[],
      createdAt: now,
      updatedAt: now,
    );

    return saleId;
  }

  @override
  Future<String?> addItem({
    required String saleId,
    required SaleDraftItemInputDto item,
  }) async {
    _ensureWriteAllowed(
      branchId: _activeBranchId,
      requiresPayLaterEnabled: false,
      requiresOnline: false,
      requiresCashSessionOpen: false,
    );

    final draft = _requireDraft(saleId);
    final now = _now();

    final existingIndex = draft.items.indexWhere(
      (draftItem) =>
          draftItem.menuItemId == item.menuItemId &&
          _modifiersMatch(draftItem.modifiers, item.selectedOptionIds),
    );

    if (existingIndex >= 0) {
      final existing = draft.items[existingIndex];
      draft.items[existingIndex] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
        unitPriceUsd: item.unitPriceUsd ?? existing.unitPriceUsd,
        lineTotalUsdExact: item.lineTotalUsdExact ?? existing.lineTotalUsdExact,
      );
      draft.updatedAt = now;
      _syncCartFingerprintFromDraft(saleId);
      _supersedeKhqrAttemptForSale(saleId: saleId, reason: 'cart_changed');
      return existing.id;
    }

    final created = _MockSaleItem(
      id: _nextId('item'),
      menuItemId: item.menuItemId,
      menuItemName: item.menuItemId,
      quantity: item.quantity,
      modifiers: item.modifiers
          .map((entry) => entry.toLegacyJson())
          .toList(growable: false),
      unitPriceUsd: item.unitPriceUsd ?? 1,
      lineTotalUsdExact: item.lineTotalUsdExact ?? (item.unitPriceUsd ?? 1),
    );

    draft.items.add(created);
    draft.updatedAt = now;
    _syncCartFingerprintFromDraft(saleId);
    _supersedeKhqrAttemptForSale(saleId: saleId, reason: 'cart_changed');
    return created.id;
  }

  @override
  Future<void> updateItemQuantity({
    required String saleId,
    required String itemId,
    required int quantity,
  }) async {
    _ensureWriteAllowed(
      branchId: _activeBranchId,
      requiresPayLaterEnabled: false,
      requiresOnline: false,
      requiresCashSessionOpen: false,
    );

    final draft = _requireDraft(saleId);
    final index = draft.items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    if (quantity <= 0) {
      draft.items.removeAt(index);
    } else {
      draft.items[index] = draft.items[index].copyWith(quantity: quantity);
    }

    draft.updatedAt = _now();
    _syncCartFingerprintFromDraft(saleId);
    _supersedeKhqrAttemptForSale(saleId: saleId, reason: 'cart_changed');
  }

  @override
  Future<void> removeItem({
    required String saleId,
    required String itemId,
  }) async {
    _ensureWriteAllowed(
      branchId: _activeBranchId,
      requiresPayLaterEnabled: false,
      requiresOnline: false,
      requiresCashSessionOpen: false,
    );

    final draft = _requireDraft(saleId);
    draft.items.removeWhere((item) => item.id == itemId);
    draft.updatedAt = _now();

    _syncCartFingerprintFromDraft(saleId);
    _supersedeKhqrAttemptForSale(saleId: saleId, reason: 'cart_changed');
  }

  @override
  Future<SaleCheckoutSummary> preCheckout({
    required String saleId,
    required String tenderCurrency,
    required String paymentMethod,
    Map<String, num>? cashReceived,
  }) async {
    final draft = _requireDraft(saleId);
    final totals = _computeTotals(
      fxRateUsed: draft.fxRateUsed,
      items: draft.items,
      tenderCurrency: tenderCurrency,
      cashReceived: cashReceived,
    );

    _cartFingerprintBySaleId[saleId] = _fingerprintFromDraft(draft);

    return SaleCheckoutSummary(
      saleId: saleId,
      tenderCurrency: tenderCurrency.toLowerCase(),
      paymentMethod: paymentMethod,
      totalUsdExact: totals.totalUsdExact,
      totalKhrExact: totals.totalKhrExact,
      cashReceivedUsd: totals.cashReceivedUsd,
      cashReceivedKhr: totals.cashReceivedKhr,
      changeGivenUsd: totals.changeGivenUsd,
      changeGivenKhr: totals.changeGivenKhr,
    );
  }

  @override
  Future<SaleCheckoutSummary> finalize(String saleId) async {
    final result = await finalizeSale(
      SaleFinalizeSaleCommand(
        saleId: saleId,
        paymentMethod: 'cash',
        tenderCurrency: 'USD',
        clientOpId: 'legacy-finalize-$saleId',
      ),
    );

    return SaleCheckoutSummary(
      saleId: result.saleId,
      tenderCurrency: 'usd',
      paymentMethod: 'cash',
      totalUsdExact: result.totalUsdExact,
      totalKhrExact: result.totalKhrExact,
      cashReceivedUsd: 0,
      cashReceivedKhr: 0,
      changeGivenUsd: 0,
      changeGivenKhr: 0,
    );
  }

  @override
  Future<void> updateFulfillmentStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    final finalized = _finalizedSales[orderId];
    if (finalized == null) return;
    finalized.fulfillmentStatus = status;
    finalized.updatedAt = _now();
  }

  @override
  Future<List<Sale>> listSales({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final all = <Sale>[
      ..._drafts.values.map(_toDomainDraft),
      ..._finalizedSales.values.map(_toDomainFinalized),
      ..._voidedSales.values.map(_toDomainFinalized),
    ];

    final lowerStatus = status?.toLowerCase();
    final filtered = all.where((sale) {
      final created = sale.createdAt;
      if (lowerStatus != null && lowerStatus.isNotEmpty) {
        if (sale.state.toLowerCase() != lowerStatus) return false;
      }
      if (startDate != null && created.isBefore(startDate)) return false;
      if (endDate != null && !created.isBefore(endDate)) return false;
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit < 1 ? 1 : limit;
    final from = (safePage - 1) * safeLimit;
    if (from >= filtered.length) return <Sale>[];
    final to = min(filtered.length, from + safeLimit);
    return filtered.sublist(from, to);
  }

  @override
  Future<SaleDetailReadDto> getSaleDetail({required String saleId}) async {
    final normalizedSaleId = saleId.trim();
    final finalized =
        _finalizedSales[normalizedSaleId] ?? _voidedSales[normalizedSaleId];
    if (finalized == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Sale not found.',
      );
    }

    return SaleDetailReadDto(
      saleId: finalized.saleId,
      orderId: null,
      status: finalized.state.trim().toUpperCase(),
      saleType: finalized.saleType.trim().isEmpty
          ? 'TAKEAWAY'
          : finalized.saleType.trim().toUpperCase(),
      paymentMethod: finalized.paymentMethod.trim().isEmpty
          ? 'CASH'
          : finalized.paymentMethod.trim().toUpperCase(),
      tenderCurrency: finalized.tenderCurrency.trim().isEmpty
          ? 'USD'
          : finalized.tenderCurrency.trim().toUpperCase(),
      fulfillmentStatus: finalized.fulfillmentStatus.trim().isEmpty
          ? 'PENDING'
          : finalized.fulfillmentStatus.trim().toUpperCase(),
      subtotalUsdExact: finalized.subtotalUsdExact,
      subtotalKhrExact: finalized.subtotalKhrExact,
      discountUsdExact: 0,
      discountKhrExact: 0,
      taxUsdExact: 0,
      taxKhrExact: 0,
      totalUsdExact: finalized.totalUsdExact,
      totalKhrExact: finalized.totalKhrExact,
      cashReceivedUsd: finalized.cashReceivedUsd,
      cashReceivedKhr: finalized.cashReceivedKhr,
      changeGivenUsd: finalized.changeGivenUsd,
      changeGivenKhr: finalized.changeGivenKhr,
      createdAt: finalized.createdAt,
      updatedAt: finalized.updatedAt,
      finalizedAt: finalized.state.trim().toUpperCase() == 'FINALIZED'
          ? finalized.updatedAt
          : null,
      voidedAt: finalized.state.trim().toUpperCase() == 'VOIDED'
          ? finalized.updatedAt
          : null,
      voidReason: null,
      lines: finalized.items
          .map(
            (item) => SaleDetailLineDto(
              lineId: item.id,
              menuItemId: item.menuItemId,
              menuItemName: item.menuItemId,
              quantity: item.quantity,
              modifierLabels: _modifierLabels(item.modifiers),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<SaleVoidRequestReadDto?> getSaleVoidRequest({
    required String saleId,
  }) async {
    return null;
  }

  @override
  Future<void> voidSale(String saleId, {required String reason}) async {
    final draft = _drafts.remove(saleId);
    if (draft != null) {
      _voidedSales[saleId] = _MockFinalizedSale(
        saleId: saleId,
        saleType: draft.saleType,
        paymentMethod: 'cash',
        tenderCurrency: 'usd',
        subtotalUsdExact: _subtotalUsd(draft.items),
        subtotalKhrExact: _subtotalUsd(draft.items) * draft.fxRateUsed,
        totalUsdExact: _subtotalUsd(draft.items),
        totalKhrExact: _subtotalUsd(draft.items) * draft.fxRateUsed,
        cashReceivedUsd: 0,
        cashReceivedKhr: 0,
        changeGivenUsd: 0,
        changeGivenKhr: 0,
        fulfillmentStatus: 'cancelled',
        state: 'voided',
        items: draft.items,
        createdAt: draft.createdAt,
        updatedAt: _now(),
      );
      return;
    }

    final finalized = _finalizedSales.remove(saleId);
    if (finalized != null) {
      finalized.state = 'voided';
      finalized.fulfillmentStatus = 'cancelled';
      finalized.updatedAt = _now();
      _voidedSales[saleId] = finalized;
    }
  }

  @override
  Future<SaleContextDto> getSaleContext({required String branchId}) async {
    final reason = _resolveBlockingReason(
      branchId: branchId,
      requiresPayLaterEnabled: false,
      requiresOnline: false,
    );

    return SaleContextDto(
      branchId: branchId,
      branchActive: _branchActive,
      branchFrozen: _branchFrozen,
      cashSessionOpen: _isCashSessionOpen,
      canMutateCart:
          reason == null ||
          reason.code == SaleCheckoutReasonCodes.cashSessionRequired,
      canCheckout: reason == null,
      canPlacePayLater:
          reason == null && _payLaterEnabled && _online && _branchActive,
      reasonCode: reason?.code,
      reasonMessage: reason?.message,
    );
  }

  @override
  Future<SaleCheckoutPreviewDto> computeCheckoutPreview(
    SaleComputeCheckoutPreviewCommand command,
  ) async {
    _ensureReadAllowed(branchId: _activeBranchId);

    final items = command.cartLines.isNotEmpty
        ? command.cartLines.map(_lineFromCommand).toList()
        : _requireDraft(command.saleId).items;

    if (items.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Cannot compute checkout preview for an empty cart.',
      );
    }

    final draft = _drafts[command.saleId];
    final fx = draft?.fxRateUsed ?? 4100;
    final cashReceived = command.cashReceived?.toJson().cast<String, num>();
    final totals = _computeTotals(
      fxRateUsed: fx,
      items: items,
      tenderCurrency: command.tenderCurrency,
      cashReceived: cashReceived,
    );

    final fingerprint = _stableStringify(
      command.cartLines.map((e) => e.toJson()).toList(),
    );
    final previous = _cartFingerprintBySaleId[command.saleId];
    if (previous != null && previous != fingerprint) {
      _supersedeKhqrAttemptForSale(
        saleId: command.saleId,
        reason: 'cart_changed',
      );
    }
    _cartFingerprintBySaleId[command.saleId] = fingerprint;

    return SaleCheckoutPreviewDto(
      saleId: command.saleId,
      tenderCurrency: command.tenderCurrency.toLowerCase(),
      paymentMethod: command.paymentMethod,
      subtotalUsdExact: totals.subtotalUsdExact,
      subtotalKhrExact: totals.subtotalKhrExact,
      totalUsdExact: totals.totalUsdExact,
      totalKhrExact: totals.totalKhrExact,
      cashReceivedUsd: totals.cashReceivedUsd,
      cashReceivedKhr: totals.cashReceivedKhr,
      changeGivenUsd: totals.changeGivenUsd,
      changeGivenKhr: totals.changeGivenKhr,
    );
  }

  @override
  Future<SaleKhqrAttemptDto> generateKhqrAttempt(
    SaleGenerateKhqrAttemptCommand command,
  ) async {
    _ensureWriteAllowed(
      branchId: _activeBranchId,
      requiresPayLaterEnabled: false,
      requiresOnline: false,
    );

    return _runIdempotent(
      action: 'khqr.generate',
      key: command.clientOpId,
      payload: command.toJson(),
      onReplay: (existing) => existing,
      execute: () async {
        final saleId = _ensurePayNowDraftForCheckout(
          saleId: command.saleId,
          saleType: command.saleType ?? 'take_away',
          cartLines: command.cartLines,
        );
        if (!_khqrReceiverConfigured) {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.khqrBranchReceiverNotConfigured,
            message:
                'Configure a Bakong receiver account for this branch before generating KHQR.',
          );
        }
        _supersedeKhqrAttemptForSale(
          saleId: saleId,
          reason: 'new_attempt_generated',
        );

        final amount = _resolveCurrentPayable(
          saleId: saleId,
          tenderCurrency: command.tenderCurrency,
        );

        final now = _now();
        final attempt = _MockKhqrAttempt(
          saleId: saleId,
          attemptId: _nextId('khqr_attempt'),
          md5: _nextId('khqr_md5'),
          status: 'WAITING_FOR_PAYMENT',
          amount: amount,
          currency: command.tenderCurrency.toUpperCase(),
          createdAt: now,
          expiresAt: now.add(const Duration(minutes: 2)),
          pollCount: 0,
          reasonCode: null,
          reasonMessage: null,
        );

        _khqrByMd5[attempt.md5] = attempt;
        _latestKhqrMd5BySaleId[saleId] = attempt.md5;

        return SaleKhqrAttemptDto(
          saleId: '',
          attemptId: attempt.attemptId,
          md5: attempt.md5,
          status: attempt.status,
          amount: attempt.amount,
          currency: attempt.currency,
          expiresAt: attempt.expiresAt,
          qrPayload: 'KHQR:${attempt.md5}',
          payloadType: 'EMV_KHQR_STRING',
          deepLinkUrl: null,
          toAccountId: 'mock-bakong-account',
          receiverName: 'Mock KHQR Receiver',
          reasonCode: attempt.reasonCode,
          reasonMessage: attempt.reasonMessage,
        );
      },
    );
  }

  @override
  Future<SaleKhqrStatusDto> checkKhqrStatus(
    SaleCheckKhqrStatusCommand command,
  ) async {
    final attempt = _khqrByMd5[command.md5];
    if (attempt == null ||
        !_khqrAttemptMatchesCommandSaleId(command.saleId, attempt)) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'KHQR attempt was not found for this sale.',
      );
    }

    final now = _now();

    if (attempt.status == 'SUPERSEDED' || attempt.status == 'PAID_CONFIRMED') {
      return SaleKhqrStatusDto(
        saleId: attempt.status == 'PAID_CONFIRMED' ? attempt.saleId : '',
        md5: attempt.md5,
        status: attempt.status,
        confirmedAt: attempt.confirmedAt,
        reasonCode: attempt.reasonCode,
        reasonMessage: attempt.reasonMessage,
      );
    }

    if (attempt.expiresAt.isBefore(now)) {
      attempt.status = 'EXPIRED';
      attempt.reasonCode = null;
      attempt.reasonMessage = null;
      return SaleKhqrStatusDto(
        saleId: '',
        md5: attempt.md5,
        status: attempt.status,
      );
    }

    attempt.pollCount += 1;

    if (!_online && attempt.pollCount >= 1) {
      attempt.status = 'PENDING_CONFIRMATION';
      return SaleKhqrStatusDto(
        saleId: '',
        md5: attempt.md5,
        status: attempt.status,
      );
    }

    if (attempt.pollCount >= 2) {
      attempt.status = 'PAID_CONFIRMED';
      attempt.confirmedAt = now;
      return SaleKhqrStatusDto(
        saleId: attempt.saleId,
        md5: attempt.md5,
        status: attempt.status,
        confirmedAt: attempt.confirmedAt,
      );
    }

    attempt.status = 'WAITING_FOR_PAYMENT';
    return SaleKhqrStatusDto(
      saleId: '',
      md5: attempt.md5,
      status: attempt.status,
    );
  }

  @override
  Future<SaleKhqrStatusDto> cancelKhqrAttempt(
    SaleCancelKhqrAttemptCommand command,
  ) async {
    final attempt = _khqrByMd5[command.md5];
    if (attempt == null ||
        !_khqrAttemptMatchesCommandSaleId(command.saleId, attempt)) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'KHQR attempt was not found for this sale.',
      );
    }

    return _runIdempotent(
      action: 'khqr.cancel',
      key: command.clientOpId,
      payload: command.toJson(),
      onReplay: (existing) => existing,
      execute: () async {
        if (attempt.status == 'WAITING_FOR_PAYMENT' ||
            attempt.status == 'PENDING_CONFIRMATION') {
          attempt.status = 'CANCELLED';
          attempt.reasonCode = null;
          attempt.reasonMessage = null;
        }

        return SaleKhqrStatusDto(
          saleId: '',
          md5: attempt.md5,
          status: attempt.status,
          confirmedAt: attempt.confirmedAt,
          reasonCode: attempt.reasonCode,
          reasonMessage: attempt.reasonMessage,
        );
      },
    );
  }

  @override
  Future<SaleFinalizeSaleResultDto> finalizeSale(
    SaleFinalizeSaleCommand command,
  ) async {
    _ensureWriteAllowed(
      branchId: _activeBranchId,
      requiresPayLaterEnabled: false,
      requiresOnline: false,
    );

    return _runIdempotent(
      action: 'sale.finalize',
      key: command.clientOpId,
      payload: command.toJson(),
      onReplay: (existing) => existing.copyWith(idempotentReplay: true),
      execute: () async {
        final saleId = _ensurePayNowDraftForCheckout(
          saleId: command.saleId,
          saleType: command.saleType ?? 'take_away',
          cartLines: command.cartLines,
        );
        final draft = _requireDraft(saleId);
        if (draft.items.isEmpty) {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.invalidRequest,
            message: 'Cannot finalize an empty cart.',
          );
        }

        if (command.paymentMethod.toLowerCase() == 'khqr') {
          _ensureKhqrConfirmed(saleId: saleId, md5: command.khqrMd5);
        }

        final cashReceived = command.cashReceived?.toJson().cast<String, num>();
        final totals = _computeTotals(
          fxRateUsed: draft.fxRateUsed,
          items: draft.items,
          tenderCurrency: command.tenderCurrency,
          cashReceived: cashReceived,
        );

        final now = _now();
        final finalized = _MockFinalizedSale(
          saleId: saleId,
          saleType: draft.saleType,
          paymentMethod: command.paymentMethod,
          tenderCurrency: command.tenderCurrency.toLowerCase(),
          subtotalUsdExact: totals.subtotalUsdExact,
          subtotalKhrExact: totals.subtotalKhrExact,
          totalUsdExact: totals.totalUsdExact,
          totalKhrExact: totals.totalKhrExact,
          cashReceivedUsd: totals.cashReceivedUsd,
          cashReceivedKhr: totals.cashReceivedKhr,
          changeGivenUsd: totals.changeGivenUsd,
          changeGivenKhr: totals.changeGivenKhr,
          fulfillmentStatus: 'in_prep',
          state: 'finalized',
          items: List<_MockSaleItem>.from(draft.items),
          createdAt: draft.createdAt,
          updatedAt: now,
        );

        _drafts.remove(saleId);
        _finalizedSales[saleId] = finalized;

        final ticketId = _openTicketIdBySaleId[saleId];
        if (ticketId != null) {
          final ticket = _openTicketsById[ticketId];
          if (ticket != null && ticket.status == 'UNPAID') {
            ticket.status = 'PAID';
            ticket.updatedAt = now;
          }
        }

        final receiptId = _nextId('receipt');
        _receiptsBySaleId[saleId] = _buildReceipt(
          saleId: saleId,
          receiptId: receiptId,
          paymentMethod: command.paymentMethod,
          subtotalUsdExact: totals.subtotalUsdExact,
          totalUsdExact: totals.totalUsdExact,
          totalKhrExact: totals.totalKhrExact,
          items: draft.items,
          issuedAt: now,
        );

        return SaleFinalizeSaleResultDto(
          saleId: saleId,
          status: 'FINALIZED',
          totalUsdExact: totals.totalUsdExact,
          totalKhrExact: totals.totalKhrExact,
          idempotentReplay: false,
          orderId: command.saleId,
          receiptId: receiptId,
          receipt: SaleImmediateReceiptDto(
            receiptId: receiptId,
            saleId: saleId,
            statusDisplay: 'NORMAL',
            issuedAt: now,
          ),
        );
      },
    );
  }

  @override
  Future<SalePlaceOrderResultDto> placeOrder(
    SalePlaceOrderCommand command,
  ) async {
    final isManualClaimOrder =
        (command.sourceMode ?? '').trim().toUpperCase() ==
        'MANUAL_EXTERNAL_PAYMENT_CLAIM';
    _ensureWriteAllowed(
      branchId: command.branchId,
      requiresPayLaterEnabled: !isManualClaimOrder,
      requiresOnline: true,
    );

    return _runIdempotent(
      action: 'ticket.place',
      key: command.clientOpId,
      payload: command.toJson(),
      onReplay: (existing) => existing.copyWith(idempotentReplay: true),
      execute: () async {
        if (command.cartLines.isEmpty) {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.invalidRequest,
            message: 'Cannot place an open ticket with an empty cart.',
          );
        }

        final now = _now();
        final draft = _MockSaleDraft(
          saleId: command.saleId,
          saleType: command.saleType,
          fxRateUsed: 4100,
          items: command.cartLines.map(_lineFromCommand).toList(),
          createdAt: now,
          updatedAt: now,
        );
        _drafts[command.saleId] = draft;

        final batchId = _nextId('batch');
        final batch = _batchFromCartLines(
          batchId: batchId,
          cartLines: command.cartLines,
          createdAt: now,
        );

        final totals = _computeTotals(
          fxRateUsed: draft.fxRateUsed,
          items: batch.items,
          tenderCurrency: 'USD',
          cashReceived: null,
        );

        final openTicketId = _nextId('open_ticket');
        final ticket = _MockOpenTicket(
          openTicketId: openTicketId,
          saleId: command.saleId,
          status: 'UNPAID',
          batches: <_MockOpenTicketBatch>[batch],
          payableUsdExact: totals.totalUsdExact,
          payableKhrExact: totals.totalKhrExact,
          createdAt: now,
          updatedAt: now,
        );

        _openTicketsById[openTicketId] = ticket;
        _openTicketIdBySaleId[command.saleId] = openTicketId;

        return SalePlaceOrderResultDto(
          openTicketId: openTicketId,
          saleId: command.saleId,
          status: ticket.status,
          batchId: batchId,
          idempotentReplay: false,
        );
      },
    );
  }

  @override
  Future<String> uploadManualPaymentProofImage({
    required List<int> imageBytes,
  }) async {
    _ensureWriteAllowed(
      branchId: _activeBranchId,
      requiresPayLaterEnabled: false,
      requiresOnline: true,
    );
    if (imageBytes.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Proof image is required before creating a manual claim.',
      );
    }
    return 'https://example.com/payment-proof/${_nextId('proof')}.jpg';
  }

  @override
  Future<SaleCreateManualPaymentClaimResultDto> createManualPaymentClaim(
    SaleCreateManualPaymentClaimCommand command,
  ) async {
    _ensureWriteAllowed(
      branchId: _activeBranchId,
      requiresPayLaterEnabled: false,
      requiresOnline: true,
    );

    return _runIdempotent(
      action: 'ticket.manual_claim.create',
      key: command.clientOpId,
      payload: command.toJson(),
      onReplay: (existing) => existing.copyWith(idempotentReplay: true),
      execute: () async {
        final orderId = command.orderId.trim();
        final ticket = _openTicketsById[orderId];
        if (ticket == null || ticket.status != 'UNPAID') {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.invalidRequest,
            message: 'Open order is not available for manual payment claim.',
          );
        }
        if (command.proofImageUrl.trim().isEmpty) {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.invalidRequest,
            message: 'Proof image is required before creating a manual claim.',
          );
        }

        final existingPendingIds =
            _manualClaimIdsByOrderId[orderId] ?? const <String>[];
        for (final existingClaimId in existingPendingIds) {
          final existingClaim = _manualClaimsById[existingClaimId];
          if (existingClaim?.status == 'PENDING_REVIEW') {
            throw const SaleCheckoutRepositoryException(
              reasonCode: SaleCheckoutReasonCodes.invalidRequest,
              message: 'This order already has a pending manual payment claim.',
            );
          }
        }

        final claimId = _nextId('manual_claim');
        _manualClaimsById[claimId] = _MockManualPaymentClaim(
          claimId: claimId,
          orderId: orderId,
          claimedPaymentMethod: command.claimedPaymentMethod
              .trim()
              .toUpperCase(),
          saleType: command.saleType,
          tenderCurrency: command.tenderCurrency.trim().toUpperCase(),
          claimedTenderAmount: command.claimedTenderAmount,
          proofImageUrl: command.proofImageUrl.trim(),
          customerReference: command.customerReference?.trim(),
          note: command.note?.trim(),
          status: 'PENDING_REVIEW',
          createdAt: _now(),
        );
        _manualClaimIdsByOrderId
            .putIfAbsent(orderId, () => <String>[])
            .add(claimId);

        return SaleCreateManualPaymentClaimResultDto(
          claimId: claimId,
          orderId: orderId,
          status: 'PENDING_REVIEW',
          idempotentReplay: false,
        );
      },
    );
  }

  @override
  Future<SaleApproveManualPaymentClaimResultDto> approveManualPaymentClaim(
    SaleApproveManualPaymentClaimCommand command,
  ) async {
    _ensureWriteAllowed(
      branchId: _activeBranchId,
      requiresPayLaterEnabled: false,
      requiresOnline: true,
    );

    return _runIdempotent(
      action: 'ticket.manual_claim.approve',
      key: command.clientOpId,
      payload: command.toJson(),
      onReplay: (existing) => existing.copyWith(idempotentReplay: true),
      execute: () async {
        final claim = _manualClaimsById[command.claimId];
        final ticket = _openTicketsById[command.orderId];
        if (claim == null ||
            ticket == null ||
            claim.orderId != ticket.openTicketId ||
            claim.status != 'PENDING_REVIEW') {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.invalidRequest,
            message: 'Manual payment claim is not pending review anymore.',
          );
        }

        final allItems = ticket.batches.expand((batch) => batch.items).toList();
        final totals = _computeTotals(
          fxRateUsed: 4100,
          items: allItems,
          tenderCurrency: claim.tenderCurrency,
          cashReceived: null,
        );
        final now = _now();

        _finalizedSales[ticket.saleId] = _MockFinalizedSale(
          saleId: ticket.saleId,
          saleType: claim.saleType,
          paymentMethod: claim.claimedPaymentMethod.toLowerCase(),
          tenderCurrency: claim.tenderCurrency.toLowerCase(),
          subtotalUsdExact: totals.subtotalUsdExact,
          subtotalKhrExact: totals.subtotalKhrExact,
          totalUsdExact: totals.totalUsdExact,
          totalKhrExact: totals.totalKhrExact,
          cashReceivedUsd: 0,
          cashReceivedKhr: 0,
          changeGivenUsd: 0,
          changeGivenKhr: 0,
          fulfillmentStatus: 'in_prep',
          state: 'finalized',
          items: allItems,
          createdAt: now,
          updatedAt: now,
        );

        ticket.status = 'CHECKED_OUT';
        ticket.updatedAt = now;
        claim.status = 'APPROVED';
        claim.reviewedAt = now;
        claim.reviewNote = command.note?.trim();
        claim.saleId = ticket.saleId;

        final receiptId = _nextId('receipt');
        final receipt = _buildReceipt(
          saleId: ticket.saleId,
          receiptId: receiptId,
          paymentMethod: claim.claimedPaymentMethod.toLowerCase(),
          subtotalUsdExact: totals.subtotalUsdExact,
          totalUsdExact: totals.totalUsdExact,
          totalKhrExact: totals.totalKhrExact,
          items: allItems,
          issuedAt: now,
        );
        _receiptsBySaleId[ticket.saleId] = receipt;
        _drafts.remove(ticket.saleId);

        return SaleApproveManualPaymentClaimResultDto(
          claimId: claim.claimId,
          orderId: ticket.openTicketId,
          status: claim.status,
          idempotentReplay: false,
          saleId: ticket.saleId,
          receiptId: receipt.receiptNumber,
          receipt: SaleImmediateReceiptDto(
            receiptId: receipt.receiptNumber,
            saleId: receipt.saleId,
            statusDisplay: 'NORMAL',
            issuedAt: receipt.issuedAt,
          ),
        );
      },
    );
  }

  @override
  Future<SaleRejectManualPaymentClaimResultDto> rejectManualPaymentClaim(
    SaleRejectManualPaymentClaimCommand command,
  ) async {
    _ensureWriteAllowed(
      branchId: _activeBranchId,
      requiresPayLaterEnabled: false,
      requiresOnline: true,
    );

    return _runIdempotent(
      action: 'ticket.manual_claim.reject',
      key: command.clientOpId,
      payload: command.toJson(),
      onReplay: (existing) => existing.copyWith(idempotentReplay: true),
      execute: () async {
        final claim = _manualClaimsById[command.claimId];
        final ticket = _openTicketsById[command.orderId];
        if (claim == null ||
            ticket == null ||
            claim.orderId != ticket.openTicketId ||
            claim.status != 'PENDING_REVIEW') {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.invalidRequest,
            message: 'Manual payment claim is not pending review anymore.',
          );
        }

        final now = _now();
        claim.status = 'REJECTED';
        claim.reviewedAt = now;
        claim.reviewNote = command.note?.trim();
        ticket.updatedAt = now;

        return SaleRejectManualPaymentClaimResultDto(
          claimId: claim.claimId,
          orderId: ticket.openTicketId,
          status: claim.status,
          idempotentReplay: false,
        );
      },
    );
  }

  @override
  Future<SaleAddItemsToOpenTicketResultDto> addItemsToOpenTicket(
    SaleAddItemsToOpenTicketCommand command,
  ) async {
    _ensureWriteAllowed(
      branchId: _activeBranchId,
      requiresPayLaterEnabled: true,
      requiresOnline: true,
    );

    return _runIdempotent(
      action: 'ticket.add_items',
      key: command.clientOpId,
      payload: command.toJson(),
      onReplay: (existing) => existing.copyWith(idempotentReplay: true),
      execute: () async {
        final ticket = _openTicketsById[command.openTicketId];
        if (ticket == null || ticket.status != 'UNPAID') {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.invalidRequest,
            message: 'Open ticket is not available for add-items.',
          );
        }
        if (command.cartLines.isEmpty) {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.invalidRequest,
            message: 'Add-items requires at least one cart line.',
          );
        }

        final batchId = _nextId('batch');
        final now = _now();
        final batch = _batchFromCartLines(
          batchId: batchId,
          cartLines: command.cartLines,
          createdAt: now,
        );

        ticket.batches.add(batch);
        ticket.updatedAt = now;

        final allItems = ticket.batches.expand((b) => b.items).toList();
        final totals = _computeTotals(
          fxRateUsed: 4100,
          items: allItems,
          tenderCurrency: 'USD',
          cashReceived: null,
        );
        ticket.payableUsdExact = totals.totalUsdExact;
        ticket.payableKhrExact = totals.totalKhrExact;

        _supersedeKhqrAttemptForSale(
          saleId: ticket.saleId,
          reason: 'ticket_changed',
        );

        final draft = _drafts[ticket.saleId];
        if (draft != null) {
          draft.items
            ..clear()
            ..addAll(allItems);
          draft.updatedAt = now;
          _syncCartFingerprintFromDraft(ticket.saleId);
        }

        return SaleAddItemsToOpenTicketResultDto(
          openTicketId: ticket.openTicketId,
          batchId: batchId,
          idempotentReplay: false,
        );
      },
    );
  }

  @override
  Future<SaleCheckoutOpenTicketResultDto> checkoutOpenTicket(
    SaleCheckoutOpenTicketCommand command,
  ) async {
    _ensureWriteAllowed(
      branchId: _activeBranchId,
      requiresPayLaterEnabled: false,
      requiresOnline: false,
    );

    return _runIdempotent(
      action: 'ticket.checkout',
      key: command.clientOpId,
      payload: command.toJson(),
      onReplay: (existing) => existing.copyWith(idempotentReplay: true),
      execute: () async {
        final ticket = _openTicketsById[command.openTicketId];
        if (ticket == null || ticket.status != 'UNPAID') {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.invalidRequest,
            message: 'Open ticket is not payable in its current state.',
          );
        }

        if (command.paymentMethod.toLowerCase() == 'khqr') {
          _ensureKhqrConfirmed(saleId: ticket.saleId, md5: command.khqrMd5);
        }

        final allItems = ticket.batches.expand((batch) => batch.items).toList();
        final cashReceived = command.cashReceived?.toJson().cast<String, num>();
        final totals = _computeTotals(
          fxRateUsed: 4100,
          items: allItems,
          tenderCurrency: command.tenderCurrency,
          cashReceived: cashReceived,
        );

        final now = _now();
        _finalizedSales[ticket.saleId] = _MockFinalizedSale(
          saleId: ticket.saleId,
          saleType: 'take_away',
          paymentMethod: command.paymentMethod,
          tenderCurrency: command.tenderCurrency.toLowerCase(),
          subtotalUsdExact: totals.subtotalUsdExact,
          subtotalKhrExact: totals.subtotalKhrExact,
          totalUsdExact: totals.totalUsdExact,
          totalKhrExact: totals.totalKhrExact,
          cashReceivedUsd: totals.cashReceivedUsd,
          cashReceivedKhr: totals.cashReceivedKhr,
          changeGivenUsd: totals.changeGivenUsd,
          changeGivenKhr: totals.changeGivenKhr,
          fulfillmentStatus: 'in_prep',
          state: 'finalized',
          items: allItems,
          createdAt: ticket.createdAt,
          updatedAt: now,
        );

        ticket.status = 'PAID';
        ticket.updatedAt = now;

        final receiptId = _nextId('receipt');
        _receiptsBySaleId[ticket.saleId] = _buildReceipt(
          saleId: ticket.saleId,
          receiptId: receiptId,
          paymentMethod: command.paymentMethod,
          subtotalUsdExact: totals.subtotalUsdExact,
          totalUsdExact: totals.totalUsdExact,
          totalKhrExact: totals.totalKhrExact,
          items: allItems,
          issuedAt: now,
        );

        _drafts.remove(ticket.saleId);

        return SaleCheckoutOpenTicketResultDto(
          openTicketId: ticket.openTicketId,
          saleId: ticket.saleId,
          status: ticket.status,
          idempotentReplay: false,
          receiptId: receiptId,
        );
      },
    );
  }

  @override
  Future<SaleCancelOpenTicketResultDto> cancelOpenTicket(
    SaleCancelOpenTicketCommand command,
  ) async {
    _ensureWriteAllowed(
      branchId: _activeBranchId,
      requiresPayLaterEnabled: false,
      requiresOnline: false,
    );

    return _runIdempotent(
      action: 'ticket.cancel',
      key: command.clientOpId,
      payload: command.toJson(),
      onReplay: (existing) => existing.copyWith(idempotentReplay: true),
      execute: () async {
        final ticket = _openTicketsById[command.openTicketId];
        if (ticket == null || ticket.status != 'UNPAID') {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.invalidRequest,
            message: 'Open ticket is not cancellable in its current state.',
          );
        }
        if (command.reason.trim().isEmpty) {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.invalidRequest,
            message: 'Cancellation reason is required.',
          );
        }

        final now = _now();
        ticket.status = 'CANCELLED';
        ticket.updatedAt = now;
        ticket.cancelledAt = now;

        _drafts.remove(ticket.saleId);

        return SaleCancelOpenTicketResultDto(
          openTicketId: ticket.openTicketId,
          status: ticket.status,
          idempotentReplay: false,
          cancelledAt: now,
        );
      },
    );
  }

  @override
  Future<SaleOrdersPageDto> getOrders(SaleOrdersQueryDto query) async {
    final items = <SaleOrderSummaryDto>[];

    for (final ticket in _openTicketsById.values) {
      items.add(
        SaleOrderSummaryDto(
          saleId: ticket.saleId,
          orderId: ticket.openTicketId,
          sourceMode: 'STANDARD',
          openedByAccountId: 'mock-account-1',
          ticketStatus: ticket.status,
          fulfillmentStatus: ticket.status == 'PAID' ? 'in_prep' : 'pending',
          totalUsdExact: ticket.payableUsdExact,
          totalKhrExact: ticket.payableKhrExact,
          placedAt: ticket.createdAt,
        ),
      );
    }

    for (final finalized in _finalizedSales.values) {
      items.add(
        SaleOrderSummaryDto(
          saleId: finalized.saleId,
          orderId: finalized.saleId,
          sourceMode: 'DIRECT_CHECKOUT',
          openedByAccountId: 'mock-account-1',
          ticketStatus: 'PAID',
          fulfillmentStatus: finalized.fulfillmentStatus,
          totalUsdExact: finalized.totalUsdExact,
          totalKhrExact: finalized.totalKhrExact,
          placedAt: finalized.createdAt,
        ),
      );
    }

    final filtered = items.where((order) {
      final lowerStatus = query.status?.toLowerCase();
      if (lowerStatus != null && lowerStatus.isNotEmpty) {
        switch (lowerStatus) {
          case 'open':
          case 'pending':
            if (order.ticketStatus.toLowerCase() != 'unpaid') {
              return false;
            }
            break;
          default:
            if (order.ticketStatus.toLowerCase() != lowerStatus &&
                order.fulfillmentStatus.toLowerCase() != lowerStatus) {
              return false;
            }
            break;
        }
      }
      final lowerView = query.view?.toLowerCase();
      if (lowerView == 'fulfillment_active') {
        if (order.ticketStatus.toLowerCase() == 'cancelled') return false;
        final fulfillmentStatus = order.fulfillmentStatus.toLowerCase();
        if (fulfillmentStatus == 'delivered' ||
            fulfillmentStatus == 'cancelled') {
          return false;
        }
      }
      if (query.from != null && order.placedAt.isBefore(query.from!)) {
        return false;
      }
      if (query.to != null && !order.placedAt.isBefore(query.to!)) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    final safePage = query.page < 1 ? 1 : query.page;
    final safeLimit = query.limit < 1 ? 1 : query.limit;
    final from = (safePage - 1) * safeLimit;
    final paged = from >= filtered.length
        ? <SaleOrderSummaryDto>[]
        : filtered.sublist(from, min(filtered.length, from + safeLimit));

    return SaleOrdersPageDto(
      items: paged,
      page: safePage,
      limit: safeLimit,
      total: filtered.length,
    );
  }

  @override
  Future<SaleOpenTicketDetailDto> getOpenTicketDetail({
    required String orderId,
  }) async {
    final normalizedOrderId = orderId.trim();
    final ticket = normalizedOrderId.isEmpty
        ? null
        : _openTicketsById[normalizedOrderId];
    if (ticket == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Open ticket not found for this order.',
      );
    }

    return SaleOpenTicketDetailDto(
      openTicketId: ticket.openTicketId,
      orderId: ticket.openTicketId,
      status: ticket.status,
      batches: ticket.batches
          .map(
            (batch) => SaleOpenTicketBatchDto(
              batchId: batch.batchId,
              createdAt: batch.createdAt,
              totalUsdExact: batch.totalUsdExact,
              totalKhrExact: batch.totalKhrExact,
            ),
          )
          .toList(),
      lineCount: ticket.batches.fold<int>(
        0,
        (sum, batch) => sum + batch.items.length,
      ),
      payableUsdExact: ticket.payableUsdExact,
      payableKhrExact: ticket.payableKhrExact,
    );
  }

  @override
  Future<SaleReceiptDto> getReceipt({required String saleId}) async {
    final receipt = _receiptsBySaleId[saleId];
    if (receipt == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Receipt is not available for this sale.',
      );
    }
    return receipt;
  }

  Future<T> _runIdempotent<T extends Object>({
    required String action,
    required String key,
    required Object payload,
    required T Function(T existing) onReplay,
    required Future<T> Function() execute,
  }) async {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Idempotency key is required.',
      );
    }

    final id = '$action|$normalizedKey';
    final payloadHash = _stableStringify(payload);
    final existing = _idempotencyRecords[id];

    if (existing != null) {
      if (existing.payloadHash != payloadHash) {
        throw const SaleCheckoutRepositoryException(
          reasonCode: SaleCheckoutReasonCodes.idempotencyConflict,
          message: 'Same idempotency key was used with a different payload.',
        );
      }
      return onReplay(existing.response as T);
    }

    final created = await execute();
    _idempotencyRecords[id] = _IdempotencyRecord(
      payloadHash: payloadHash,
      response: created,
    );
    return created;
  }

  Sale _toDomainDraft(_MockSaleDraft draft) {
    return Sale(
      id: draft.saleId,
      saleType: draft.saleType,
      state: 'draft',
      fulfillmentStatus: 'in_prep',
      paymentMethod: 'cash',
      tenderCurrency: 'usd',
      fxRateUsed: draft.fxRateUsed,
      subtotalUsdExact: _subtotalUsd(draft.items),
      subtotalKhrExact: _subtotalUsd(draft.items) * draft.fxRateUsed,
      discountUsdExact: 0,
      discountKhrExact: 0,
      taxUsdExact: 0,
      taxKhrExact: 0,
      totalUsdExact: _subtotalUsd(draft.items),
      totalKhrExact: _subtotalUsd(draft.items) * draft.fxRateUsed,
      cashReceivedUsd: 0,
      cashReceivedKhr: 0,
      changeGivenUsd: 0,
      changeGivenKhr: 0,
      createdAt: draft.createdAt,
      updatedAt: draft.updatedAt,
      items: draft.items.map(_toDomainItem).toList(),
    );
  }

  Sale _toDomainFinalized(_MockFinalizedSale sale) {
    return Sale(
      id: sale.saleId,
      saleType: sale.saleType,
      state: sale.state,
      fulfillmentStatus: sale.fulfillmentStatus,
      paymentMethod: sale.paymentMethod,
      tenderCurrency: sale.tenderCurrency,
      fxRateUsed: 4100,
      subtotalUsdExact: sale.subtotalUsdExact,
      subtotalKhrExact: sale.subtotalKhrExact,
      discountUsdExact: 0,
      discountKhrExact: 0,
      taxUsdExact: 0,
      taxKhrExact: 0,
      totalUsdExact: sale.totalUsdExact,
      totalKhrExact: sale.totalKhrExact,
      cashReceivedUsd: sale.cashReceivedUsd,
      cashReceivedKhr: sale.cashReceivedKhr,
      changeGivenUsd: sale.changeGivenUsd,
      changeGivenKhr: sale.changeGivenKhr,
      createdAt: sale.createdAt,
      updatedAt: sale.updatedAt,
      items: sale.items.map(_toDomainItem).toList(),
    );
  }

  SaleItem _toDomainItem(_MockSaleItem item) {
    return SaleItem(
      id: item.id,
      menuItemId: item.menuItemId,
      menuItemName: item.menuItemName,
      quantity: item.quantity,
      modifiers: item.modifiers
          .map(
            (modifier) => SaleModifier(
              groupId: modifier['groupId']?.toString() ?? '',
              optionIds: ((modifier['optionIds'] as List<dynamic>?) ?? const [])
                  .map((value) => value.toString())
                  .toList(),
              optionLabels:
                  ((modifier['options'] as List<dynamic>?) ?? const [])
                      .map((option) {
                        if (option is Map<String, dynamic>) {
                          return option['label']?.toString() ?? '';
                        }
                        return option.toString();
                      })
                      .where((label) => label.isNotEmpty)
                      .toList(),
            ),
          )
          .toList(),
    );
  }

  _Totals _computeTotals({
    required double fxRateUsed,
    required List<_MockSaleItem> items,
    required String tenderCurrency,
    required Map<String, num>? cashReceived,
  }) {
    final subtotalUsd = _subtotalUsd(items);
    final subtotalKhr = subtotalUsd * fxRateUsed;

    final cashUsd = (cashReceived?['usd'] ?? 0).toDouble();
    final cashKhr = (cashReceived?['khr'] ?? 0).toDouble();

    final upperCurrency = tenderCurrency.toUpperCase();
    final changeUsd = upperCurrency == 'USD'
        ? max<double>(0, cashUsd - subtotalUsd)
        : 0.0;
    final changeKhr = upperCurrency == 'KHR'
        ? max<double>(0, cashKhr - subtotalKhr)
        : 0.0;

    return _Totals(
      subtotalUsdExact: subtotalUsd,
      subtotalKhrExact: subtotalKhr,
      totalUsdExact: subtotalUsd,
      totalKhrExact: subtotalKhr,
      cashReceivedUsd: cashUsd,
      cashReceivedKhr: cashKhr,
      changeGivenUsd: changeUsd,
      changeGivenKhr: changeKhr,
    );
  }

  double _subtotalUsd(List<_MockSaleItem> items) {
    return items.fold<double>(0, (sum, item) {
      final lineBase = item.lineTotalUsdExact > 0
          ? item.lineTotalUsdExact
          : item.unitPriceUsd;
      return sum + (lineBase * item.quantity);
    });
  }

  List<String> _modifierLabels(List<Map<String, dynamic>> modifiers) {
    final labels = <String>[];
    for (final modifier in modifiers) {
      final rawOptionIds = modifier['optionIds'];
      if (rawOptionIds is! List) continue;
      for (final optionId in rawOptionIds) {
        final value = optionId?.toString().trim() ?? '';
        if (value.isNotEmpty) labels.add(value);
      }
    }
    return labels;
  }

  _MockSaleItem _lineFromCommand(SaleCartLineInputDto line) {
    final modifiers = line.modifiers
        .map(
          (entry) => <String, dynamic>{
            'groupId': entry.groupId,
            'optionIds': entry.optionIds,
          },
        )
        .toList();

    return _MockSaleItem(
      id: _nextId('item'),
      menuItemId: line.menuItemId,
      menuItemName: line.menuItemId,
      quantity: line.quantity,
      modifiers: modifiers,
      unitPriceUsd: (line.unitPriceUsd ?? 1).toDouble(),
      lineTotalUsdExact: (line.lineTotalUsdExact ?? line.unitPriceUsd ?? 1)
          .toDouble(),
    );
  }

  _MockOpenTicketBatch _batchFromCartLines({
    required String batchId,
    required List<SaleCartLineInputDto> cartLines,
    required DateTime createdAt,
  }) {
    final items = cartLines.map(_lineFromCommand).toList();
    final totals = _computeTotals(
      fxRateUsed: 4100,
      items: items,
      tenderCurrency: 'USD',
      cashReceived: null,
    );

    return _MockOpenTicketBatch(
      batchId: batchId,
      items: items,
      totalUsdExact: totals.totalUsdExact,
      totalKhrExact: totals.totalKhrExact,
      createdAt: createdAt,
    );
  }

  SaleReceiptDto _buildReceipt({
    required String saleId,
    required String receiptId,
    required String paymentMethod,
    required double subtotalUsdExact,
    double discountUsdExact = 0,
    required double totalUsdExact,
    required double totalKhrExact,
    required List<_MockSaleItem> items,
    required DateTime issuedAt,
  }) {
    return SaleReceiptDto(
      saleId: saleId,
      receiptNumber: receiptId,
      paymentMethod: paymentMethod,
      subtotalUsdExact: subtotalUsdExact,
      discountUsdExact: discountUsdExact,
      taxUsdExact: 0,
      totalUsdExact: totalUsdExact,
      totalKhrExact: totalKhrExact,
      issuedAt: issuedAt,
      lines: items
          .map(
            (item) => SaleReceiptLineDto(
              name: item.menuItemName,
              quantity: item.quantity,
              unitPriceUsd: item.unitPriceUsd,
              lineTotalUsdExact: item.lineTotalUsdExact * item.quantity,
              modifiers: item.modifiers
                  .expand(
                    (modifier) =>
                        ((modifier['options'] as List<dynamic>?) ?? const [])
                            .whereType<Map<String, dynamic>>()
                            .map(
                              (option) => SaleReceiptModifierLineDto(
                                name:
                                    option['label']?.toString() ??
                                    option['name']?.toString() ??
                                    '',
                                priceDeltaUsd:
                                    (option['priceAdjustmentUsd'] as num?)
                                        ?.toDouble() ??
                                    0,
                              ),
                            ),
                  )
                  .where((modifier) => modifier.name.trim().isNotEmpty)
                  .toList(growable: false),
            ),
          )
          .toList(),
    );
  }

  _MockSaleDraft _requireDraft(String saleId) {
    final draft = _drafts[saleId];
    if (draft == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Sale draft was not found.',
      );
    }
    return draft;
  }

  void _ensureReadAllowed({required String branchId}) {
    if (!_authorized) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.unauthorized,
        message: 'You are not authorized for this branch.',
      );
    }
    if (!_adoptActiveBranchContext(branchId)) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.branchRequired,
        message: 'Branch context is required.',
      );
    }
  }

  void _ensureWriteAllowed({
    required String branchId,
    required bool requiresPayLaterEnabled,
    required bool requiresOnline,
    bool requiresCashSessionOpen = true,
  }) {
    final reason = _resolveBlockingReason(
      branchId: branchId,
      requiresPayLaterEnabled: requiresPayLaterEnabled,
      requiresOnline: requiresOnline,
      requiresCashSessionOpen: requiresCashSessionOpen,
    );
    if (reason != null) {
      throw SaleCheckoutRepositoryException(
        reasonCode: reason.code,
        message: reason.message,
      );
    }
  }

  _BlockingReason? _resolveBlockingReason({
    required String branchId,
    required bool requiresPayLaterEnabled,
    required bool requiresOnline,
    bool requiresCashSessionOpen = true,
  }) {
    if (!_authorized) {
      return const _BlockingReason(
        code: SaleCheckoutReasonCodes.unauthorized,
        message: 'You are not authorized for this action.',
      );
    }
    if (!_adoptActiveBranchContext(branchId)) {
      return const _BlockingReason(
        code: SaleCheckoutReasonCodes.branchRequired,
        message: 'Active branch context is required.',
      );
    }
    if (!_branchActive || _branchFrozen) {
      return const _BlockingReason(
        code: SaleCheckoutReasonCodes.branchFrozen,
        message: 'Branch is currently frozen for write operations.',
      );
    }
    if (requiresCashSessionOpen && !_isCashSessionOpen) {
      return const _BlockingReason(
        code: SaleCheckoutReasonCodes.cashSessionRequired,
        message: 'Open cash session is required before this action.',
      );
    }
    if (requiresPayLaterEnabled && !_payLaterEnabled) {
      return const _BlockingReason(
        code: SaleCheckoutReasonCodes.payLaterDisabled,
        message: 'Pay-later is disabled for this branch.',
      );
    }
    if (requiresOnline && !_online) {
      return const _BlockingReason(
        code: SaleCheckoutReasonCodes.offlineUnreachable,
        message: 'This action requires online connectivity.',
      );
    }
    return null;
  }

  bool _adoptActiveBranchContext(String branchId) {
    final normalized = branchId.trim();
    if (normalized.isEmpty) return false;
    _activeBranchId = normalized;
    return true;
  }

  String _ensurePayNowDraftForCheckout({
    required String saleId,
    required String saleType,
    required List<SaleCartLineInputDto> cartLines,
  }) {
    final normalizedSaleId = saleId.trim();
    if (normalizedSaleId.isNotEmpty) {
      final existingDraft = _drafts[normalizedSaleId];
      if (existingDraft != null) {
        if (cartLines.isNotEmpty) {
          existingDraft.items
            ..clear()
            ..addAll(cartLines.map(_lineFromCommand));
          existingDraft.updatedAt = _now();
          _syncCartFingerprintFromDraft(normalizedSaleId);
        }
        return normalizedSaleId;
      }
      if (cartLines.isEmpty) {
        return normalizedSaleId;
      }
      final now = _now();
      _drafts[normalizedSaleId] = _MockSaleDraft(
        saleId: normalizedSaleId,
        saleType: saleType,
        fxRateUsed: 4100,
        items: cartLines.map(_lineFromCommand).toList(),
        createdAt: now,
        updatedAt: now,
      );
      _syncCartFingerprintFromDraft(normalizedSaleId);
      return normalizedSaleId;
    }

    final generatedSaleId = 'mock_sale_${_nextId('checkout')}';
    final now = _now();
    _drafts[generatedSaleId] = _MockSaleDraft(
      saleId: generatedSaleId,
      saleType: saleType,
      fxRateUsed: 4100,
      items: cartLines.map(_lineFromCommand).toList(),
      createdAt: now,
      updatedAt: now,
    );
    _syncCartFingerprintFromDraft(generatedSaleId);
    return generatedSaleId;
  }

  void _ensureKhqrConfirmed({required String saleId, required String? md5}) {
    if (md5 == null || md5.trim().isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.khqrNotConfirmed,
        message: 'KHQR payment is not confirmed for this sale.',
      );
    }

    final attempt = _khqrByMd5[md5];
    if (attempt == null || attempt.saleId != saleId) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.khqrNotConfirmed,
        message: 'KHQR payment proof does not match this sale.',
      );
    }

    if (attempt.status != 'PAID_CONFIRMED') {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.khqrNotConfirmed,
        message: 'KHQR payment is still pending confirmation.',
      );
    }
  }

  bool _khqrAttemptMatchesCommandSaleId(
    String commandSaleId,
    _MockKhqrAttempt attempt,
  ) {
    final normalizedCommandSaleId = commandSaleId.trim();
    return normalizedCommandSaleId.isEmpty ||
        attempt.saleId == normalizedCommandSaleId;
  }

  double _resolveCurrentPayable({
    required String saleId,
    required String tenderCurrency,
  }) {
    final draft = _drafts[saleId];
    if (draft != null) {
      final totals = _computeTotals(
        fxRateUsed: draft.fxRateUsed,
        items: draft.items,
        tenderCurrency: tenderCurrency,
        cashReceived: null,
      );
      return tenderCurrency.toUpperCase() == 'KHR'
          ? totals.totalKhrExact
          : totals.totalUsdExact;
    }

    final ticketId = _openTicketIdBySaleId[saleId];
    final ticket = ticketId == null ? null : _openTicketsById[ticketId];
    if (ticket != null) {
      return tenderCurrency.toUpperCase() == 'KHR'
          ? ticket.payableKhrExact
          : ticket.payableUsdExact;
    }

    throw const SaleCheckoutRepositoryException(
      reasonCode: SaleCheckoutReasonCodes.invalidRequest,
      message: 'No payable sale context found for KHQR generation.',
    );
  }

  void _syncCartFingerprintFromDraft(String saleId) {
    final draft = _drafts[saleId];
    if (draft == null) return;
    _cartFingerprintBySaleId[saleId] = _fingerprintFromDraft(draft);
  }

  String _fingerprintFromDraft(_MockSaleDraft draft) {
    final payload = draft.items
        .map(
          (item) => {
            'menu_item_id': item.menuItemId,
            'quantity': item.quantity,
            'modifiers': item.modifiers,
            'unit_price_usd': item.unitPriceUsd,
            'line_total_usd_exact': item.lineTotalUsdExact,
          },
        )
        .toList();
    return _stableStringify(payload);
  }

  void _supersedeKhqrAttemptForSale({
    required String saleId,
    required String reason,
  }) {
    final latestMd5 = _latestKhqrMd5BySaleId[saleId];
    if (latestMd5 == null) return;

    final attempt = _khqrByMd5[latestMd5];
    if (attempt == null) return;

    if (attempt.status == 'WAITING_FOR_PAYMENT' ||
        attempt.status == 'PAID_CONFIRMED' ||
        attempt.status == 'PENDING_CONFIRMATION') {
      attempt.status = 'SUPERSEDED';
      attempt.reasonCode = SaleCheckoutReasonCodes.invalidRequest;
      attempt.reasonMessage = reason;
    }
  }

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

  String _nextId(String prefix) {
    final next = _idCounter++;
    return '$prefix-${next.toString().padLeft(6, '0')}';
  }

  DateTime _now() => _nowFactory().toUtc();

  String _stableStringify(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      final normalized = <String, dynamic>{
        for (final key in keys) key: _stableStringify(value[key]),
      };
      return jsonEncode(normalized);
    }
    if (value is Iterable) {
      return jsonEncode(value.map(_stableStringify).toList());
    }
    return jsonEncode(value);
  }
}

class _MockSaleDraft {
  _MockSaleDraft({
    required this.saleId,
    required this.saleType,
    required this.fxRateUsed,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final String saleId;
  final String saleType;
  final double fxRateUsed;
  final List<_MockSaleItem> items;
  final DateTime createdAt;
  DateTime updatedAt;
}

class _MockSaleItem {
  _MockSaleItem({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.modifiers,
    required this.unitPriceUsd,
    required this.lineTotalUsdExact,
  });

  final String id;
  final String menuItemId;
  final String menuItemName;
  final int quantity;
  final List<Map<String, dynamic>> modifiers;
  final double unitPriceUsd;
  final double lineTotalUsdExact;

  _MockSaleItem copyWith({
    String? id,
    String? menuItemId,
    String? menuItemName,
    int? quantity,
    List<Map<String, dynamic>>? modifiers,
    double? unitPriceUsd,
    double? lineTotalUsdExact,
  }) {
    return _MockSaleItem(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      quantity: quantity ?? this.quantity,
      modifiers: modifiers ?? this.modifiers,
      unitPriceUsd: unitPriceUsd ?? this.unitPriceUsd,
      lineTotalUsdExact: lineTotalUsdExact ?? this.lineTotalUsdExact,
    );
  }
}

class _MockOpenTicketBatch {
  _MockOpenTicketBatch({
    required this.batchId,
    required this.items,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.createdAt,
  });

  final String batchId;
  final List<_MockSaleItem> items;
  final double totalUsdExact;
  final double totalKhrExact;
  final DateTime createdAt;
}

class _MockOpenTicket {
  _MockOpenTicket({
    required this.openTicketId,
    required this.saleId,
    required this.status,
    required this.batches,
    required this.payableUsdExact,
    required this.payableKhrExact,
    required this.createdAt,
    required this.updatedAt,
  });

  final String openTicketId;
  final String saleId;
  String status;
  final List<_MockOpenTicketBatch> batches;
  double payableUsdExact;
  double payableKhrExact;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? cancelledAt;
}

class _MockManualPaymentClaim {
  _MockManualPaymentClaim({
    required this.claimId,
    required this.orderId,
    required this.claimedPaymentMethod,
    required this.saleType,
    required this.tenderCurrency,
    required this.claimedTenderAmount,
    required this.proofImageUrl,
    required this.customerReference,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  final String claimId;
  final String orderId;
  final String claimedPaymentMethod;
  final String saleType;
  final String tenderCurrency;
  final double claimedTenderAmount;
  final String proofImageUrl;
  final String? customerReference;
  final String? note;
  String status;
  final DateTime createdAt;
  DateTime? reviewedAt;
  String? reviewNote;
  String? saleId;
}

class _MockKhqrAttempt {
  _MockKhqrAttempt({
    required this.saleId,
    required this.attemptId,
    required this.md5,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.expiresAt,
    required this.pollCount,
    this.reasonCode,
    this.reasonMessage,
  });

  final String saleId;
  final String attemptId;
  final String md5;
  String status;
  final double amount;
  final String currency;
  final DateTime createdAt;
  final DateTime expiresAt;
  int pollCount;
  DateTime? confirmedAt;
  String? reasonCode;
  String? reasonMessage;
}

class _MockFinalizedSale {
  _MockFinalizedSale({
    required this.saleId,
    required this.saleType,
    required this.paymentMethod,
    required this.tenderCurrency,
    required this.subtotalUsdExact,
    required this.subtotalKhrExact,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.cashReceivedUsd,
    required this.cashReceivedKhr,
    required this.changeGivenUsd,
    required this.changeGivenKhr,
    required this.fulfillmentStatus,
    required this.state,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final String saleId;
  final String saleType;
  final String paymentMethod;
  final String tenderCurrency;
  final double subtotalUsdExact;
  final double subtotalKhrExact;
  final double totalUsdExact;
  final double totalKhrExact;
  final double cashReceivedUsd;
  final double cashReceivedKhr;
  final double changeGivenUsd;
  final double changeGivenKhr;
  String fulfillmentStatus;
  String state;
  final List<_MockSaleItem> items;
  final DateTime createdAt;
  DateTime updatedAt;
}

class _BlockingReason {
  const _BlockingReason({required this.code, required this.message});

  final String code;
  final String message;
}

class _Totals {
  const _Totals({
    required this.subtotalUsdExact,
    required this.subtotalKhrExact,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.cashReceivedUsd,
    required this.cashReceivedKhr,
    required this.changeGivenUsd,
    required this.changeGivenKhr,
  });

  final double subtotalUsdExact;
  final double subtotalKhrExact;
  final double totalUsdExact;
  final double totalKhrExact;
  final double cashReceivedUsd;
  final double cashReceivedKhr;
  final double changeGivenUsd;
  final double changeGivenKhr;
}

class _IdempotencyRecord {
  const _IdempotencyRecord({required this.payloadHash, required this.response});

  final String payloadHash;
  final Object response;
}

extension on SaleFinalizeSaleResultDto {
  SaleFinalizeSaleResultDto copyWith({bool? idempotentReplay}) {
    return SaleFinalizeSaleResultDto(
      saleId: saleId,
      status: status,
      totalUsdExact: totalUsdExact,
      totalKhrExact: totalKhrExact,
      idempotentReplay: idempotentReplay ?? this.idempotentReplay,
      orderId: orderId,
      receiptId: receiptId,
      receipt: receipt,
      reasonCode: reasonCode,
      reasonMessage: reasonMessage,
    );
  }
}

extension on SalePlaceOrderResultDto {
  SalePlaceOrderResultDto copyWith({bool? idempotentReplay}) {
    return SalePlaceOrderResultDto(
      openTicketId: openTicketId,
      saleId: saleId,
      status: status,
      batchId: batchId,
      idempotentReplay: idempotentReplay ?? this.idempotentReplay,
      reasonCode: reasonCode,
      reasonMessage: reasonMessage,
    );
  }
}

extension on SaleAddItemsToOpenTicketResultDto {
  SaleAddItemsToOpenTicketResultDto copyWith({bool? idempotentReplay}) {
    return SaleAddItemsToOpenTicketResultDto(
      openTicketId: openTicketId,
      batchId: batchId,
      idempotentReplay: idempotentReplay ?? this.idempotentReplay,
      reasonCode: reasonCode,
      reasonMessage: reasonMessage,
    );
  }
}

extension on SaleCreateManualPaymentClaimResultDto {
  SaleCreateManualPaymentClaimResultDto copyWith({bool? idempotentReplay}) {
    return SaleCreateManualPaymentClaimResultDto(
      claimId: claimId,
      orderId: orderId,
      status: status,
      idempotentReplay: idempotentReplay ?? this.idempotentReplay,
      reasonCode: reasonCode,
      reasonMessage: reasonMessage,
    );
  }
}

extension on SaleApproveManualPaymentClaimResultDto {
  SaleApproveManualPaymentClaimResultDto copyWith({bool? idempotentReplay}) {
    return SaleApproveManualPaymentClaimResultDto(
      claimId: claimId,
      orderId: orderId,
      status: status,
      idempotentReplay: idempotentReplay ?? this.idempotentReplay,
      saleId: saleId,
      receiptId: receiptId,
      receipt: receipt,
      reasonCode: reasonCode,
      reasonMessage: reasonMessage,
    );
  }
}

extension on SaleRejectManualPaymentClaimResultDto {
  SaleRejectManualPaymentClaimResultDto copyWith({bool? idempotentReplay}) {
    return SaleRejectManualPaymentClaimResultDto(
      claimId: claimId,
      orderId: orderId,
      status: status,
      idempotentReplay: idempotentReplay ?? this.idempotentReplay,
      reasonCode: reasonCode,
      reasonMessage: reasonMessage,
    );
  }
}

extension on SaleCheckoutOpenTicketResultDto {
  SaleCheckoutOpenTicketResultDto copyWith({bool? idempotentReplay}) {
    return SaleCheckoutOpenTicketResultDto(
      openTicketId: openTicketId,
      saleId: saleId,
      status: status,
      idempotentReplay: idempotentReplay ?? this.idempotentReplay,
      receiptId: receiptId,
      reasonCode: reasonCode,
      reasonMessage: reasonMessage,
    );
  }
}

extension on SaleCancelOpenTicketResultDto {
  SaleCancelOpenTicketResultDto copyWith({bool? idempotentReplay}) {
    return SaleCancelOpenTicketResultDto(
      openTicketId: openTicketId,
      status: status,
      idempotentReplay: idempotentReplay ?? this.idempotentReplay,
      cancelledAt: cancelledAt,
      reasonCode: reasonCode,
      reasonMessage: reasonMessage,
    );
  }
}
