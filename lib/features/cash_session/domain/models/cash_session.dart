class CashSession {
  const CashSession({
    required this.id,
    required this.status,
    required this.openedAt,
    required this.closedAt,
    required this.openingFloatUsd,
    required this.openingFloatKhr,
    required this.totalPaidInUsd,
    required this.totalPaidOutUsd,
    required this.ownerId,
  });

  final String id;
  final String status;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final double openingFloatUsd;
  final double openingFloatKhr;
  final double totalPaidInUsd;
  final double totalPaidOutUsd;
  final String? ownerId;
}

