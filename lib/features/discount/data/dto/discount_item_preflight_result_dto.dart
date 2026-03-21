class DiscountItemPreflightResultDto {
  const DiscountItemPreflightResultDto({
    required this.branchId,
    required this.eligibleItemIds,
    required this.invalidItemIds,
    required this.allEligible,
  });

  final String branchId;
  final List<String> eligibleItemIds;
  final List<String> invalidItemIds;
  final bool allEligible;

  factory DiscountItemPreflightResultDto.fromJson(Map<String, dynamic> json) {
    List<String> parseIds(dynamic raw) {
      if (raw is! List) return const <String>[];
      return raw
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }

    return DiscountItemPreflightResultDto(
      branchId: json['branchId']?.toString() ?? '',
      eligibleItemIds: parseIds(json['eligibleItemIds']),
      invalidItemIds: parseIds(json['invalidItemIds']),
      allEligible: json['allEligible'] == true,
    );
  }
}
