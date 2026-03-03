class MenuComponent {
  const MenuComponent({
    required this.stockItemId,
    required this.quantityInBaseUnit,
    required this.trackingMode,
  });

  final String stockItemId;
  final double quantityInBaseUnit;
  final String trackingMode;

  factory MenuComponent.fromJson(Map<String, dynamic> json) {
    final quantityRaw = json['quantityInBaseUnit'] ?? 0;
    final quantity = quantityRaw is num
        ? quantityRaw.toDouble()
        : double.tryParse(quantityRaw.toString()) ?? 0;
    return MenuComponent(
      stockItemId: json['stockItemId']?.toString() ?? '',
      quantityInBaseUnit: quantity,
      trackingMode: (json['trackingMode']?.toString() ?? '').trim(),
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

class MenuCompositionEvaluate {
  const MenuCompositionEvaluate({
    required this.menuItemId,
    required this.components,
  });

  final String menuItemId;
  final List<MenuComponent> components;

  factory MenuCompositionEvaluate.fromJson(Map<String, dynamic> json) {
    final rawComponents =
        json['components'] as List<dynamic>? ?? const <dynamic>[];
    final components = rawComponents
        .whereType<Map>()
        .map(
          (entry) => MenuComponent.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList(growable: false);

    return MenuCompositionEvaluate(
      menuItemId: json['menuItemId']?.toString() ?? '',
      components: components,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'menuItemId': menuItemId,
      'components': components
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }
}
