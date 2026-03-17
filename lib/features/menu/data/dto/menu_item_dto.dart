class MenuItemDto {
  const MenuItemDto({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.categoryId,
    required this.basePrice,
    required this.status,
    required this.priceUsd,
    required this.imageUrl,
    required this.modifierGroupIds,
    required this.description,
    required this.visibleBranchIds,
    required this.branchIds,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  final String id;
  final String tenantId;
  final String name;
  final String categoryId;
  final double basePrice;
  final String status;
  // Legacy alias kept for compatibility until mapper/domain refactor is finished.
  final double priceUsd;
  final String? imageUrl;
  final List<String> modifierGroupIds;
  final String description;
  final List<String> visibleBranchIds;
  // Legacy alias kept for compatibility until mapper/domain refactor is finished.
  final List<String> branchIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Legacy alias kept for compatibility until mapper/domain refactor is finished.
  final bool isActive;

  MenuItemDto copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? categoryId,
    double? basePrice,
    String? status,
    double? priceUsd,
    String? imageUrl,
    List<String>? modifierGroupIds,
    String? description,
    List<String>? visibleBranchIds,
    List<String>? branchIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    final resolvedBasePrice = basePrice ?? priceUsd ?? this.basePrice;
    final resolvedStatus = _normalizeStatus(
      status ??
          (isActive == null ? this.status : (isActive ? 'ACTIVE' : 'ARCHIVED')),
      fallbackIsActive: this.isActive,
    );
    final resolvedVisibleBranchIds =
        visibleBranchIds ?? branchIds ?? this.visibleBranchIds;
    final resolvedIsActive = resolvedStatus != 'ARCHIVED';

    return MenuItemDto(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      basePrice: resolvedBasePrice,
      status: resolvedStatus,
      priceUsd: resolvedBasePrice,
      imageUrl: imageUrl ?? this.imageUrl,
      modifierGroupIds: modifierGroupIds ?? this.modifierGroupIds,
      description: description ?? this.description,
      visibleBranchIds: resolvedVisibleBranchIds,
      branchIds: resolvedVisibleBranchIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: resolvedIsActive,
    );
  }

  factory MenuItemDto.fromJson(Map<String, dynamic> json) {
    final priceValue =
        json['basePrice'] ?? json['priceUsd'] ?? json['price'] ?? 0;
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

    final visibleBranchIds = _parseStringList(
      json['visibleBranchIds'] ?? json['branchIds'],
    );
    final normalizedStatus = _normalizeStatus(
      json['status']?.toString(),
      fallbackIsActive: _asBool(json['isActive'], fallback: true),
    );

    return MenuItemDto(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Menu Item',
      categoryId: (json['categoryId']?.toString() ?? '').trim(),
      basePrice: parsedPrice,
      status: normalizedStatus,
      priceUsd: parsedPrice,
      imageUrl: image != null && image.isNotEmpty ? image : null,
      modifierGroupIds: modifierIds,
      description: json['description']?.toString() ?? '',
      visibleBranchIds: visibleBranchIds,
      branchIds: visibleBranchIds,
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
      isActive: normalizedStatus != 'ARCHIVED',
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

List<String> _parseStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((entry) => entry?.toString().trim() ?? '')
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String _normalizeStatus(String? value, {required bool fallbackIsActive}) {
  final raw = (value ?? '').trim().toUpperCase();
  if (raw == 'ACTIVE') return raw;
  if (raw == 'ARCHIVED' || raw == 'ARCHIVE' || raw == 'INACTIVE') {
    return 'ARCHIVED';
  }
  return fallbackIsActive ? 'ACTIVE' : 'ARCHIVED';
}
