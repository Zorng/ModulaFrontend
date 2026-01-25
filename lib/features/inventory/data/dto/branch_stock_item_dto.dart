import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';

class BranchStockItemDto {
  const BranchStockItemDto({
    required this.stockItemId,
    required this.branchId,
    required this.branchName,
    required this.onHand,
    required this.minThreshold,
    required this.stockItem,
  });

  final String stockItemId;
  final String branchId;
  final String branchName;
  final int? onHand;
  final int? minThreshold;
  final StockItemDto stockItem;

  factory BranchStockItemDto.fromJson(
    Map<String, dynamic> json, {
    String? branchIdHint,
  }) {
    if (json.containsKey('stockItem') && json['stockItem'] is Map) {
      final itemMap = Map<String, dynamic>.from(json['stockItem'] as Map);
      final onHand = _asInt(json['onHand'] ?? json['qty'] ?? json['quantity']);
      final minThreshold = _asInt(json['minThreshold'] ?? json['threshold']);
      String branchId =
          (json['branchId'] ?? json['branch_id'] ?? '').toString();
      if (branchId.isEmpty && branchIdHint != null) {
        branchId = branchIdHint;
      }
      final branchName =
          (json['branchName'] ?? json['branch_name'] ?? '').toString();
      final stockItem = StockItemDto.fromJson(itemMap);
      return BranchStockItemDto(
        stockItemId: stockItem.id,
        branchId: branchId,
        branchName: branchName,
        onHand: onHand,
        minThreshold: minThreshold,
        stockItem: stockItem,
      );
    }

    final stockItem = StockItemDto.fromJson(json);
    String branchId =
        (json['branchId'] ?? json['branch_id'] ?? '').toString();
    if (branchId.isEmpty && branchIdHint != null) {
      branchId = branchIdHint;
    }
    final branchName =
        (json['branchName'] ?? json['branch_name'] ?? '').toString();
    final onHand = _asInt(json['onHand'] ?? json['qty'] ?? json['quantity']);
    final minThreshold = _asInt(json['minThreshold'] ?? json['threshold']);
    return BranchStockItemDto(
      stockItemId: stockItem.id,
      branchId: branchId,
      branchName: branchName,
      onHand: onHand,
      minThreshold: minThreshold,
      stockItem: stockItem,
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

