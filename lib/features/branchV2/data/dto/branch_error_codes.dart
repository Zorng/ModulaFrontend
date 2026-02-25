class BranchErrorCodes {
  const BranchErrorCodes._();

  static const subscriptionUpgradeRequired = 'SUBSCRIPTION_UPGRADE_REQUIRED';
  static const fairUseHardLimitExceeded = 'FAIRUSE_HARD_LIMIT_EXCEEDED';
  static const fairUseRateLimited = 'FAIRUSE_RATE_LIMITED';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const idempotencyInProgress = 'IDEMPOTENCY_IN_PROGRESS';

  static const branchActivationPaymentRequired =
      'BRANCH_ACTIVATION_PAYMENT_REQUIRED';
  static const draftNotPendingPayment = 'DRAFT_NOT_PENDING_PAYMENT';
  static const invoiceNotPayable = 'INVOICE_NOT_PAYABLE';
  static const draftNotFound = 'DRAFT_NOT_FOUND';

  static const initiateCodes = <String>{
    subscriptionUpgradeRequired,
    fairUseHardLimitExceeded,
    fairUseRateLimited,
    idempotencyConflict,
    idempotencyInProgress,
  };

  static const confirmCodes = <String>{
    branchActivationPaymentRequired,
    draftNotPendingPayment,
    invoiceNotPayable,
    draftNotFound,
    idempotencyConflict,
    idempotencyInProgress,
  };

  static bool isInitiateCode(String? code) =>
      initiateCodes.contains((code ?? '').trim().toUpperCase());

  static bool isConfirmCode(String? code) =>
      confirmCodes.contains((code ?? '').trim().toUpperCase());
}
