class SaleOutageOrderStates {
  static const localOpenOrderCaptured = 'LOCAL_OPEN_ORDER_CAPTURED';
  static const awaitingSettlement = 'AWAITING_SETTLEMENT';
  static const manualExternalPaymentClaimRecorded =
      'MANUAL_EXTERNAL_PAYMENT_CLAIM_RECORDED';
  static const settlementInProgress = 'SETTLEMENT_IN_PROGRESS';
  static const settledOnline = 'SETTLED_ONLINE';
  static const finalizationFailed = 'FINALIZATION_FAILED';

  static String normalize(String raw) {
    final normalized = raw.trim().toUpperCase();
    switch (normalized) {
      case localOpenOrderCaptured:
      case awaitingSettlement:
      case manualExternalPaymentClaimRecorded:
      case settlementInProgress:
      case settledOnline:
      case finalizationFailed:
        return normalized;
      default:
        return awaitingSettlement;
    }
  }
}

class SaleOutageErrorCodes {
  static const manualExternalPaymentClaimRejected =
      'ORDER_MANUAL_PAYMENT_CLAIM_REJECTED';
}

class SaleOutageSourceModes {
  static const standardOpenOrder = 'STANDARD_OPEN_ORDER';
  static const manualExternalPaymentClaim = 'MANUAL_EXTERNAL_PAYMENT_CLAIM';

  static String normalize(String raw) {
    final normalized = raw.trim().toUpperCase();
    switch (normalized) {
      case manualExternalPaymentClaim:
        return manualExternalPaymentClaim;
      case standardOpenOrder:
      default:
        return standardOpenOrder;
    }
  }
}

class SaleOutageLineSnapshot {
  const SaleOutageLineSnapshot({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.selectedOptionIds,
    required this.modifierLabels,
    required this.unitPriceUsd,
    required this.lineTotalUsdExact,
  });

  final String menuItemId;
  final String name;
  final int quantity;
  final Map<String, List<String>> selectedOptionIds;
  final List<String> modifierLabels;
  final double unitPriceUsd;
  final double lineTotalUsdExact;

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'selectedOptionIds': selectedOptionIds,
      'modifierLabels': modifierLabels,
      'unitPriceUsd': unitPriceUsd,
      'lineTotalUsdExact': lineTotalUsdExact,
    };
  }

  factory SaleOutageLineSnapshot.fromJson(Map<String, dynamic> json) {
    return SaleOutageLineSnapshot(
      menuItemId: json['menuItemId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      selectedOptionIds:
          (json['selectedOptionIds'] as Map<String, dynamic>?)?.map(
            (key, value) =>
                MapEntry(key, List<String>.from((value as List<dynamic>))),
          ) ??
          const <String, List<String>>{},
      modifierLabels:
          (json['modifierLabels'] as List<dynamic>?)
              ?.map((value) => value as String)
              .toList(growable: false) ??
          const <String>[],
      unitPriceUsd: (json['unitPriceUsd'] as num?)?.toDouble() ?? 0,
      lineTotalUsdExact: (json['lineTotalUsdExact'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SaleOutageOrderRecord {
  static const Object _unset = Object();

  const SaleOutageOrderRecord({
    required this.localIntentId,
    required this.orderNumber,
    required this.tenantId,
    required this.branchId,
    required this.accountId,
    required this.saleType,
    required this.paymentMethodRequested,
    required this.tenderCurrency,
    required this.cashReceivedUsd,
    required this.cashReceivedKhr,
    required this.totalUsd,
    required this.totalKhr,
    required this.lines,
    required this.state,
    required this.sourceMode,
    required this.createdAt,
    required this.updatedAt,
    this.backendOrderId,
    this.materializedAt,
    this.claimedPaymentMethod,
    this.claimedTenderAmount,
    this.proofImageUrl,
    this.customerReference,
    this.note,
    this.claimRecordedAt,
    this.backendClaimId,
    this.claimSubmittedAt,
    this.lastErrorCode,
    this.lastErrorMessage,
  });

  final String localIntentId;
  final String orderNumber;
  final String tenantId;
  final String branchId;
  final String accountId;
  final String saleType;
  final String paymentMethodRequested;
  final String tenderCurrency;
  final double cashReceivedUsd;
  final double cashReceivedKhr;
  final double totalUsd;
  final double totalKhr;
  final List<SaleOutageLineSnapshot> lines;
  final String state;
  final String sourceMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? backendOrderId;
  final DateTime? materializedAt;
  final String? claimedPaymentMethod;
  final double? claimedTenderAmount;
  final String? proofImageUrl;
  final String? customerReference;
  final String? note;
  final DateTime? claimRecordedAt;
  final String? backendClaimId;
  final DateTime? claimSubmittedAt;
  final String? lastErrorCode;
  final String? lastErrorMessage;

  bool get isAwaitingSettlement =>
      SaleOutageOrderStates.normalize(state) !=
      SaleOutageOrderStates.settledOnline;

  SaleOutageOrderRecord copyWith({
    String? state,
    Object? backendOrderId = _unset,
    Object? materializedAt = _unset,
    Object? claimedPaymentMethod = _unset,
    Object? claimedTenderAmount = _unset,
    Object? proofImageUrl = _unset,
    Object? customerReference = _unset,
    Object? note = _unset,
    Object? claimRecordedAt = _unset,
    Object? backendClaimId = _unset,
    Object? claimSubmittedAt = _unset,
    Object? lastErrorCode = _unset,
    Object? lastErrorMessage = _unset,
    DateTime? updatedAt,
  }) {
    return SaleOutageOrderRecord(
      localIntentId: localIntentId,
      orderNumber: orderNumber,
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      saleType: saleType,
      paymentMethodRequested: paymentMethodRequested,
      tenderCurrency: tenderCurrency,
      cashReceivedUsd: cashReceivedUsd,
      cashReceivedKhr: cashReceivedKhr,
      totalUsd: totalUsd,
      totalKhr: totalKhr,
      lines: lines,
      state: state == null
          ? this.state
          : SaleOutageOrderStates.normalize(state),
      sourceMode: sourceMode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      backendOrderId: identical(backendOrderId, _unset)
          ? this.backendOrderId
          : backendOrderId as String?,
      materializedAt: identical(materializedAt, _unset)
          ? this.materializedAt
          : materializedAt as DateTime?,
      claimedPaymentMethod: identical(claimedPaymentMethod, _unset)
          ? this.claimedPaymentMethod
          : claimedPaymentMethod as String?,
      claimedTenderAmount: identical(claimedTenderAmount, _unset)
          ? this.claimedTenderAmount
          : claimedTenderAmount as double?,
      proofImageUrl: identical(proofImageUrl, _unset)
          ? this.proofImageUrl
          : proofImageUrl as String?,
      customerReference: identical(customerReference, _unset)
          ? this.customerReference
          : customerReference as String?,
      note: identical(note, _unset) ? this.note : note as String?,
      claimRecordedAt: identical(claimRecordedAt, _unset)
          ? this.claimRecordedAt
          : claimRecordedAt as DateTime?,
      backendClaimId: identical(backendClaimId, _unset)
          ? this.backendClaimId
          : backendClaimId as String?,
      claimSubmittedAt: identical(claimSubmittedAt, _unset)
          ? this.claimSubmittedAt
          : claimSubmittedAt as DateTime?,
      lastErrorCode: identical(lastErrorCode, _unset)
          ? this.lastErrorCode
          : lastErrorCode as String?,
      lastErrorMessage: identical(lastErrorMessage, _unset)
          ? this.lastErrorMessage
          : lastErrorMessage as String?,
    );
  }
}
