class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    this.tenantId = '',
    this.status = 'ACTIVE',
    this.description = '',
    this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String tenantId;
  final String status;
  final String description;
  final int? displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == 'ACTIVE';

  MenuCategory copyWith({
    String? id,
    String? name,
    String? tenantId,
    String? status,
    String? description,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final resolvedStatus = _normalizeStatus(
      status ?? this.status,
      fallbackIsActive: isActive,
    );

    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      tenantId: tenantId ?? this.tenantId,
      status: resolvedStatus,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    final resolvedStatus = _normalizeStatus(
      json['status']?.toString(),
      fallbackIsActive: _asBool(json['isActive'], fallback: true),
    );

    return MenuCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Category',
      tenantId: json['tenantId']?.toString() ?? '',
      status: resolvedStatus,
      description: json['description'] as String? ?? '',
      displayOrder: json['displayOrder'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tenantId': tenantId,
    'status': status,
    'description': description,
    'displayOrder': displayOrder,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  }..removeWhere((key, value) => value == null);
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

String _normalizeStatus(String? value, {required bool fallbackIsActive}) {
  final raw = (value ?? '').trim().toUpperCase();
  if (raw == 'ACTIVE' || raw == 'ARCHIVED') return raw;
  return fallbackIsActive ? 'ACTIVE' : 'ARCHIVED';
}
