class SaleDiscountResolveLine {
  const SaleDiscountResolveLine({
    required this.menuItemId,
    required this.quantity,
  });

  final String menuItemId;
  final int quantity;
}

class SaleResolvedDiscountRule {
  const SaleResolvedDiscountRule({
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

  bool get isItemLevel => scope == 'ITEM';
  bool get isBranchWide => scope == 'BRANCH_WIDE';

  bool appliesToMenuItem(String menuItemId) {
    if (!isItemLevel) return false;
    return itemIds.contains(menuItemId);
  }
}

class SaleResolvedDiscountSet {
  const SaleResolvedDiscountSet({
    required this.branchId,
    required this.occurredAt,
    required this.rules,
  });

  final String branchId;
  final DateTime occurredAt;
  final List<SaleResolvedDiscountRule> rules;

  List<SaleResolvedDiscountRule> get branchWideRules {
    return rules.where((rule) => rule.isBranchWide).toList(growable: false);
  }

  List<SaleResolvedDiscountRule> rulesForMenuItem(String menuItemId) {
    return rules
        .where(
          (rule) => rule.isBranchWide || rule.appliesToMenuItem(menuItemId),
        )
        .toList(growable: false);
  }
}
