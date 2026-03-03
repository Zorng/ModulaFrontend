class BranchStockProjectionDto {
  const BranchStockProjectionDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.stockItemId,
    required this.onHandInBaseUnit,
    required this.lastMovementAt,
    required this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String branchId;
  final String stockItemId;
  final int onHandInBaseUnit;
  final String lastMovementAt;
  final String updatedAt;

  factory BranchStockProjectionDto.fromJson(Map<String, dynamic> json) {
    final branchId = (json['branchId'] ?? '').toString();
    final stockItemId = (json['stockItemId'] ?? '').toString();
    final generatedId = branchId.isNotEmpty && stockItemId.isNotEmpty
        ? '$branchId:$stockItemId'
        : '';
    final id = (json['id'] ?? generatedId).toString();
    return BranchStockProjectionDto(
      id: id,
      tenantId: (json['tenantId'] ?? '').toString(),
      branchId: branchId,
      stockItemId: stockItemId,
      onHandInBaseUnit:
          _asInt(
            json['onHandInBaseUnit'] ??
                json['resultingOnHandInBaseUnit'] ??
                json['onHand'],
          ) ??
          0,
      lastMovementAt:
          (json['lastMovementAt'] ??
                  json['occurredAt'] ??
                  json['updatedAt'] ??
                  '')
              .toString(),
      updatedAt: (json['updatedAt'] ?? json['lastMovementAt'] ?? '').toString(),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
