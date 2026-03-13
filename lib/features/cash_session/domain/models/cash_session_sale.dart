class CashSessionSaleStatuses {
  const CashSessionSaleStatuses._();

  static const finalized = 'FINALIZED';
  static const voidPending = 'VOID_PENDING';
  static const voided = 'VOIDED';

  static const values = <String>{finalized, voidPending, voided};

  static String normalize(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    if (values.contains(normalized)) return normalized;
    return finalized;
  }
}

class CashSessionSale {
  CashSessionSale({
    required this.saleId,
    required String status,
    required this.paymentMethod,
    required this.saleType,
    required this.finalizedAt,
    required this.totalItems,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
    required this.cashierAccountId,
    required this.cashierName,
    required this.voidedAt,
  }) : status = CashSessionSaleStatuses.normalize(status);

  final String saleId;
  final String status;
  final String paymentMethod;
  final String saleType;
  final DateTime? finalizedAt;
  final int totalItems;
  final double grandTotalUsd;
  final double grandTotalKhr;
  final String cashierAccountId;
  final String cashierName;
  final DateTime? voidedAt;
}
