class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    this.tenantId = '',
    required this.price,
    double? basePrice,
    String? status,
    this.imageUrl,
    this.modifierGroupIds = const [],
    this.description = '',
    List<String>? visibleBranchIds,
    List<String>? branchIds,
    this.createdAt,
    this.updatedAt,
    bool? isActive,
  }) : basePrice = basePrice ?? price,
       status = status ?? ((isActive ?? true) ? 'ACTIVE' : 'ARCHIVED'),
       visibleBranchIds = visibleBranchIds ?? branchIds ?? const <String>[],
       branchIds = branchIds ?? visibleBranchIds ?? const <String>[],
       isActive = isActive ?? ((status ?? 'ACTIVE') != 'ARCHIVED');

  final String id;
  final String name;
  final String categoryId;
  final String tenantId;
  // Legacy alias kept for compatibility until UI cutover.
  final double price;
  final double basePrice;
  final String status;
  final String? imageUrl;
  final List<String> modifierGroupIds;
  final String description;
  final List<String> visibleBranchIds;
  // Legacy alias kept for compatibility until UI cutover.
  final List<String> branchIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Legacy alias kept for compatibility until UI cutover.
  final bool isActive;

  MenuItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? tenantId,
    double? price,
    double? basePrice,
    String? status,
    String? imageUrl,
    List<String>? modifierGroupIds,
    String? description,
    List<String>? visibleBranchIds,
    List<String>? branchIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    final resolvedBasePrice = basePrice ?? price ?? this.basePrice;
    final resolvedStatus = _normalizeStatus(
      status ?? ((isActive ?? this.isActive) ? 'ACTIVE' : 'ARCHIVED'),
      fallbackIsActive: isActive ?? this.isActive,
    );
    final resolvedVisibleBranchIds =
        visibleBranchIds ?? branchIds ?? this.visibleBranchIds;

    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      tenantId: tenantId ?? this.tenantId,
      price: resolvedBasePrice,
      basePrice: resolvedBasePrice,
      status: resolvedStatus,
      imageUrl: imageUrl ?? this.imageUrl,
      modifierGroupIds: modifierGroupIds ?? this.modifierGroupIds,
      description: description ?? this.description,
      visibleBranchIds: resolvedVisibleBranchIds,
      branchIds: resolvedVisibleBranchIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: resolvedStatus != 'ARCHIVED',
    );
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final priceValue =
        json['basePrice'] ?? json['price'] ?? json['priceUsd'] ?? 0;
    final double parsedPrice = priceValue is num
        ? priceValue.toDouble()
        : double.tryParse(priceValue.toString()) ?? 0;
    final rawImage =
        json['imageUrl'] ?? json['image'] ?? json['image_url'] ?? json['url'];
    final image = rawImage?.toString().trim();
    final rawModifierIds =
        json['modifierGroupIds'] ?? json['modifiers'] ?? json['modifierGroups'];
    final modifierIds = <String>[];
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

    return MenuItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Menu Item',
      categoryId: (json['categoryId']?.toString() ?? '').trim(),
      tenantId: json['tenantId']?.toString() ?? '',
      price: parsedPrice,
      basePrice: parsedPrice,
      status: normalizedStatus,
      imageUrl: image,
      modifierGroupIds: modifierIds.isNotEmpty
          ? modifierIds
          : (json['modifierGroupIds'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
      description: json['description'] as String? ?? '',
      visibleBranchIds: visibleBranchIds,
      branchIds: visibleBranchIds,
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
      isActive: normalizedStatus != 'ARCHIVED',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenantId': tenantId,
    'name': name,
    'categoryId': categoryId,
    'basePrice': basePrice,
    'status': status,
    'price': price,
    'imageUrl': imageUrl,
    'modifierGroupIds': modifierGroupIds,
    'description': description,
    'visibleBranchIds': visibleBranchIds,
    'branchIds': branchIds,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'isActive': isActive,
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
