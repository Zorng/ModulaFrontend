class DiscountErrorCodes {
  const DiscountErrorCodes._();

  static const tenantContextRequired = 'TENANT_CONTEXT_REQUIRED';
  static const branchContextRequired = 'BRANCH_CONTEXT_REQUIRED';
  static const ruleNotFound = 'DISCOUNT_RULE_NOT_FOUND';
  static const overlapWarning = 'DISCOUNT_RULE_OVERLAP_WARNING';
  static const updateRequiresEffectiveInactive =
      'DISCOUNT_RULE_UPDATE_REQUIRES_EFFECTIVE_INACTIVE';
  static const ruleInvalid = 'DISCOUNT_RULE_INVALID';
  static const scopeInvalid = 'DISCOUNT_SCOPE_INVALID';
  static const percentageOutOfRange = 'DISCOUNT_PERCENTAGE_OUT_OF_RANGE';
  static const itemAssignmentRequired = 'DISCOUNT_ITEM_ASSIGNMENT_REQUIRED';
  static const offlineUnreachable = 'OFFLINE_UNREACHABLE';

  static const knownCodes = <String>{
    tenantContextRequired,
    branchContextRequired,
    ruleNotFound,
    overlapWarning,
    updateRequiresEffectiveInactive,
    ruleInvalid,
    scopeInvalid,
    percentageOutOfRange,
    itemAssignmentRequired,
    offlineUnreachable,
  };

  static String? normalize(String? code) {
    final normalized = (code ?? '').trim().toUpperCase();
    if (normalized.isEmpty) return null;
    if (knownCodes.contains(normalized)) return normalized;
    return normalized;
  }
}
