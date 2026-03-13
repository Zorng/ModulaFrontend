class MenuCategoryDto {
  const MenuCategoryDto({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.status,
    required this.description,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String name;
  final String status;
  final String description;
  // Legacy alias kept for compatibility until mapper/domain refactor is finished.
  final bool isActive;
  final int? displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MenuCategoryDto.fromJson(Map<String, dynamic> json) {
    final normalizedStatus = _normalizeStatus(
      json['status']?.toString(),
      fallbackIsActive: _asBool(json['isActive'], fallback: true),
    );

    return MenuCategoryDto(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Category',
      status: normalizedStatus,
      description: json['description']?.toString() ?? '',
      isActive: normalizedStatus != 'ARCHIVED',
      displayOrder: _asInt(json['displayOrder']),
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
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

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String _normalizeStatus(String? value, {required bool fallbackIsActive}) {
  final raw = (value ?? '').trim().toUpperCase();
  if (raw == 'ACTIVE' || raw == 'ARCHIVED') return raw;
  return fallbackIsActive ? 'ACTIVE' : 'ARCHIVED';
}
