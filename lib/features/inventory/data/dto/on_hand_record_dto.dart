class OnHandRecordDto {
  const OnHandRecordDto({
    required this.stockItemId,
    required this.branchId,
    required this.onHand,
    required this.minThreshold,
  });

  final String stockItemId;
  final String branchId;
  final int? onHand;
  final int? minThreshold;

  factory OnHandRecordDto.fromJson(
    Map<String, dynamic> json, {
    String? branchIdHint,
  }) {
    final stockItemId = (json['stockItemId'] ??
            json['stock_item_id'] ??
            json['id'] ??
            '')
        .toString();
    var branchId = (json['branchId'] ?? json['branch_id'] ?? '').toString();
    if (branchId.isEmpty && branchIdHint != null && branchIdHint.isNotEmpty) {
      branchId = branchIdHint;
    }
    return OnHandRecordDto(
      stockItemId: stockItemId,
      branchId: branchId,
      onHand: _asInt(json['onHand'] ??
          json['onHandQty'] ??
          json['onHandExact'] ??
          json['quantity'] ??
          json['qty']),
      minThreshold: _asInt(json['minThreshold'] ?? json['threshold']),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

