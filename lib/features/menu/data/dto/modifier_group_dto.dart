class ModifierOptionDto {
  const ModifierOptionDto({
    required this.id,
    required this.label,
    required this.priceAdjustmentUsd,
    required this.isDefault,
    required this.isActive,
  });

  final String id;
  final String label;
  final double priceAdjustmentUsd;
  final bool isDefault;
  final bool isActive;

  factory ModifierOptionDto.fromJson(Map<String, dynamic> json) {
    final priceRaw =
        json['priceAdjustmentUsd'] ?? json['price'] ?? json['priceUsd'] ?? 0;
    final parsedPrice = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw.toString()) ?? 0;
    final rawName =
        json['label'] ?? json['name'] ?? json['optionName'] ?? json['title'] ?? json['value'];
    return ModifierOptionDto(
      id: json['id']?.toString() ?? '',
      label: rawName?.toString() ?? 'Option',
      priceAdjustmentUsd: parsedPrice,
      isDefault: _asBool(json['isDefault'], fallback: false),
      isActive: _asBool(json['isActive'], fallback: true),
    );
  }
}

class ModifierGroupDto {
  const ModifierGroupDto({
    required this.id,
    required this.name,
    required this.selectionType,
    required this.pricingBehavior,
    required this.options,
    required this.defaultOptionId,
    required this.isRequired,
    required this.isActive,
  });

  final String id;
  final String name;
  final String selectionType;
  final String pricingBehavior;
  final List<ModifierOptionDto> options;
  final String? defaultOptionId;
  final bool? isRequired;
  final bool isActive;

  ModifierGroupDto copyWith({
    List<ModifierOptionDto>? options,
    String? defaultOptionId,
    bool? isRequired,
  }) {
    return ModifierGroupDto(
      id: id,
      name: name,
      selectionType: selectionType,
      pricingBehavior: pricingBehavior,
      options: options ?? this.options,
      defaultOptionId: defaultOptionId ?? this.defaultOptionId,
      isRequired: isRequired ?? this.isRequired,
      isActive: isActive,
    );
  }

  factory ModifierGroupDto.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    final options = rawOptions
        .whereType<Map>()
        .map((opt) => ModifierOptionDto.fromJson(
              Map<String, dynamic>.from(opt),
            ))
        .toList(growable: false);
    return ModifierGroupDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Modifier Group',
      selectionType:
          (json['selectionType']?.toString() ?? 'single').toLowerCase(),
      pricingBehavior:
          (json['pricingBehavior']?.toString() ?? 'addon').toLowerCase(),
      options: options,
      defaultOptionId: json['defaultOptionId']?.toString(),
      isRequired: json['isRequired'] as bool?,
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

