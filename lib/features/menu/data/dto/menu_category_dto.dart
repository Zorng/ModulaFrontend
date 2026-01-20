class MenuCategoryDto {
  const MenuCategoryDto({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final bool isActive;
  final int? displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MenuCategoryDto.fromJson(Map<String, dynamic> json) {
    return MenuCategoryDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Category',
      description: json['description']?.toString() ?? '',
      isActive: _asBool(json['isActive'], fallback: true),
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

