class BranchErrorCodes {
  const BranchErrorCodes._();

  static const branchContextRequired = 'BRANCH_CONTEXT_REQUIRED';
  static const noBranchAccess = 'NO_BRANCH_ACCESS';
  static const orgBranchKhqrReceiverInvalid =
      'ORG_BRANCH_KHQR_RECEIVER_INVALID';
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

  static const currentBranchCodes = <String>{
    branchContextRequired,
    noBranchAccess,
  };

  static const khqrReceiverCodes = <String>{
    branchContextRequired,
    noBranchAccess,
    orgBranchKhqrReceiverInvalid,
  };

  static bool isInitiateCode(String? code) =>
      initiateCodes.contains((code ?? '').trim().toUpperCase());

  static bool isConfirmCode(String? code) =>
      confirmCodes.contains((code ?? '').trim().toUpperCase());

  static bool isCurrentBranchCode(String? code) =>
      currentBranchCodes.contains(normalize(code));

  static bool isKhqrReceiverCode(String? code) =>
      khqrReceiverCodes.contains(normalize(code));

  static String? normalize(String? code) {
    final raw = (code ?? '').trim();
    if (raw.isEmpty) return null;
    final canonical = raw
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .trim()
        .toUpperCase();
    switch (canonical) {
      case 'BRANCH_CONTEXT_REQUIRED':
        return branchContextRequired;
      case 'NO_BRANCH_ACCESS':
        return noBranchAccess;
      case 'ORG_BRANCH_KHQR_RECEIVER_INVALID':
        return orgBranchKhqrReceiverInvalid;
      case 'SUBSCRIPTION_UPGRADE_REQUIRED':
        return subscriptionUpgradeRequired;
      case 'FAIRUSE_HARD_LIMIT_EXCEEDED':
        return fairUseHardLimitExceeded;
      case 'FAIRUSE_RATE_LIMITED':
        return fairUseRateLimited;
      case 'IDEMPOTENCY_CONFLICT':
        return idempotencyConflict;
      case 'IDEMPOTENCY_IN_PROGRESS':
        return idempotencyInProgress;
      case 'BRANCH_ACTIVATION_PAYMENT_REQUIRED':
        return branchActivationPaymentRequired;
      case 'DRAFT_NOT_PENDING_PAYMENT':
        return draftNotPendingPayment;
      case 'INVOICE_NOT_PAYABLE':
        return invoiceNotPayable;
      case 'DRAFT_NOT_FOUND':
        return draftNotFound;
      default:
        return canonical;
    }
  }
}
