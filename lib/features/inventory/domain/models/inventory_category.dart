import 'package:equatable/equatable.dart';

class InventoryCategory extends Equatable {
  const InventoryCategory({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String name;
  final bool isActive;

  InventoryCategory copyWith({
    String? id,
    String? name,
    bool? isActive,
  }) {
    return InventoryCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }

  factory InventoryCategory.fromJson(Map<String, dynamic> json) {
    return InventoryCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isActive': isActive,
      };

  @override
  List<Object?> get props => [id, name, isActive];
}
