class PolicyErrorCodes {
  const PolicyErrorCodes._();

  static const tenantContextRequired = 'TENANT_CONTEXT_REQUIRED';
  static const branchContextRequired = 'BRANCH_CONTEXT_REQUIRED';
  static const noMembership = 'NO_MEMBERSHIP';
  static const noBranchAccess = 'NO_BRANCH_ACCESS';
  static const permissionDenied = 'PERMISSION_DENIED';
  static const branchFrozen = 'BRANCH_FROZEN';
  static const subscriptionFrozen = 'SUBSCRIPTION_FROZEN';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const idempotencyInProgress = 'IDEMPOTENCY_IN_PROGRESS';
  static const policyPatchEmpty = 'POLICY_PATCH_EMPTY';
  static const policyValidationFailed = 'POLICY_VALIDATION_FAILED';
  static const offlineUnreachable = 'OFFLINE_UNREACHABLE';

  static const knownCodes = <String>{
    tenantContextRequired,
    branchContextRequired,
    noMembership,
    noBranchAccess,
    permissionDenied,
    branchFrozen,
    subscriptionFrozen,
    idempotencyConflict,
    idempotencyInProgress,
    policyPatchEmpty,
    policyValidationFailed,
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
