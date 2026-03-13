class StockAggregateItemDto {
  const StockAggregateItemDto({
    required this.stockItemId,
    required this.stockItemName,
    required this.baseUnit,
    required this.totalOnHandInBaseUnit,
    required this.branchCount,
  });

  final String stockItemId;
  final String stockItemName;
  final String baseUnit;
  final int totalOnHandInBaseUnit;
  final int branchCount;

  factory StockAggregateItemDto.fromJson(Map<String, dynamic> json) {
    return StockAggregateItemDto(
      stockItemId: (json['stockItemId'] ?? json['id'] ?? '').toString(),
      stockItemName: (json['stockItemName'] ?? json['name'] ?? 'Item')
          .toString(),
      baseUnit: (json['baseUnit'] ?? json['unitText'] ?? 'pcs').toString(),
      totalOnHandInBaseUnit:
          _asInt(json['totalOnHandInBaseUnit'] ?? json['onHandInBaseUnit']) ??
          0,
      branchCount: _asInt(json['branchCount']) ?? 0,
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
