import 'package:modular_pos/features/inventory/domain/models/inventory_status.dart';

class StockItemDto {
  const StockItemDto({
    required this.id,
    required this.tenantId,
    required this.categoryId,
    required this.name,
    required this.baseUnit,
    required this.imageUrl,
    required this.lowStockThreshold,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String? categoryId;
  final String name;
  final String baseUnit;
  final String? imageUrl;
  final int? lowStockThreshold;
  final InventoryStatus status;
  final String createdAt;
  final String updatedAt;

  bool get isActive => status.isActive;

  factory StockItemDto.fromJson(Map<String, dynamic> json) {
    final id =
        (json['id'] ?? json['stockItemId'] ?? json['stock_item_id'] ?? '')
            .toString();
    final categoryId =
        json['categoryId']?.toString() ?? json['category_id']?.toString();

    final statusRaw =
        json['status']?.toString() ??
        (_asBool(json['isActive'], fallback: true) ? 'ACTIVE' : 'ARCHIVED');

    return StockItemDto(
      id: id,
      tenantId:
          json['tenantId']?.toString() ?? json['tenant_id']?.toString() ?? '',
      categoryId: (categoryId == null || categoryId.isEmpty)
          ? null
          : categoryId,
      name: json['name']?.toString() ?? 'Item',
      baseUnit:
          json['baseUnit']?.toString() ?? json['unitText']?.toString() ?? 'pcs',
      imageUrl: _readImageUrl(json),
      lowStockThreshold:
          _asInt(json['lowStockThreshold']) ??
          _asInt(json['minThreshold']) ??
          _asInt(json['threshold']),
      status: inventoryStatusFromRaw(statusRaw),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

String? _readImageUrl(Map<String, dynamic> json) {
  final raw =
      json['imageUrl'] ??
      json['image_url'] ??
      json['image'] ??
      (json['image'] is Map ? (json['image'] as Map)['url'] : null);
  final trimmed = raw?.toString().trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

bool _asBool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.trim().toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
