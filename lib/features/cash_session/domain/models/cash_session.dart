class CashSessionStatuses {
  const CashSessionStatuses._();

  static const open = 'OPEN';
  static const closed = 'CLOSED';
  static const forceClosed = 'FORCE_CLOSED';

  static const values = <String>{open, closed, forceClosed};

  static String normalize(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    if (values.contains(normalized)) return normalized;
    return open;
  }

  static bool isClosed(String? value) {
    final normalized = normalize(value);
    return normalized == closed || normalized == forceClosed;
  }
}

class CashSession {
  CashSession({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.openedByAccountId,
    required this.openedAt,
    required String status,
    required this.openingFloatUsd,
    required this.openingFloatKhr,
    required this.closedAt,
    required this.closedByAccountId,
    required this.closeNote,
    required this.totalPaidInUsd,
    required this.totalPaidOutUsd,
  }) : status = CashSessionStatuses.normalize(status);

  final String id;
  final String tenantId;
  final String branchId;
  final String openedByAccountId;
  final DateTime? openedAt;
  final String status;
  final double openingFloatUsd;
  final double openingFloatKhr;
  final DateTime? closedAt;
  final String? closedByAccountId;
  final String? closeNote;
  final double totalPaidInUsd;
  final double totalPaidOutUsd;
}
