class DiscountOverlapWarning {
  const DiscountOverlapWarning({
    required this.code,
    required this.message,
    this.conflictingRuleIds = const <String>[],
  });

  final String code;
  final String message;
  final List<String> conflictingRuleIds;

  bool get hasConflicts => conflictingRuleIds.isNotEmpty;
}
