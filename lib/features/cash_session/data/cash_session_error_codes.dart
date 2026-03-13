class CashSessionErrorCodes {
  const CashSessionErrorCodes._();

  static const cashSessionAlreadyOpen = 'CASH_SESSION_ALREADY_OPEN';
  static const cashSessionNotFound = 'CASH_SESSION_NOT_FOUND';
  static const cashSessionNotOpen = 'CASH_SESSION_NOT_OPEN';
  static const cashSessionAlreadyClosed = 'CASH_SESSION_ALREADY_CLOSED';
  static const cashSessionUnpaidTicketsExist =
      'CASH_SESSION_UNPAID_TICKETS_EXIST';
  static const cashSessionForbiddenSelfScope =
      'CASH_SESSION_FORBIDDEN_SELF_SCOPE';
  static const idempotencyKeyRequired = 'IDEMPOTENCY_KEY_REQUIRED';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const idempotencyInProgress = 'IDEMPOTENCY_IN_PROGRESS';
  static const offlineUnreachable = 'OFFLINE_UNREACHABLE';

  static const knownCodes = <String>{
    cashSessionAlreadyOpen,
    cashSessionNotFound,
    cashSessionNotOpen,
    cashSessionAlreadyClosed,
    cashSessionUnpaidTicketsExist,
    cashSessionForbiddenSelfScope,
    idempotencyKeyRequired,
    idempotencyConflict,
    idempotencyInProgress,
    offlineUnreachable,
  };

  static String? normalize(String? code) {
    final normalized = (code ?? '').trim().toUpperCase();
    if (normalized.isEmpty) return null;
    if (knownCodes.contains(normalized)) return normalized;
    return normalized;
  }

  static bool isOffline(String? code) {
    return normalize(code) == offlineUnreachable;
  }
}
