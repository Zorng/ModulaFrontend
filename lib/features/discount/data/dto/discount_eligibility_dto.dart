class DiscountEligibilityRuleDto {
  const DiscountEligibilityRuleDto({
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

  factory DiscountEligibilityRuleDto.fromJson(Map<String, dynamic> json) {
    return DiscountEligibilityRuleDto(
      ruleId: json['ruleId']?.toString() ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      scope: json['scope']?.toString() ?? '',
      itemIds: (json['itemIds'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      stackingPolicy: json['stackingPolicy']?.toString() ?? 'MULTIPLICATIVE',
    );
  }
}
