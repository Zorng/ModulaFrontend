import 'package:modular_pos/features/sale/domain/models/sale.dart';

class SaleCheckoutReasonCodes {
  static const unauthorized = 'UNAUTHORIZED';
  static const branchRequired = 'BRANCH_REQUIRED';
  static const branchFrozen = 'BRANCH_FROZEN';
  static const cashSessionRequired = 'CASH_SESSION_REQUIRED';
  static const payLaterDisabled = 'PAY_LATER_DISABLED';
  static const khqrNotConfirmed = 'KHQR_NOT_CONFIRMED';
  static const khqrBranchReceiverNotConfigured =
      'KHQR_BRANCH_RECEIVER_NOT_CONFIGURED';
  static const duplicateOperation = 'DUPLICATE_OPERATION';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const invalidRequest = 'INVALID_REQUEST';
  static const offlineUnreachable = 'OFFLINE_UNREACHABLE';
  static const unknownError = 'UNKNOWN_ERROR';

  static String? normalize(String? raw) {
    final code = _canonicalize(raw);
    switch (code) {
      case null:
      case '':
        return null;
      case unauthorized:
      case branchRequired:
      case branchFrozen:
      case cashSessionRequired:
      case payLaterDisabled:
      case khqrNotConfirmed:
      case khqrBranchReceiverNotConfigured:
      case duplicateOperation:
      case idempotencyConflict:
      case invalidRequest:
      case offlineUnreachable:
      case unknownError:
        return code;
      case 'TENANT_CONTEXT_REQUIRED':
      case 'BRANCH_CONTEXT_REQUIRED':
      case 'NO_BRANCH_ACCESS':
      case 'NO_MEMBERSHIP':
      case 'NO_TENANT_ACCESS':
      case 'PERMISSION_DENIED':
      case 'FORBIDDEN':
        return branchRequired;
      case 'SUBSCRIPTION_FROZEN':
      case 'BRANCH_NOT_ACTIVE':
        return branchFrozen;
      case 'ORDER_REQUIRES_OPEN_CASH_SESSION':
      case 'SALE_FINALIZE_REQUIRES_OPEN_CASH_SESSION':
      case 'KHQR_GENERATE_REQUIRES_OPEN_CASH_SESSION':
        return cashSessionRequired;
      case 'ORDER_PAY_LATER_DISABLED':
        return payLaterDisabled;
      case 'SALE_FINALIZE_KHQR_CONFIRMATION_REQUIRED':
      case 'SALE_FINALIZE_KHQR_PROOF_MISMATCH':
      case 'PAYMENT_INTENT_NOT_FOUND':
      case 'PAYMENT_ALREADY_CONFIRMED':
        return khqrNotConfirmed;
      case 'IDEMPOTENCY_KEY_REQUIRED':
      case 'IDEMPOTENCY_IN_PROGRESS':
        return idempotencyConflict;
      case 'SALE_VALIDATION_FAILED':
      case 'ORDER_VALIDATION_FAILED':
        return invalidRequest;
      default:
        return code;
    }
  }

  static String? _canonicalize(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

class SaleCheckoutRepositoryException implements Exception {
  const SaleCheckoutRepositoryException({
    required this.reasonCode,
    required this.message,
  });

  final String reasonCode;
  final String message;

  @override
  String toString() =>
      'SaleCheckoutRepositoryException(reasonCode: $reasonCode, message: $message)';
}

class SaleCashReceivedInputDto {
  const SaleCashReceivedInputDto({this.usd, this.khr});

  final num? usd;
  final num? khr;

  Map<String, dynamic> toJson() {
    return {if (usd != null) 'usd': usd, if (khr != null) 'khr': khr};
  }
}

class SaleCartModifierInputDto {
  const SaleCartModifierInputDto({
    required this.groupId,
    required this.optionIds,
  });

  final String groupId;
  final List<String> optionIds;

  Map<String, dynamic> toJson() {
    return {'group_id': groupId, 'option_ids': optionIds};
  }
}

class SaleCartLineInputDto {
  const SaleCartLineInputDto({
    required this.menuItemId,
    required this.quantity,
    required this.modifiers,
    this.unitPriceUsd,
    this.lineTotalUsdExact,
    this.addonTotalUsd,
    this.pricingSnapshot,
  });

  final String menuItemId;
  final int quantity;
  final List<SaleCartModifierInputDto> modifiers;
  final num? unitPriceUsd;
  final num? lineTotalUsdExact;
  final num? addonTotalUsd;
  final Map<String, dynamic>? pricingSnapshot;

  Map<String, dynamic> toJson() {
    return {
      'menu_item_id': menuItemId,
      'quantity': quantity,
      'modifiers': modifiers.map((item) => item.toJson()).toList(),
      if (unitPriceUsd != null) 'unit_price_usd': unitPriceUsd,
      if (lineTotalUsdExact != null) 'line_total_usd_exact': lineTotalUsdExact,
      if (addonTotalUsd != null) 'addon_total_usd': addonTotalUsd,
      if (pricingSnapshot != null) 'pricing_snapshot': pricingSnapshot,
    };
  }
}

class SalePricingSnapshotDto {
  const SalePricingSnapshotDto({
    required this.baseUnitPriceUsd,
    required this.addonTotalUsd,
    required this.unitPriceUsd,
    required this.lineTotalUsdExact,
  });

  final double baseUnitPriceUsd;
  final double addonTotalUsd;
  final double unitPriceUsd;
  final double lineTotalUsdExact;

  Map<String, dynamic> toJson() {
    return {
      'baseUnitPriceUsd': baseUnitPriceUsd,
      'addonTotalUsd': addonTotalUsd,
      'unitPriceUsd': unitPriceUsd,
      'lineTotalUsdExact': lineTotalUsdExact,
    };
  }
}

class SaleDraftModifierOptionDto {
  const SaleDraftModifierOptionDto({
    required this.id,
    required this.label,
    required this.priceAdjustmentUsd,
    required this.isDefault,
  });

  final String id;
  final String label;
  final double priceAdjustmentUsd;
  final bool isDefault;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'priceAdjustmentUsd': priceAdjustmentUsd,
      'isDefault': isDefault,
    };
  }
}

class SaleDraftModifierInputDto {
  const SaleDraftModifierInputDto({
    required this.groupId,
    required this.optionIds,
    this.options = const [],
    this.priceAdjustmentUsd = 0,
    this.priceAdjustmentUsdTotal,
    this.pricingSnapshot,
  });

  final String groupId;
  final List<String> optionIds;
  final List<SaleDraftModifierOptionDto> options;
  final double priceAdjustmentUsd;
  final double? priceAdjustmentUsdTotal;
  final SalePricingSnapshotDto? pricingSnapshot;

  Map<String, dynamic> toLegacyJson() {
    return {
      'groupId': groupId,
      'optionIds': optionIds,
      if (options.isNotEmpty)
        'options': options.map((item) => item.toJson()).toList(),
      'priceAdjustmentUsd': priceAdjustmentUsd,
      if (priceAdjustmentUsdTotal != null)
        'priceAdjustmentUsdTotal': priceAdjustmentUsdTotal,
      if (pricingSnapshot != null) 'pricingSnapshot': pricingSnapshot!.toJson(),
    };
  }
}

class SaleDraftItemInputDto {
  const SaleDraftItemInputDto({
    required this.menuItemId,
    required this.quantity,
    required this.selectedOptionIds,
    required this.modifiers,
    this.unitPriceUsd,
    this.lineTotalUsdExact,
    this.addonTotalUsd,
    this.pricingSnapshot,
  });

  final String menuItemId;
  final int quantity;
  final Map<String, List<String>> selectedOptionIds;
  final List<SaleDraftModifierInputDto> modifiers;
  final double? unitPriceUsd;
  final double? lineTotalUsdExact;
  final double? addonTotalUsd;
  final SalePricingSnapshotDto? pricingSnapshot;

  Map<String, dynamic> toLegacyApiJson() {
    final modifierPayloads = modifiers
        .map((item) => item.toLegacyJson())
        .toList(growable: true);
    final snapshotJson = pricingSnapshot?.toJson();
    if (snapshotJson != null) {
      if (modifierPayloads.isNotEmpty) {
        modifierPayloads.first['pricingSnapshot'] = snapshotJson;
      } else {
        modifierPayloads.add({'pricingSnapshot': snapshotJson});
      }
    }
    return {
      'menuItemId': menuItemId,
      'quantity': quantity,
      'modifiers': modifierPayloads,
      if (unitPriceUsd != null) 'unitPriceUsd': unitPriceUsd,
      if (lineTotalUsdExact != null) 'lineTotalUsdExact': lineTotalUsdExact,
      if (addonTotalUsd != null) 'addonTotalUsd': addonTotalUsd,
      if (snapshotJson != null) 'pricingSnapshot': snapshotJson,
    };
  }
}

class SaleContextDto {
  const SaleContextDto({
    required this.branchId,
    required this.branchActive,
    required this.branchFrozen,
    required this.cashSessionOpen,
    required this.canMutateCart,
    required this.canCheckout,
    required this.canPlacePayLater,
    this.reasonCode,
    this.reasonMessage,
  });

  final String branchId;
  final bool branchActive;
  final bool branchFrozen;
  final bool cashSessionOpen;
  final bool canMutateCart;
  final bool canCheckout;
  final bool canPlacePayLater;
  final String? reasonCode;
  final String? reasonMessage;

  Map<String, dynamic> toJson() {
    return {
      'branch_id': branchId,
      'branch_active': branchActive,
      'branch_frozen': branchFrozen,
      'cash_session_open': cashSessionOpen,
      'can_mutate_cart': canMutateCart,
      'can_checkout': canCheckout,
      'can_place_pay_later': canPlacePayLater,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (reasonMessage != null) 'reason_message': reasonMessage,
    };
  }
}

class SaleComputeCheckoutPreviewCommand {
  const SaleComputeCheckoutPreviewCommand({
    required this.saleId,
    required this.saleType,
    required this.paymentMethod,
    required this.tenderCurrency,
    required this.cartLines,
    this.cashReceived,
  });

  final String saleId;
  final String saleType;
  final String paymentMethod;
  final String tenderCurrency;
  final List<SaleCartLineInputDto> cartLines;
  final SaleCashReceivedInputDto? cashReceived;

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'sale_type': saleType,
      'payment_method': paymentMethod,
      'tender_currency': tenderCurrency,
      'cart_lines': cartLines.map((item) => item.toJson()).toList(),
      if (cashReceived != null) 'cash_received': cashReceived!.toJson(),
    };
  }
}

class SaleCheckoutPreviewDto {
  const SaleCheckoutPreviewDto({
    required this.saleId,
    required this.tenderCurrency,
    required this.paymentMethod,
    required this.subtotalUsdExact,
    required this.subtotalKhrExact,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.cashReceivedUsd,
    required this.cashReceivedKhr,
    required this.changeGivenUsd,
    required this.changeGivenKhr,
    this.reasonCode,
    this.reasonMessage,
  });

  final String saleId;
  final String tenderCurrency;
  final String paymentMethod;
  final double subtotalUsdExact;
  final double subtotalKhrExact;
  final double totalUsdExact;
  final double totalKhrExact;
  final double cashReceivedUsd;
  final double cashReceivedKhr;
  final double changeGivenUsd;
  final double changeGivenKhr;
  final String? reasonCode;
  final String? reasonMessage;

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'tender_currency': tenderCurrency,
      'payment_method': paymentMethod,
      'subtotal_usd_exact': subtotalUsdExact,
      'subtotal_khr_exact': subtotalKhrExact,
      'total_usd_exact': totalUsdExact,
      'total_khr_exact': totalKhrExact,
      'cash_received_usd': cashReceivedUsd,
      'cash_received_khr': cashReceivedKhr,
      'change_given_usd': changeGivenUsd,
      'change_given_khr': changeGivenKhr,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (reasonMessage != null) 'reason_message': reasonMessage,
    };
  }
}

class SaleGenerateKhqrAttemptCommand {
  const SaleGenerateKhqrAttemptCommand({
    required this.saleId,
    required this.tenderCurrency,
    required this.clientOpId,
    this.saleType,
    this.cartLines = const [],
    this.expiresInSeconds,
  });

  final String saleId;
  final String tenderCurrency;
  final String clientOpId;
  final String? saleType;
  final List<SaleCartLineInputDto> cartLines;
  final int? expiresInSeconds;

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'tender_currency': tenderCurrency,
      'client_op_id': clientOpId,
      if (saleType != null) 'sale_type': saleType,
      'cart_lines': cartLines.map((item) => item.toJson()).toList(),
      if (expiresInSeconds != null) 'expires_in_seconds': expiresInSeconds,
    };
  }
}

class SaleKhqrAttemptDto {
  const SaleKhqrAttemptDto({
    required this.saleId,
    required this.attemptId,
    required this.md5,
    required this.status,
    required this.amount,
    required this.currency,
    required this.expiresAt,
    this.qrPayload,
    this.payloadType,
    this.deepLinkUrl,
    this.toAccountId,
    this.reasonCode,
    this.reasonMessage,
  });

  final String saleId;
  final String attemptId;
  final String md5;
  final String status;
  final double amount;
  final String currency;
  final DateTime expiresAt;
  final String? qrPayload;
  final String? payloadType;
  final String? deepLinkUrl;
  final String? toAccountId;
  final String? reasonCode;
  final String? reasonMessage;
}

class SaleCheckKhqrStatusCommand {
  const SaleCheckKhqrStatusCommand({
    required this.saleId,
    required this.md5,
    this.intentId,
  });

  final String saleId;
  final String md5;
  final String? intentId;

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'md5': md5,
      if (intentId != null) 'intent_id': intentId,
    };
  }
}

class SaleCancelKhqrAttemptCommand {
  const SaleCancelKhqrAttemptCommand({
    required this.saleId,
    required this.md5,
    required this.intentId,
    required this.clientOpId,
  });

  final String saleId;
  final String md5;
  final String intentId;
  final String clientOpId;

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'md5': md5,
      'intent_id': intentId,
      'client_op_id': clientOpId,
    };
  }
}

class SaleKhqrStatusDto {
  const SaleKhqrStatusDto({
    required this.saleId,
    required this.md5,
    required this.status,
    this.confirmedAt,
    this.reasonCode,
    this.reasonMessage,
  });

  final String saleId;
  final String md5;
  final String status;
  final DateTime? confirmedAt;
  final String? reasonCode;
  final String? reasonMessage;
}

class SaleFinalizeSaleCommand {
  const SaleFinalizeSaleCommand({
    required this.saleId,
    required this.paymentMethod,
    required this.tenderCurrency,
    required this.clientOpId,
    this.cashReceived,
    this.khqrMd5,
    this.saleType,
    this.cartLines = const [],
  });

  final String saleId;
  final String paymentMethod;
  final String tenderCurrency;
  final String clientOpId;
  final SaleCashReceivedInputDto? cashReceived;
  final String? khqrMd5;
  final String? saleType;
  final List<SaleCartLineInputDto> cartLines;

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'payment_method': paymentMethod,
      'tender_currency': tenderCurrency,
      'client_op_id': clientOpId,
      if (cashReceived != null) 'cash_received': cashReceived!.toJson(),
      if (khqrMd5 != null) 'khqr_md5': khqrMd5,
      if (saleType != null) 'sale_type': saleType,
      'cart_lines': cartLines.map((item) => item.toJson()).toList(),
    };
  }
}

class SaleFinalizeSaleResultDto {
  const SaleFinalizeSaleResultDto({
    required this.saleId,
    required this.status,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.idempotentReplay,
    this.cashReceivedUsd,
    this.cashReceivedKhr,
    this.changeGivenUsd,
    this.changeGivenKhr,
    this.orderId,
    this.receiptId,
    this.receipt,
    this.reasonCode,
    this.reasonMessage,
  });

  final String saleId;
  final String status;
  final double totalUsdExact;
  final double totalKhrExact;
  final bool idempotentReplay;
  final double? cashReceivedUsd;
  final double? cashReceivedKhr;
  final double? changeGivenUsd;
  final double? changeGivenKhr;
  final String? orderId;
  final String? receiptId;
  final SaleImmediateReceiptDto? receipt;
  final String? reasonCode;
  final String? reasonMessage;
}

class SaleImmediateReceiptDto {
  const SaleImmediateReceiptDto({
    required this.receiptId,
    required this.saleId,
    required this.statusDisplay,
    required this.issuedAt,
  });

  final String receiptId;
  final String saleId;
  final String statusDisplay;
  final DateTime issuedAt;
}

class SalePlaceOrderCommand {
  const SalePlaceOrderCommand({
    required this.saleId,
    required this.branchId,
    required this.saleType,
    required this.clientOpId,
    required this.cartLines,
  });

  final String saleId;
  final String branchId;
  final String saleType;
  final String clientOpId;
  final List<SaleCartLineInputDto> cartLines;

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'branch_id': branchId,
      'sale_type': saleType,
      'client_op_id': clientOpId,
      'cart_lines': cartLines.map((item) => item.toJson()).toList(),
    };
  }
}

class SalePlaceOrderResultDto {
  const SalePlaceOrderResultDto({
    required this.openTicketId,
    required this.saleId,
    required this.status,
    required this.batchId,
    required this.idempotentReplay,
    this.reasonCode,
    this.reasonMessage,
  });

  final String openTicketId;
  final String saleId;
  final String status;
  final String batchId;
  final bool idempotentReplay;
  final String? reasonCode;
  final String? reasonMessage;
}

class SaleAddItemsToOpenTicketCommand {
  const SaleAddItemsToOpenTicketCommand({
    required this.openTicketId,
    required this.clientOpId,
    required this.cartLines,
  });

  final String openTicketId;
  final String clientOpId;
  final List<SaleCartLineInputDto> cartLines;

  Map<String, dynamic> toJson() {
    return {
      'open_ticket_id': openTicketId,
      'client_op_id': clientOpId,
      'cart_lines': cartLines.map((item) => item.toJson()).toList(),
    };
  }
}

class SaleAddItemsToOpenTicketResultDto {
  const SaleAddItemsToOpenTicketResultDto({
    required this.openTicketId,
    required this.batchId,
    required this.idempotentReplay,
    this.reasonCode,
    this.reasonMessage,
  });

  final String openTicketId;
  final String batchId;
  final bool idempotentReplay;
  final String? reasonCode;
  final String? reasonMessage;
}

class SaleCheckoutOpenTicketCommand {
  const SaleCheckoutOpenTicketCommand({
    required this.openTicketId,
    required this.paymentMethod,
    required this.tenderCurrency,
    required this.clientOpId,
    this.cashReceived,
    this.khqrMd5,
  });

  final String openTicketId;
  final String paymentMethod;
  final String tenderCurrency;
  final String clientOpId;
  final SaleCashReceivedInputDto? cashReceived;
  final String? khqrMd5;

  Map<String, dynamic> toJson() {
    return {
      'open_ticket_id': openTicketId,
      'payment_method': paymentMethod,
      'tender_currency': tenderCurrency,
      'client_op_id': clientOpId,
      if (cashReceived != null) 'cash_received': cashReceived!.toJson(),
      if (khqrMd5 != null) 'khqr_md5': khqrMd5,
    };
  }
}

class SaleCheckoutOpenTicketResultDto {
  const SaleCheckoutOpenTicketResultDto({
    required this.openTicketId,
    required this.saleId,
    required this.status,
    required this.idempotentReplay,
    this.receiptId,
    this.reasonCode,
    this.reasonMessage,
  });

  final String openTicketId;
  final String saleId;
  final String status;
  final bool idempotentReplay;
  final String? receiptId;
  final String? reasonCode;
  final String? reasonMessage;
}

class SaleCancelOpenTicketCommand {
  const SaleCancelOpenTicketCommand({
    required this.openTicketId,
    required this.reason,
    required this.clientOpId,
  });

  final String openTicketId;
  final String reason;
  final String clientOpId;

  Map<String, dynamic> toJson() {
    return {
      'open_ticket_id': openTicketId,
      'reason': reason,
      'client_op_id': clientOpId,
    };
  }
}

class SaleCancelOpenTicketResultDto {
  const SaleCancelOpenTicketResultDto({
    required this.openTicketId,
    required this.status,
    required this.idempotentReplay,
    required this.cancelledAt,
    this.reasonCode,
    this.reasonMessage,
  });

  final String openTicketId;
  final String status;
  final bool idempotentReplay;
  final DateTime cancelledAt;
  final String? reasonCode;
  final String? reasonMessage;
}

class SaleOrdersQueryDto {
  const SaleOrdersQueryDto({
    this.status,
    this.from,
    this.to,
    this.page = 1,
    this.limit = 50,
  });

  final String? status;
  final DateTime? from;
  final DateTime? to;
  final int page;
  final int limit;

  Map<String, dynamic> toJson() {
    return {
      if (status != null && status!.isNotEmpty) 'status': status,
      if (from != null) 'from': from!.toUtc().toIso8601String(),
      if (to != null) 'to': to!.toUtc().toIso8601String(),
      'page': page,
      'limit': limit,
    };
  }
}

class SaleOrderSummaryDto {
  const SaleOrderSummaryDto({
    required this.saleId,
    required this.orderId,
    required this.ticketStatus,
    required this.fulfillmentStatus,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.placedAt,
  });

  final String saleId;
  final String orderId;
  final String ticketStatus;
  final String fulfillmentStatus;
  final double totalUsdExact;
  final double totalKhrExact;
  final DateTime placedAt;
}

class SaleOrdersPageDto {
  const SaleOrdersPageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<SaleOrderSummaryDto> items;
  final int page;
  final int limit;
  final int total;
}

class SaleOpenTicketBatchDto {
  const SaleOpenTicketBatchDto({
    required this.batchId,
    required this.createdAt,
    required this.totalUsdExact,
    required this.totalKhrExact,
  });

  final String batchId;
  final DateTime createdAt;
  final double totalUsdExact;
  final double totalKhrExact;
}

class SaleOpenTicketDetailDto {
  const SaleOpenTicketDetailDto({
    required this.openTicketId,
    required this.saleId,
    required this.status,
    required this.batches,
    required this.payableUsdExact,
    required this.payableKhrExact,
  });

  final String openTicketId;
  final String saleId;
  final String status;
  final List<SaleOpenTicketBatchDto> batches;
  final double payableUsdExact;
  final double payableKhrExact;
}

class SaleReceiptLineDto {
  const SaleReceiptLineDto({
    required this.name,
    required this.quantity,
    required this.unitPriceUsd,
    required this.lineTotalUsdExact,
    this.modifiers = const <SaleReceiptModifierLineDto>[],
  });

  final String name;
  final int quantity;
  final double unitPriceUsd;
  final double lineTotalUsdExact;
  final List<SaleReceiptModifierLineDto> modifiers;
}

class SaleReceiptModifierLineDto {
  const SaleReceiptModifierLineDto({
    required this.name,
    this.priceDeltaUsd = 0,
  });

  final String name;
  final double priceDeltaUsd;
}

class SaleReceiptDto {
  const SaleReceiptDto({
    required this.saleId,
    required this.receiptNumber,
    required this.paymentMethod,
    required this.subtotalUsdExact,
    required this.taxUsdExact,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.issuedAt,
    required this.lines,
  });

  final String saleId;
  final String receiptNumber;
  final String paymentMethod;
  final double subtotalUsdExact;
  final double taxUsdExact;
  final double totalUsdExact;
  final double totalKhrExact;
  final DateTime issuedAt;
  final List<SaleReceiptLineDto> lines;
}

abstract class SaleCartRepository {
  // Legacy draft/cart mutation methods still used by the existing cart UI.
  Future<String> ensureDraft({
    String? clientUuid,
    required String saleType,
    double fxRateUsed = 4100,
  });

  Future<String?> addItem({
    required String saleId,
    required SaleDraftItemInputDto item,
  });

  Future<void> updateItemQuantity({
    required String saleId,
    required String itemId,
    required int quantity,
  });

  Future<void> removeItem({required String saleId, required String itemId});

  Future<SaleKhqrAttemptDto> generateKhqrAttempt(
    SaleGenerateKhqrAttemptCommand command,
  );

  Future<SaleKhqrStatusDto> checkKhqrStatus(SaleCheckKhqrStatusCommand command);

  Future<SaleKhqrStatusDto> cancelKhqrAttempt(
    SaleCancelKhqrAttemptCommand command,
  );

  Future<SaleFinalizeSaleResultDto> finalizeSale(
    SaleFinalizeSaleCommand command,
  );

  Future<SalePlaceOrderResultDto> placeOrder(SalePlaceOrderCommand command);

  Future<SaleOpenTicketDetailDto> getOpenTicketDetail({required String saleId});

  Future<SaleReceiptDto> getReceipt({required String saleId});
}

abstract class SaleCheckoutRepository implements SaleCartRepository {
  Future<SaleCheckoutSummary> preCheckout({
    required String saleId,
    required String tenderCurrency,
    required String paymentMethod,
    Map<String, num>? cashReceived,
  });

  Future<SaleCheckoutSummary> finalize(String saleId);

  Future<void> updateFulfillmentStatus({
    required String saleId,
    required String status,
  });

  Future<List<Sale>> listSales({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  });

  Future<void> voidSale(String saleId, {required String reason});

  Future<SaleContextDto> getSaleContext({required String branchId});

  Future<SaleCheckoutPreviewDto> computeCheckoutPreview(
    SaleComputeCheckoutPreviewCommand command,
  );

  Future<SaleAddItemsToOpenTicketResultDto> addItemsToOpenTicket(
    SaleAddItemsToOpenTicketCommand command,
  );

  Future<SaleCheckoutOpenTicketResultDto> checkoutOpenTicket(
    SaleCheckoutOpenTicketCommand command,
  );

  Future<SaleCancelOpenTicketResultDto> cancelOpenTicket(
    SaleCancelOpenTicketCommand command,
  );

  Future<SaleOrdersPageDto> getOrders(SaleOrdersQueryDto query);
}
