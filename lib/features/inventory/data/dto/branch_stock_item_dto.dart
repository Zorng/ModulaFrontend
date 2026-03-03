import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';

class BranchStockItemDto {
  const BranchStockItemDto({
    required this.stockItemId,
    required this.stockItemName,
    required this.baseUnit,
    required this.branchId,
    required this.onHand,
    required this.minThreshold,
    required this.isLowStock,
    required this.updatedAt,
    required this.stockItem,
  });

  final String stockItemId;
  final String stockItemName;
  final String baseUnit;
  final String branchId;
  final int? onHand;
  final int? minThreshold;
  final bool isLowStock;
  final String updatedAt;
  final StockItemDto stockItem;

  factory BranchStockItemDto.fromJson(
    Map<String, dynamic> json, {
    String? branchIdHint,
  }) {
    if (json.containsKey('stockItem') && json['stockItem'] is Map) {
      final itemMap = Map<String, dynamic>.from(json['stockItem'] as Map);
      final stockItem = StockItemDto.fromJson(itemMap);
      final onHand =
          _asInt(
            json['onHandInBaseUnit'] ??
                json['onHand'] ??
                json['qty'] ??
                json['quantity'],
          ) ??
          0;
      final minThreshold =
          _asInt(json['lowStockThreshold']) ??
          _asInt(json['minThreshold']) ??
          _asInt(json['threshold']);
      String branchId = (json['branchId'] ?? json['branch_id'] ?? '')
          .toString();
      if (branchId.isEmpty && branchIdHint != null) {
        branchId = branchIdHint;
      }

      return BranchStockItemDto(
        stockItemId: stockItem.id,
        stockItemName: json['stockItemName']?.toString() ?? stockItem.name,
        baseUnit: json['baseUnit']?.toString() ?? stockItem.baseUnit,
        branchId: branchId,
        onHand: onHand,
        minThreshold: minThreshold,
        isLowStock:
            json['isLowStock'] as bool? ??
            ((minThreshold != null) ? onHand < minThreshold : false),
        updatedAt: json['updatedAt']?.toString() ?? '',
        stockItem: stockItem,
      );
    }

    final stockItemId =
        (json['stockItemId'] ?? json['stock_item_id'] ?? json['id'] ?? '')
            .toString();
    final stockItemName =
        json['stockItemName']?.toString() ?? json['name']?.toString() ?? 'Item';
    final baseUnit =
        json['baseUnit']?.toString() ?? json['unitText']?.toString() ?? 'pcs';

    final onHand =
        _asInt(
          json['onHandInBaseUnit'] ??
              json['onHand'] ??
              json['qty'] ??
              json['quantity'],
        ) ??
        0;
    final minThreshold =
        _asInt(json['lowStockThreshold']) ??
        _asInt(json['minThreshold']) ??
        _asInt(json['threshold']);

    String branchId = (json['branchId'] ?? json['branch_id'] ?? '').toString();
    if (branchId.isEmpty && branchIdHint != null) {
      branchId = branchIdHint;
    }

    final stockItem = StockItemDto.fromJson({
      ...json,
      'id': stockItemId,
      'name': stockItemName,
      'baseUnit': baseUnit,
      'lowStockThreshold': minThreshold,
    });

    return BranchStockItemDto(
      stockItemId: stockItemId,
      stockItemName: stockItemName,
      baseUnit: baseUnit,
      branchId: branchId,
      onHand: onHand,
      minThreshold: minThreshold,
      isLowStock:
          json['isLowStock'] as bool? ??
          ((minThreshold != null) ? onHand < minThreshold : false),
      updatedAt: json['updatedAt']?.toString() ?? '',
      stockItem: stockItem,
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
