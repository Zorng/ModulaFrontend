class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.imageUrl,
    this.modifierGroupIds = const [],
    this.description = '',
    this.branchIds = const [],
  });

  final String id;
  final String name;
  final String categoryId;
  final double price;
  final String? imageUrl;
  final List<String> modifierGroupIds;
  final String description;
  final List<String> branchIds;

  MenuItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? price,
    String? imageUrl,
    List<String>? modifierGroupIds,
    String? description,
    List<String>? branchIds,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      modifierGroupIds: modifierGroupIds ?? this.modifierGroupIds,
      description: description ?? this.description,
      branchIds: branchIds ?? this.branchIds,
    );
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      modifierGroupIds: (json['modifierGroupIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      description: json['description'] as String? ?? '',
      branchIds: (json['branchIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'price': price,
        'imageUrl': imageUrl,
        'modifierGroupIds': modifierGroupIds,
        'description': description,
        'branchIds': branchIds,
      };
}
