class MenuComponentDto {
  const MenuComponentDto({
    required this.stockItemId,
    required this.quantityInBaseUnit,
    required this.trackingMode,
  });

  final String stockItemId;
  final double quantityInBaseUnit;
  final String trackingMode;

  factory MenuComponentDto.fromJson(Map<String, dynamic> json) {
    final quantityRaw = json['quantityInBaseUnit'] ?? 0;
    final quantity = quantityRaw is num
        ? quantityRaw.toDouble()
        : double.tryParse(quantityRaw.toString()) ?? 0;

    return MenuComponentDto(
      stockItemId: json['stockItemId']?.toString() ?? '',
      quantityInBaseUnit: quantity,
      trackingMode: json['trackingMode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stockItemId': stockItemId,
      'quantityInBaseUnit': quantityInBaseUnit,
      'trackingMode': trackingMode,
    };
  }
}

class MenuCompositionUpsertRequestDto {
  const MenuCompositionUpsertRequestDto({required this.baseComponents});

  final List<MenuComponentDto> baseComponents;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'baseComponents': baseComponents.map((entry) => entry.toJson()).toList(),
    };
  }
}

class MenuCompositionEvaluateRequestDto {
  const MenuCompositionEvaluateRequestDto({
    required this.selectedModifierOptionIds,
  });

  final List<String> selectedModifierOptionIds;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'selectedModifierOptionIds': selectedModifierOptionIds,
    };
  }
}

class MenuCompositionEvaluateDto {
  const MenuCompositionEvaluateDto({
    required this.menuItemId,
    required this.components,
  });

  final String menuItemId;
  final List<MenuComponentDto> components;

  factory MenuCompositionEvaluateDto.fromJson(Map<String, dynamic> json) {
    final rawComponents =
        json['components'] as List<dynamic>? ?? const <dynamic>[];
    final components = rawComponents
        .whereType<Map>()
        .map(
          (entry) =>
              MenuComponentDto.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList(growable: false);

    return MenuCompositionEvaluateDto(
      menuItemId: json['menuItemId']?.toString() ?? '',
      components: components,
    );
  }
}
