class MenuItemDto {
  const MenuItemDto({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.priceUsd,
    required this.imageUrl,
    required this.modifierGroupIds,
    required this.description,
    required this.branchIds,
    required this.isActive,
  });

  final String id;
  final String name;
  final String categoryId;
  final double priceUsd;
  final String? imageUrl;
  final List<String> modifierGroupIds;
  final String description;
  final List<String> branchIds;
  final bool isActive;

  MenuItemDto copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? priceUsd,
    String? imageUrl,
    List<String>? modifierGroupIds,
    String? description,
    List<String>? branchIds,
    bool? isActive,
  }) {
    return MenuItemDto(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      priceUsd: priceUsd ?? this.priceUsd,
      imageUrl: imageUrl ?? this.imageUrl,
      modifierGroupIds: modifierGroupIds ?? this.modifierGroupIds,
      description: description ?? this.description,
      branchIds: branchIds ?? this.branchIds,
      isActive: isActive ?? this.isActive,
    );
  }

  factory MenuItemDto.fromJson(Map<String, dynamic> json) {
    final priceValue = json['priceUsd'] ?? json['price'] ?? 0;
    final parsedPrice = priceValue is num
        ? priceValue.toDouble()
        : double.tryParse(priceValue.toString()) ?? 0;
    final rawImage =
        json['imageUrl'] ?? json['image'] ?? json['image_url'] ?? json['url'];
    final image = rawImage?.toString().trim();

    final modifierIds = <String>[];
    final rawModifierIds =
        json['modifierGroupIds'] ?? json['modifiers'] ?? json['modifierGroups'];
    if (rawModifierIds is List) {
      for (final entry in rawModifierIds) {
        if (entry is Map) {
          final id =
              entry['id'] ?? entry['modifierGroupId'] ?? entry['groupId'];
          if (id != null) modifierIds.add(id.toString());
        } else if (entry != null) {
          modifierIds.add(entry.toString());
        }
      }
    }

    return MenuItemDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Menu Item',
      categoryId: json['categoryId']?.toString() ?? '',
      priceUsd: parsedPrice,
      imageUrl: image != null && image.isNotEmpty ? image : null,
      modifierGroupIds: modifierIds,
      description: json['description']?.toString() ?? '',
      branchIds: (json['branchIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      isActive: _asBool(json['isActive'], fallback: true),
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

