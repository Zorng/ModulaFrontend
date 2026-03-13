import 'package:modular_pos/features/inventory/domain/models/inventory_status.dart';

class RestockBatchDto {
  const RestockBatchDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.stockItemId,
    required this.quantityInBaseUnit,
    required this.status,
    required this.receivedAt,
    required this.expiryDate,
    required this.supplierName,
    required this.purchaseCostUsd,
    required this.note,
    required this.createdByAccountId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String branchId;
  final String stockItemId;
  final int quantityInBaseUnit;
  final InventoryStatus status;
  final String receivedAt;
  final String? expiryDate;
  final String? supplierName;
  final double? purchaseCostUsd;
  final String? note;
  final String createdByAccountId;
  final String createdAt;
  final String updatedAt;

  bool get isActive => status.isActive;

  factory RestockBatchDto.fromJson(Map<String, dynamic> json) {
    final statusRaw =
        json['status']?.toString() ??
        (((json['isActive'] as bool?) ?? true) ? 'ACTIVE' : 'ARCHIVED');
    return RestockBatchDto(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      stockItemId: json['stockItemId']?.toString() ?? '',
      quantityInBaseUnit:
          _asInt(json['quantityInBaseUnit'] ?? json['qty'] ?? 0) ?? 0,
      status: inventoryStatusFromRaw(statusRaw),
      receivedAt:
          json['receivedAt']?.toString() ??
          json['receivedDate']?.toString() ??
          json['createdAt']?.toString() ??
          '',
      expiryDate: _nullableText(json['expiryDate']),
      supplierName: _nullableText(json['supplierName']),
      purchaseCostUsd: _asDouble(json['purchaseCostUsd']),
      note: _nullableText(json['note']),
      createdByAccountId: json['createdByAccountId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt:
          json['updatedAt']?.toString() ?? json['createdAt']?.toString() ?? '',
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _nullableText(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return text;
}
