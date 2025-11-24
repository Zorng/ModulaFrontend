class ModifierOption {
  const ModifierOption({
    required this.id,
    required this.name,
    this.price = 0,
  });

  final String id;
  final String name;
  final double price;

  ModifierOption copyWith({String? id, String? name, double? price}) {
    return ModifierOption(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  factory ModifierOption.fromJson(Map<String, dynamic> json) {
    return ModifierOption(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
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
  });

  final String id;
  final String name;
  final String selectionType; // 'single' or 'multiple'
  final String pricingBehavior; // 'addon', 'fixed', 'none'
  final List<ModifierOption> options;
  final String? defaultOptionId;

  ModifierGroup copyWith({
    String? id,
    String? name,
    String? selectionType,
    String? pricingBehavior,
    List<ModifierOption>? options,
    String? defaultOptionId,
  }) {
    return ModifierGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      selectionType: selectionType ?? this.selectionType,
      pricingBehavior: pricingBehavior ?? this.pricingBehavior,
      options: options ?? this.options,
      defaultOptionId: defaultOptionId ?? this.defaultOptionId,
    );
  }

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    return ModifierGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      selectionType: json['selectionType'] as String? ?? 'single',
      pricingBehavior: json['pricingBehavior'] as String? ?? 'addon',
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((option) => ModifierOption.fromJson(option as Map<String, dynamic>))
          .toList(),
      defaultOptionId: json['defaultOptionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'selectionType': selectionType,
        'pricingBehavior': pricingBehavior,
        'options': options.map((o) => o.toJson()).toList(),
        'defaultOptionId': defaultOptionId,
      };
}
