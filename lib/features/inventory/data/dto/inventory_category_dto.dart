import 'package:modular_pos/features/inventory/domain/models/inventory_status.dart';

class InventoryCategoryDto {
  const InventoryCategoryDto({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String name;
  final InventoryStatus status;
  final String createdAt;
  final String updatedAt;

  bool get isActive => status.isActive;

  factory InventoryCategoryDto.fromJson(Map<String, dynamic> json) {
    final statusRaw =
        json['status']?.toString() ??
        (_asBool(json['isActive'], fallback: true) ? 'ACTIVE' : 'ARCHIVED');

    return InventoryCategoryDto(
      id: json['id']?.toString() ?? '',
      tenantId:
          json['tenantId']?.toString() ?? json['tenant_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Category',
      status: inventoryStatusFromRaw(statusRaw),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
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
