class CashMovementTypes {
  const CashMovementTypes._();

  static const saleIn = 'SALE_IN';
  static const refundCash = 'REFUND_CASH';
  static const manualIn = 'MANUAL_IN';
  static const manualOut = 'MANUAL_OUT';
  static const adjustment = 'ADJUSTMENT';

  static const values = <String>{
    saleIn,
    refundCash,
    manualIn,
    manualOut,
    adjustment,
  };

  static String normalize(String? value) {
    final normalized = (value ?? '').trim().toUpperCase().replaceAll('-', '_');
    if (values.contains(normalized)) return normalized;
    return manualIn;
  }
}

class CashMovement {
  CashMovement({
    required this.id,
    required this.sessionId,
    required this.tenantId,
    required this.branchId,
    required String movementType,
    required this.amountUsd,
    required this.amountKhr,
    required this.reason,
    required this.sourceRefType,
    required this.sourceRefId,
    required this.recordedByAccountId,
    required this.occurredAt,
  }) : movementType = CashMovementTypes.normalize(movementType);

  final String id;
  final String sessionId;
  final String tenantId;
  final String branchId;
  final String movementType;
  final double amountUsd;
  final double amountKhr;
  final String? reason;
  final String sourceRefType;
  final String? sourceRefId;
  final String recordedByAccountId;
  final DateTime? occurredAt;
}
