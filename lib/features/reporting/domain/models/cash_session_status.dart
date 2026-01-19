enum CashSessionStatus { open, closed, pendingReview, approved, unknown }

CashSessionStatus cashSessionStatusFromApi(String? raw) {
  final value = raw?.trim().toUpperCase() ?? '';
  return switch (value) {
    'OPEN' => CashSessionStatus.open,
    'CLOSED' => CashSessionStatus.closed,
    'PENDING_REVIEW' => CashSessionStatus.pendingReview,
    'APPROVED' => CashSessionStatus.approved,
    _ => CashSessionStatus.unknown,
  };
}

extension CashSessionStatusX on CashSessionStatus {
  String get label => switch (this) {
    CashSessionStatus.open => 'Open',
    CashSessionStatus.closed => 'Closed',
    CashSessionStatus.pendingReview => 'Pending review',
    CashSessionStatus.approved => 'Approved',
    CashSessionStatus.unknown => 'Unknown',
  };

  bool get isOpen => this == CashSessionStatus.open;
}
