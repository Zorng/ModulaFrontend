class InventoryCategoryDto {
  const InventoryCategoryDto({
    required this.id,
    required this.name,
    required this.isActive,
    this.description,
  });

  final String id;
  final String name;
  final bool isActive;
  final String? description;

  factory InventoryCategoryDto.fromJson(Map<String, dynamic> json) {
    return InventoryCategoryDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Category',
      isActive: _asBool(json['isActive'], fallback: true),
      description: json['description']?.toString(),
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
