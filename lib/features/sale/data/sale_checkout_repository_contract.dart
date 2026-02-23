import 'package:modular_pos/features/sale/domain/models/sale.dart';

class SaleCheckoutReasonCodes {
  static const unauthorized = 'UNAUTHORIZED';
  static const branchRequired = 'BRANCH_REQUIRED';
  static const branchFrozen = 'BRANCH_FROZEN';
  static const cashSessionRequired = 'CASH_SESSION_REQUIRED';
  static const payLaterDisabled = 'PAY_LATER_DISABLED';
  static const khqrNotConfirmed = 'KHQR_NOT_CONFIRMED';
  static const duplicateOperation = 'DUPLICATE_OPERATION';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const invalidRequest = 'INVALID_REQUEST';
  static const offlineUnreachable = 'OFFLINE_UNREACHABLE';
  static const unknownError = 'UNKNOWN_ERROR';
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
    required this.branchId,
    required this.saleType,
    required this.paymentMethod,
    required this.tenderCurrency,
    required this.cartLines,
    this.cashReceived,
  });

  final String saleId;
  final String branchId;
  final String saleType;
  final String paymentMethod;
  final String tenderCurrency;
  final List<SaleCartLineInputDto> cartLines;
  final SaleCashReceivedInputDto? cashReceived;

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'branch_id': branchId,
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
  });

  final String saleId;
  final String tenderCurrency;
  final String clientOpId;

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'tender_currency': tenderCurrency,
      'client_op_id': clientOpId,
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
  final String? reasonCode;
  final String? reasonMessage;
}

class SaleCheckKhqrStatusCommand {
  const SaleCheckKhqrStatusCommand({required this.saleId, required this.md5});

  final String saleId;
  final String md5;

  Map<String, dynamic> toJson() {
    return {'sale_id': saleId, 'md5': md5};
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
    required this.branchId,
    required this.paymentMethod,
    required this.tenderCurrency,
    required this.clientOpId,
    this.cashReceived,
    this.khqrMd5,
  });

  final String saleId;
  final String branchId;
  final String paymentMethod;
  final String tenderCurrency;
  final String clientOpId;
  final SaleCashReceivedInputDto? cashReceived;
  final String? khqrMd5;

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'branch_id': branchId,
      'payment_method': paymentMethod,
      'tender_currency': tenderCurrency,
      'client_op_id': clientOpId,
      if (cashReceived != null) 'cash_received': cashReceived!.toJson(),
      if (khqrMd5 != null) 'khqr_md5': khqrMd5,
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
    this.orderId,
    this.receiptId,
    this.reasonCode,
    this.reasonMessage,
  });

  final String saleId;
  final String status;
  final double totalUsdExact;
  final double totalKhrExact;
  final bool idempotentReplay;
  final String? orderId;
  final String? receiptId;
  final String? reasonCode;
  final String? reasonMessage;
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
  });

  final String name;
  final int quantity;
  final double unitPriceUsd;
  final double lineTotalUsdExact;
}

class SaleReceiptDto {
  const SaleReceiptDto({
    required this.saleId,
    required this.receiptNumber,
    required this.paymentMethod,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.issuedAt,
    required this.lines,
  });

  final String saleId;
  final String receiptNumber;
  final String paymentMethod;
  final double totalUsdExact;
  final double totalKhrExact;
  final DateTime issuedAt;
  final List<SaleReceiptLineDto> lines;
}

abstract class SaleCheckoutRepository {
  // Legacy sale mutations currently used by existing pages/viewmodels.
  Future<String> ensureDraft({
    String? clientUuid,
    required String saleType,
    double fxRateUsed = 4100,
  });

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
  });

  Future<void> updateItemQuantity({
    required String saleId,
    required String itemId,
    required int quantity,
  });

  Future<void> removeItem({required String saleId, required String itemId});

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

  // FE-SALE-01 checkout contract.
  Future<SaleContextDto> getSaleContext({required String branchId});

  Future<SaleCheckoutPreviewDto> computeCheckoutPreview(
    SaleComputeCheckoutPreviewCommand command,
  );

  Future<SaleKhqrAttemptDto> generateKhqrAttempt(
    SaleGenerateKhqrAttemptCommand command,
  );

  Future<SaleKhqrStatusDto> checkKhqrStatus(SaleCheckKhqrStatusCommand command);

  Future<SaleFinalizeSaleResultDto> finalizeSale(
    SaleFinalizeSaleCommand command,
  );

  Future<SalePlaceOrderResultDto> placeOrder(SalePlaceOrderCommand command);

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

  Future<SaleOpenTicketDetailDto> getOpenTicketDetail({required String saleId});

  Future<SaleReceiptDto> getReceipt({required String saleId});
}
