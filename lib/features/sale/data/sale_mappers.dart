import 'package:modular_pos/features/sale/data/dto/sale_dto.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';

class SaleMappers {
  const SaleMappers._();

  static SaleImmediateReceiptDto? toImmediateReceipt(
    SaleReceiptProjectionDto? receipt,
  ) {
    if (receipt == null) return null;
    if (receipt.receiptId.trim().isEmpty) return null;
    return SaleImmediateReceiptDto(
      receiptId: receipt.receiptId,
      saleId: receipt.saleId,
      statusDisplay: receipt.statusDisplay,
      issuedAt: receipt.issuedAt.toLocal(),
    );
  }

  static SaleReceiptDto toCanonicalReceipt(SaleReceiptReadDto receipt) {
    return SaleReceiptDto(
      saleId: receipt.saleId,
      receiptNumber: receipt.receiptNumber.isEmpty
          ? receipt.receiptId
          : receipt.receiptNumber,
      paymentMethod: toUiPaymentMethod(receipt.saleSnapshot.paymentMethod),
      subtotalUsdExact: receipt.saleSnapshot.subtotalUsd,
      taxUsdExact: receipt.saleSnapshot.vatUsd,
      totalUsdExact: receipt.saleSnapshot.grandTotalUsd,
      totalKhrExact: receipt.saleSnapshot.grandTotalKhr,
      issuedAt: receipt.issuedAt.toLocal(),
      lines: receipt.lines
          .map(
            (line) => SaleReceiptLineDto(
              name: line.name,
              quantity: line.quantity,
              unitPriceUsd: line.unitPrice,
              lineTotalUsdExact: line.lineTotalAmount,
              modifiers: line.modifiers
                  .map(
                    (modifier) => SaleReceiptModifierLineDto(
                      name: modifier.name,
                      priceDeltaUsd: modifier.priceDeltaUsd,
                    ),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
  }

  static Sale toDomainSale(SaleDto dto) {
    return Sale(
      id: dto.id,
      saleType: dto.saleType,
      state: normalizeSaleState(dto.state),
      fulfillmentStatus: dto.fulfillmentStatus,
      paymentMethod: normalizePaymentMethod(dto.paymentMethod),
      tenderCurrency: normalizeTenderCurrency(dto.tenderCurrency),
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
                    (modifier) => SaleModifier(
                      groupId: modifier.groupId,
                      optionIds: modifier.optionIds,
                      optionLabels: modifier.options
                          .map((option) => option.label)
                          .where((label) => label.isNotEmpty)
                          .toList(growable: false),
                    ),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
  }

  static SaleCheckoutSummary toCheckoutSummary(SaleDto dto) {
    final tenderCurrency = normalizeTenderCurrency(
      dto.tenderCurrency,
    ).toLowerCase();
    return SaleCheckoutSummary(
      saleId: dto.id,
      tenderCurrency: tenderCurrency,
      paymentMethod: toUiPaymentMethod(dto.paymentMethod),
      totalUsdExact: dto.totalUsdExact,
      totalKhrExact: dto.totalKhrExact,
      cashReceivedUsd: dto.cashReceivedUsd ?? 0,
      cashReceivedKhr: dto.cashReceivedKhr ?? 0,
      changeGivenUsd: dto.changeGivenUsd ?? 0,
      changeGivenKhr: dto.changeGivenKhr ?? 0,
    );
  }

  static SaleCheckoutSummary toCheckoutSummaryFromDraft(SaleDraftDto dto) {
    final tenderCurrency = normalizeTenderCurrency(
      dto.tenderCurrency,
    ).toLowerCase();
    return SaleCheckoutSummary(
      saleId: dto.id,
      tenderCurrency: tenderCurrency,
      paymentMethod: toUiPaymentMethod(dto.paymentMethod),
      totalUsdExact: dto.totalUsdExact,
      totalKhrExact: dto.totalKhrExact,
      cashReceivedUsd: dto.cashReceivedUsd ?? 0,
      cashReceivedKhr: dto.cashReceivedKhr ?? 0,
      changeGivenUsd: dto.changeGivenUsd ?? 0,
      changeGivenKhr: dto.changeGivenKhr ?? 0,
    );
  }

  static SaleKhqrAttemptDto toKhqrAttempt({
    required SaleGenerateKhqrAttemptCommand command,
    required SaleKhqrInitiateResponseDto response,
    required DateTime expiresAt,
  }) {
    final intentId = response.intent.paymentIntentId.ifEmpty(response.id);
    final normalizedCurrency = normalizeTenderCurrency(command.tenderCurrency);
    final amount =
        response.paymentRequest.amount ??
        (normalizedCurrency == 'KHR'
            ? response.preview.grandTotalKhr
            : response.preview.grandTotalUsd);
    return SaleKhqrAttemptDto(
      saleId: (response.attempt.saleId ?? '')
          .ifEmpty(response.intent.saleId ?? '')
          .ifEmpty(command.saleId),
      attemptId: intentId,
      md5: response.attempt.md5,
      status: normalizeKhqrStatus(
        rawStatus: response.attempt.status,
        saleId: response.attempt.saleId,
      ),
      amount: amount,
      currency:
          normalizeTenderCurrency(response.paymentRequest.currency ?? '') ==
                  'USD' &&
              (response.paymentRequest.currency ?? '').trim().isEmpty
          ? normalizedCurrency
          : normalizeTenderCurrency(response.paymentRequest.currency ?? ''),
      expiresAt: response.paymentRequest.expiresAt ?? expiresAt,
      qrPayload: response.paymentRequest.payload,
      payloadType: response.paymentRequest.payloadType,
      deepLinkUrl: response.paymentRequest.deepLinkUrl,
      toAccountId: response.paymentRequest.toAccountId,
      reasonCode: response.intent.reasonCode,
      reasonMessage: null,
    );
  }

  static SaleKhqrStatusDto toKhqrStatus({
    required SaleCheckKhqrStatusCommand command,
    required SaleKhqrIntentStateDto state,
  }) {
    return SaleKhqrStatusDto(
      saleId: (state.saleId ?? '').ifEmpty(command.saleId),
      md5: command.md5,
      status: normalizeKhqrStatus(
        rawStatus: state.status,
        saleId: state.saleId,
      ),
      confirmedAt: null,
      reasonCode: state.reasonCode,
      reasonMessage: null,
    );
  }

  static SaleFinalizeSaleResultDto toFinalizeResultFromCashCheckout(
    SaleCashCheckoutResponseDto response, {
    bool idempotentReplay = false,
  }) {
    final resolvedSaleId = _resolveFinalizeSaleId(
      saleId: response.sale.id,
      receipt: response.receipt,
    );
    return SaleFinalizeSaleResultDto(
      saleId: resolvedSaleId,
      status: normalizeSaleState(response.sale.state),
      totalUsdExact: response.sale.totalUsdExact,
      totalKhrExact: response.sale.totalKhrExact,
      idempotentReplay: idempotentReplay,
      cashReceivedUsd: response.sale.cashReceivedUsd,
      cashReceivedKhr: response.sale.cashReceivedKhr,
      changeGivenUsd: response.sale.changeGivenUsd,
      changeGivenKhr: response.sale.changeGivenKhr,
      orderId: null,
      receiptId: response.receipt?.receiptId,
      receipt: toImmediateReceipt(response.receipt),
    );
  }

  static SaleFinalizeSaleResultDto toFinalizeResultFromFinalizeResponse(
    SaleFinalizeResponseDto response, {
    bool idempotentReplay = false,
  }) {
    final resolvedSaleId = _resolveFinalizeSaleId(
      saleId: response.sale.id,
      receipt: response.receipt,
    );
    return SaleFinalizeSaleResultDto(
      saleId: resolvedSaleId,
      status: normalizeSaleState(response.sale.state),
      totalUsdExact: response.sale.totalUsdExact,
      totalKhrExact: response.sale.totalKhrExact,
      idempotentReplay: idempotentReplay,
      cashReceivedUsd: response.sale.cashReceivedUsd,
      cashReceivedKhr: response.sale.cashReceivedKhr,
      changeGivenUsd: response.sale.changeGivenUsd,
      changeGivenKhr: response.sale.changeGivenKhr,
      orderId: null,
      receiptId: response.receipt?.receiptId,
      receipt: toImmediateReceipt(response.receipt),
    );
  }

  static String normalizeKhqrStatus({
    required String rawStatus,
    required String? saleId,
  }) {
    final normalized = rawStatus.trim().toUpperCase();
    if ((saleId?.trim().isNotEmpty ?? false) &&
        normalized != 'WAITING_FOR_PAYMENT' &&
        normalized != 'CANCELLED') {
      return 'PAID_CONFIRMED';
    }
    return switch (normalized) {
      'WAITING_FOR_PAYMENT' => 'WAITING_FOR_PAYMENT',
      'CANCELLED' => 'CANCELLED',
      'EXPIRED' => 'EXPIRED',
      'PENDING_CONFIRMATION' => 'PENDING_CONFIRMATION',
      'PAID_CONFIRMED' => 'PAID_CONFIRMED',
      _ => normalized,
    };
  }

  static String normalizeSaleState(String rawState) {
    final normalized = rawState.trim().toUpperCase();
    return switch (normalized) {
      'FINALIZED' => 'FINALIZED',
      'PENDING' => 'PENDING',
      'VOID_PENDING' => 'VOID_PENDING',
      'VOIDED' => 'VOIDED',
      'DRAFT' => 'PENDING',
      'REOPENED' => 'PENDING',
      _ => normalized.isEmpty ? 'PENDING' : normalized,
    };
  }

  static String normalizePaymentMethod(String rawMethod) {
    final normalized = rawMethod.trim().toUpperCase();
    return switch (normalized) {
      'CASH' => 'CASH',
      'KHQR' => 'KHQR',
      'QR' => 'KHQR',
      _ => normalized.isEmpty ? 'CASH' : normalized,
    };
  }

  static String normalizeTenderCurrency(String rawCurrency) {
    final normalized = rawCurrency.trim().toUpperCase();
    return switch (normalized) {
      'USD' => 'USD',
      'KHR' => 'KHR',
      _ => normalized.isEmpty ? 'USD' : normalized,
    };
  }

  static String toUiPaymentMethod(String rawMethod) {
    final normalized = normalizePaymentMethod(rawMethod);
    return switch (normalized) {
      'KHQR' => 'qr',
      'CASH' => 'cash',
      _ => normalized.toLowerCase(),
    };
  }

  static String _resolveFinalizeSaleId({
    required String saleId,
    required SaleReceiptProjectionDto? receipt,
  }) {
    final normalizedSaleId = saleId.trim();
    if (normalizedSaleId.isNotEmpty) {
      return normalizedSaleId;
    }

    final receiptSaleId = receipt?.saleId.trim() ?? '';
    if (receiptSaleId.isNotEmpty) {
      return receiptSaleId;
    }

    return receipt?.receiptId.trim() ?? '';
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
