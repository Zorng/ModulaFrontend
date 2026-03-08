class SaleKhqrUiStates {
  const SaleKhqrUiStates._();

  static const readyToGenerate = 'READY_TO_GENERATE';
  static const waitingForPayment = 'WAITING_FOR_PAYMENT';
  static const paidConfirmed = 'PAID_CONFIRMED';
  static const cancelled = 'CANCELLED';
  static const expired = 'EXPIRED';
  static const pendingConfirmation = 'PENDING_CONFIRMATION';
  static const superseded = 'SUPERSEDED';

  static String normalize(String status) {
    final upper = status.trim().toUpperCase();
    switch (upper) {
      case waitingForPayment:
      case paidConfirmed:
      case cancelled:
      case expired:
      case pendingConfirmation:
      case superseded:
      case readyToGenerate:
        return upper;
      default:
        return readyToGenerate;
    }
  }

  static String? toFoundationStatus(String status) {
    final normalized = normalize(status);
    return switch (normalized) {
      waitingForPayment => waitingForPayment,
      pendingConfirmation => pendingConfirmation,
      paidConfirmed => paidConfirmed,
      cancelled => cancelled,
      expired => expired,
      superseded => superseded,
      readyToGenerate => null,
      _ => null,
    };
  }
}

bool saleKhqrCanFinalize(String status) =>
    SaleKhqrUiStates.normalize(status) == SaleKhqrUiStates.paidConfirmed;

bool saleKhqrIsActiveAttempt(String status) {
  final normalized = SaleKhqrUiStates.normalize(status);
  return normalized == SaleKhqrUiStates.waitingForPayment ||
      normalized == SaleKhqrUiStates.pendingConfirmation ||
      normalized == SaleKhqrUiStates.paidConfirmed;
}

bool saleKhqrNeedsRegenerate(String status) {
  final normalized = SaleKhqrUiStates.normalize(status);
  return normalized == SaleKhqrUiStates.cancelled ||
      normalized == SaleKhqrUiStates.expired ||
      normalized == SaleKhqrUiStates.superseded;
}
