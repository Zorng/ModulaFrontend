class DiscountEligibilityLineInput {
  const DiscountEligibilityLineInput({
    required this.menuItemId,
    required this.quantity,
  });

  final String menuItemId;
  final int quantity;
}

class DiscountEligibilityRule {
  const DiscountEligibilityRule({
    required this.ruleId,
    required this.percentage,
    required this.scope,
    required this.itemIds,
    required this.stackingPolicy,
  });

  final String ruleId;
  final double percentage;
  final String scope;
  final List<String> itemIds;
  final String stackingPolicy;
}
