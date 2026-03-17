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
          (json['selectedOptionIds'] as Map<String, dynamic>?)
              ?.map(
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
    String? backendOrderId,
    DateTime? materializedAt,
    String? claimedPaymentMethod,
    double? claimedTenderAmount,
    String? proofImageUrl,
    String? customerReference,
    String? note,
    DateTime? claimRecordedAt,
    String? backendClaimId,
    DateTime? claimSubmittedAt,
    String? lastErrorCode,
    String? lastErrorMessage,
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
      state: state == null ? this.state : SaleOutageOrderStates.normalize(state),
      sourceMode: sourceMode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      backendOrderId: backendOrderId ?? this.backendOrderId,
      materializedAt: materializedAt ?? this.materializedAt,
      claimedPaymentMethod:
          claimedPaymentMethod ?? this.claimedPaymentMethod,
      claimedTenderAmount: claimedTenderAmount ?? this.claimedTenderAmount,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      customerReference: customerReference ?? this.customerReference,
      note: note ?? this.note,
      claimRecordedAt: claimRecordedAt ?? this.claimRecordedAt,
      backendClaimId: backendClaimId ?? this.backendClaimId,
      claimSubmittedAt: claimSubmittedAt ?? this.claimSubmittedAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
    );
  }
}
