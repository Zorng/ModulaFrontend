class DiscountItemPreflightResult {
  const DiscountItemPreflightResult({
    required this.branchId,
    required this.eligibleItemIds,
    required this.invalidItemIds,
    required this.allEligible,
  });

  final String branchId;
  final List<String> eligibleItemIds;
  final List<String> invalidItemIds;
  final bool allEligible;
}
