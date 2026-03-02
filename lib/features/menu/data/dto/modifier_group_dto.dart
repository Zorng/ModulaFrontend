class ModifierDeltaDto {
  const ModifierDeltaDto({
    required this.stockItemId,
    required this.quantityDeltaInBaseUnit,
    required this.trackingMode,
  });

  final String stockItemId;
  final double quantityDeltaInBaseUnit;
  final String trackingMode;

  factory ModifierDeltaDto.fromJson(Map<String, dynamic> json) {
    final quantity = _asDouble(
      json['quantityDeltaInBaseUnit'] ?? json['quantityDelta'] ?? 0,
    );
    return ModifierDeltaDto(
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

class ModifierOptionDto {
  const ModifierOptionDto({
    required this.id,
    required this.groupId,
    required this.label,
    required this.priceDelta,
    required this.status,
    required this.componentDeltas,
    required this.priceAdjustmentUsd,
    required this.isDefault,
    required this.isActive,
  });

  final String id;
  final String groupId;
  final String label;
  final double priceDelta;
  final String status;
  final List<ModifierDeltaDto> componentDeltas;

  // Legacy aliases kept for compatibility until mapper/domain refactor is finished.
  final double priceAdjustmentUsd;
  final bool isDefault;
  final bool isActive;

  factory ModifierOptionDto.fromJson(Map<String, dynamic> json) {
    final priceDeltaRaw =
        json['priceDelta'] ?? json['priceAdjustmentUsd'] ?? json['price'] ?? 0;
    final parsedPriceDelta = _asDouble(priceDeltaRaw);
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

    final rawComponentDeltas =
        json['componentDeltas'] as List<dynamic>? ?? const <dynamic>[];
    final componentDeltas = rawComponentDeltas
        .whereType<Map>()
        .map(
          (entry) =>
              ModifierDeltaDto.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList(growable: false);

    return ModifierOptionDto(
      id: json['id']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      label: rawName?.toString() ?? 'Option',
      priceDelta: parsedPriceDelta,
      status: normalizedStatus,
      componentDeltas: componentDeltas,
      priceAdjustmentUsd: parsedPriceDelta,
      isDefault: _asBool(json['isDefault'], fallback: false),
      isActive: normalizedStatus != 'ARCHIVED',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'groupId': groupId,
      'label': label,
      'priceDelta': priceDelta,
      'status': status,
      'componentDeltas': componentDeltas
          .map((entry) => entry.toJson())
          .toList(),
      // Legacy compatibility shape
      'priceAdjustmentUsd': priceAdjustmentUsd,
      'isDefault': isDefault,
      'isActive': isActive,
    };
  }
}

class ModifierGroupDto {
  const ModifierGroupDto({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.selectionMode,
    required this.minSelections,
    required this.maxSelections,
    required this.isRequired,
    required this.status,
    required this.options,
    required this.selectionType,
    required this.pricingBehavior,
    required this.defaultOptionId,
    required this.isActive,
  });

  final String id;
  final String tenantId;
  final String name;
  final String selectionMode;
  final int minSelections;
  final int maxSelections;
  final bool isRequired;
  final String status;
  final List<ModifierOptionDto> options;

  // Legacy aliases kept for compatibility until mapper/domain refactor is finished.
  final String selectionType;
  final String pricingBehavior;
  final String? defaultOptionId;
  final bool isActive;

  ModifierGroupDto copyWith({
    List<ModifierOptionDto>? options,
    String? defaultOptionId,
    bool? isRequired,
  }) {
    return ModifierGroupDto(
      id: id,
      tenantId: tenantId,
      name: name,
      selectionMode: selectionMode,
      minSelections: minSelections,
      maxSelections: maxSelections,
      isRequired: isRequired ?? this.isRequired,
      status: status,
      options: options ?? this.options,
      selectionType: selectionType,
      pricingBehavior: pricingBehavior,
      defaultOptionId: defaultOptionId ?? this.defaultOptionId,
      isActive: isActive,
    );
  }

  factory ModifierGroupDto.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const <dynamic>[];
    final options = rawOptions
        .whereType<Map>()
        .map(
          (entry) =>
              ModifierOptionDto.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList(growable: false);

    final selectionMode = _normalizeSelectionMode(
      json['selectionMode']?.toString() ?? json['selectionType']?.toString(),
    );
    final normalizedStatus = _normalizeStatus(
      json['status']?.toString(),
      fallbackIsActive: _asBool(json['isActive'], fallback: true),
    );

    final minSelections =
        _asInt(json['minSelections']) ?? (selectionMode == 'SINGLE' ? 0 : 0);
    final maxSelections =
        _asInt(json['maxSelections']) ?? (selectionMode == 'SINGLE' ? 1 : 99);

    return ModifierGroupDto(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Modifier Group',
      selectionMode: selectionMode,
      minSelections: minSelections,
      maxSelections: maxSelections,
      isRequired: _asBool(json['isRequired'], fallback: false),
      status: normalizedStatus,
      options: options,
      selectionType: selectionMode == 'MULTI' ? 'multiple' : 'single',
      pricingBehavior: (json['pricingBehavior']?.toString() ?? 'addon')
          .trim()
          .toLowerCase(),
      defaultOptionId: json['defaultOptionId']?.toString(),
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

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _normalizeSelectionMode(String? value) {
  final raw = (value ?? '').trim().toUpperCase();
  if (raw == 'MULTI' || raw == 'MULTIPLE') return 'MULTI';
  return 'SINGLE';
}

String _normalizeStatus(String? value, {required bool fallbackIsActive}) {
  final raw = (value ?? '').trim().toUpperCase();
  if (raw == 'ACTIVE' || raw == 'ARCHIVED') return raw;
  return fallbackIsActive ? 'ACTIVE' : 'ARCHIVED';
}
