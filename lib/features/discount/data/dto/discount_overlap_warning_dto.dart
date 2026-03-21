class DiscountOverlapWarningDto {
  const DiscountOverlapWarningDto({
    required this.code,
    required this.message,
    required this.conflictingRuleIds,
  });

  final String code;
  final String message;
  final List<String> conflictingRuleIds;

  factory DiscountOverlapWarningDto.fromJson(Map<String, dynamic> json) {
    final ids =
        (json['conflictingRuleIds'] as List<dynamic>? ??
                json['conflicts'] as List<dynamic>? ??
                const <dynamic>[])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);

    return DiscountOverlapWarningDto(
      code: json['code']?.toString() ?? 'DISCOUNT_RULE_OVERLAP_WARNING',
      message:
          json['message']?.toString() ??
          'Discount rule overlaps with an existing rule.',
      conflictingRuleIds: ids,
    );
  }
}
