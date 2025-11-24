class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;
  final bool isActive;

  MenuCategory copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'isActive': isActive,
      };
}
