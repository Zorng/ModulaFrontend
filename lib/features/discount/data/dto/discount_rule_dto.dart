class DiscountRuleDto {
  const DiscountRuleDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.name,
    required this.percentage,
    required this.scope,
    required this.status,
    required this.itemIds,
    required this.schedule,
    required this.stackingPolicy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String branchId;
  final String name;
  final double percentage;
  final String scope;
  final String status;
  final List<String> itemIds;
  final DiscountRuleScheduleDto schedule;
  final String stackingPolicy;
  final String? createdAt;
  final String? updatedAt;

  factory DiscountRuleDto.fromJson(Map<String, dynamic> json) {
    final rawPercentage =
        json['percentage'] ?? json['value'] ?? json['percent'] ?? 0;
    final itemIds = (json['itemIds'] as List<dynamic>? ?? const <dynamic>[])
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);

    return DiscountRuleDto(
      id: json['id']?.toString() ?? json['discountRuleId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      percentage: rawPercentage is num
          ? rawPercentage.toDouble()
          : double.tryParse(rawPercentage.toString()) ?? 0,
      scope: json['scope']?.toString() ?? 'ITEM',
      status: json['status']?.toString() ?? 'INACTIVE',
      itemIds: itemIds,
      schedule: DiscountRuleScheduleDto.fromJson(json['schedule']),
      stackingPolicy: json['stackingPolicy']?.toString() ?? 'MULTIPLICATIVE',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class DiscountRuleScheduleDto {
  const DiscountRuleScheduleDto({required this.startAt, required this.endAt});

  final String? startAt;
  final String? endAt;

  factory DiscountRuleScheduleDto.fromJson(dynamic json) {
    final source = json is Map<String, dynamic> ? json : <String, dynamic>{};
    return DiscountRuleScheduleDto(
      startAt: source['startAt']?.toString(),
      endAt: source['endAt']?.toString(),
    );
  }
}
