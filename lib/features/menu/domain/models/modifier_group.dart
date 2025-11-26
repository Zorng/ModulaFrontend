class ModifierOption {
  const ModifierOption({
    required this.id,
    required this.name,
    this.price = 0,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final double price;
  final bool isDefault;

  ModifierOption copyWith({String? id, String? name, double? price, bool? isDefault}) {
    return ModifierOption(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory ModifierOption.fromJson(Map<String, dynamic> json) {
    return ModifierOption(
      id: json['id'] as String,
      name: (json['label'] as String?) ??
          json['name'] as String? ??
          'Option',
      price: (json['priceAdjustmentUsd'] as num?)
              ?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'label': name,
        'priceAdjustmentUsd': price,
        'isDefault': isDefault,
      };
}

class ModifierGroup {
  const ModifierGroup({
    required this.id,
    required this.name,
    required this.selectionType,
    required this.pricingBehavior,
    required this.options,
    this.defaultOptionId,
    this.isRequired,
  });

  final String id;
  final String name;
  final String selectionType; // 'single' or 'multiple'
  final String pricingBehavior; // 'addon', 'fixed', 'none'
  final List<ModifierOption> options;
  final String? defaultOptionId;
  final bool? isRequired;

  ModifierGroup copyWith({
    String? id,
    String? name,
    String? selectionType,
    String? pricingBehavior,
    List<ModifierOption>? options,
    String? defaultOptionId,
    bool? isRequired,
  }) {
    return ModifierGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      selectionType: selectionType ?? this.selectionType,
      pricingBehavior: pricingBehavior ?? this.pricingBehavior,
      options: options ?? this.options,
      defaultOptionId: defaultOptionId ?? this.defaultOptionId,
      isRequired: isRequired ?? this.isRequired,
    );
  }

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    return ModifierGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      selectionType: (json['selectionType'] as String? ?? 'single').toLowerCase(),
      pricingBehavior: (json['pricingBehavior'] as String? ?? 'addon').toLowerCase(),
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((option) => ModifierOption.fromJson(option as Map<String, dynamic>))
          .toList(),
      defaultOptionId: json['defaultOptionId'] as String?,
      isRequired: json['isRequired'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'selectionType': selectionType,
        'pricingBehavior': pricingBehavior,
        'options': options.map((o) => o.toJson()).toList(),
        'defaultOptionId': defaultOptionId,
        'isRequired': isRequired,
      };
}
