class ModifierDelta {
  const ModifierDelta({
    required this.stockItemId,
    required this.quantityDeltaInBaseUnit,
    required this.trackingMode,
  });

  final String stockItemId;
  final double quantityDeltaInBaseUnit;
  final String trackingMode;

  factory ModifierDelta.fromJson(Map<String, dynamic> json) {
    final quantityRaw = json['quantityDeltaInBaseUnit'] ?? 0;
    final quantity = quantityRaw is num
        ? quantityRaw.toDouble()
        : double.tryParse(quantityRaw.toString()) ?? 0;

    return ModifierDelta(
      stockItemId: json['stockItemId']?.toString() ?? '',
      quantityDeltaInBaseUnit: quantity,
      trackingMode: (json['trackingMode']?.toString() ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stockItemId': stockItemId,
      'quantityDeltaInBaseUnit': quantityDeltaInBaseUnit,
      'trackingMode': trackingMode,
    };
  }
}

class ModifierOption {
  const ModifierOption({
    required this.id,
    required this.name,
    this.groupId = '',
    double? price,
    double? priceDelta,
    this.status = 'ACTIVE',
    this.componentDeltas = const [],
    this.isDefault = false,
    this.isActive = true,
  }) : price = priceDelta ?? price ?? 0,
       priceDelta = priceDelta ?? price ?? 0;

  final String id;
  final String name;
  final String groupId;
  // Legacy alias kept for compatibility until UI cutover.
  final double price;
  final double priceDelta;
  final String status;
  final List<ModifierDelta> componentDeltas;
  final bool isDefault;
  // Legacy alias kept for compatibility until UI cutover.
  final bool isActive;

  ModifierOption copyWith({
    String? id,
    String? name,
    String? groupId,
    double? price,
    double? priceDelta,
    String? status,
    List<ModifierDelta>? componentDeltas,
    bool? isDefault,
    bool? isActive,
  }) {
    final resolvedPrice = price ?? priceDelta ?? this.price;
    final resolvedStatus = _normalizeStatus(
      status ?? ((isActive ?? this.isActive) ? 'ACTIVE' : 'ARCHIVED'),
      fallbackIsActive: isActive ?? this.isActive,
    );

    return ModifierOption(
      id: id ?? this.id,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      price: resolvedPrice,
      priceDelta: resolvedPrice,
      status: resolvedStatus,
      componentDeltas: componentDeltas ?? this.componentDeltas,
      isDefault: isDefault ?? this.isDefault,
      isActive: resolvedStatus != 'ARCHIVED',
    );
  }

  factory ModifierOption.fromJson(Map<String, dynamic> json) {
    final priceRaw =
        json['priceDelta'] ?? json['priceAdjustmentUsd'] ?? json['price'] ?? 0;
    final parsedPrice = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw.toString()) ?? 0;
    final rawName =
        json['label'] ??
        json['name'] ??
        json['optionName'] ??
        json['title'] ??
        json['value'];
    final normalizedStatus = _normalizeStatus(
      json['status']?.toString(),
      fallbackIsActive: _asBool(json['isActive'], fallback: true),
    );

    final rawDeltas =
        json['componentDeltas'] as List<dynamic>? ?? const <dynamic>[];
    final deltas = rawDeltas
        .whereType<Map>()
        .map(
          (entry) => ModifierDelta.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList(growable: false);

    return ModifierOption(
      id: json['id']?.toString() ?? '',
      name: rawName?.toString() ?? 'Option',
      groupId: json['groupId']?.toString() ?? '',
      price: parsedPrice,
      priceDelta: parsedPrice,
      status: normalizedStatus,
      componentDeltas: deltas,
      isDefault: _asBool(json['isDefault'], fallback: false),
      isActive: normalizedStatus != 'ARCHIVED',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'groupId': groupId,
      'label': name,
      'priceDelta': priceDelta,
      'status': status,
      'componentDeltas': componentDeltas
          .map((entry) => entry.toJson())
          .toList(growable: false),
      // Legacy compatibility shape
      'priceAdjustmentUsd': price,
      'isDefault': isDefault,
      'isActive': isActive,
    };
  }
}

class ModifierGroup {
  const ModifierGroup({
    required this.id,
    required this.name,
    required this.selectionType,
    required this.pricingBehavior,
    required this.options,
    this.tenantId = '',
    this.selectionMode = 'SINGLE',
    this.minSelections = 0,
    this.maxSelections = 1,
    this.defaultOptionId,
    this.isRequired,
    this.status = 'ACTIVE',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String tenantId;
  // Legacy alias kept for compatibility until UI cutover.
  final String selectionType; // single or multiple
  final String pricingBehavior; // addon, fixed, none
  final String selectionMode; // SINGLE or MULTI
  final int minSelections;
  final int maxSelections;
  final List<ModifierOption> options;
  final String? defaultOptionId;
  final bool? isRequired;
  final String status;
  // Legacy alias kept for compatibility until UI cutover.
  final bool isActive;

  ModifierGroup copyWith({
    String? id,
    String? name,
    String? tenantId,
    String? selectionType,
    String? pricingBehavior,
    String? selectionMode,
    int? minSelections,
    int? maxSelections,
    List<ModifierOption>? options,
    String? defaultOptionId,
    bool? isRequired,
    String? status,
    bool? isActive,
  }) {
    final resolvedSelectionMode = _normalizeSelectionMode(
      selectionMode ??
          (selectionType != null
              ? _selectionTypeToMode(selectionType)
              : this.selectionMode),
    );
    final resolvedStatus = _normalizeStatus(
      status ?? ((isActive ?? this.isActive) ? 'ACTIVE' : 'ARCHIVED'),
      fallbackIsActive: isActive ?? this.isActive,
    );

    return ModifierGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      tenantId: tenantId ?? this.tenantId,
      selectionType: selectionType ?? this.selectionType,
      pricingBehavior: pricingBehavior ?? this.pricingBehavior,
      selectionMode: resolvedSelectionMode,
      minSelections: minSelections ?? this.minSelections,
      maxSelections: maxSelections ?? this.maxSelections,
      options: options ?? this.options,
      defaultOptionId: defaultOptionId ?? this.defaultOptionId,
      isRequired: isRequired ?? this.isRequired,
      status: resolvedStatus,
      isActive: resolvedStatus != 'ARCHIVED',
    );
  }

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    final selectionMode = _normalizeSelectionMode(
      json['selectionMode']?.toString() ?? json['selectionType']?.toString(),
    );
    final normalizedStatus = _normalizeStatus(
      json['status']?.toString(),
      fallbackIsActive: _asBool(json['isActive'], fallback: true),
    );
    final rawOptions = json['options'] as List<dynamic>? ?? const <dynamic>[];
    final options = rawOptions
        .whereType<Map>()
        .map(
          (option) =>
              ModifierOption.fromJson(Map<String, dynamic>.from(option)),
        )
        .toList(growable: false);

    return ModifierGroup(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Modifier Group',
      tenantId: json['tenantId']?.toString() ?? '',
      selectionType: selectionMode == 'MULTI' ? 'multiple' : 'single',
      pricingBehavior: (json['pricingBehavior'] as String? ?? 'addon')
          .trim()
          .toLowerCase(),
      selectionMode: selectionMode,
      minSelections:
          _asInt(json['minSelections']) ?? (selectionMode == 'SINGLE' ? 0 : 0),
      maxSelections:
          _asInt(json['maxSelections']) ?? (selectionMode == 'SINGLE' ? 1 : 99),
      options: options,
      defaultOptionId: json['defaultOptionId']?.toString(),
      isRequired: _asNullableBool(json['isRequired']),
      status: normalizedStatus,
      isActive: normalizedStatus != 'ARCHIVED',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'tenantId': tenantId,
      'selectionType': selectionType,
      'pricingBehavior': pricingBehavior,
      'selectionMode': selectionMode,
      'minSelections': minSelections,
      'maxSelections': maxSelections,
      'options': options.map((entry) => entry.toJson()).toList(growable: false),
      'defaultOptionId': defaultOptionId,
      'isRequired': isRequired,
      'status': status,
      'isActive': isActive,
    }..removeWhere((key, value) => value == null);
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

bool? _asNullableBool(dynamic value) {
  if (value == null) return null;
  return _asBool(value, fallback: false);
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _normalizeStatus(String? value, {required bool fallbackIsActive}) {
  final raw = (value ?? '').trim().toUpperCase();
  if (raw == 'ACTIVE' || raw == 'ARCHIVED') return raw;
  return fallbackIsActive ? 'ACTIVE' : 'ARCHIVED';
}

String _normalizeSelectionMode(String? value) {
  final raw = (value ?? '').trim().toUpperCase();
  if (raw == 'MULTI' || raw == 'MULTIPLE') return 'MULTI';
  return 'SINGLE';
}

String _selectionTypeToMode(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'multiple' || normalized == 'multi') return 'MULTI';
  return 'SINGLE';
}
