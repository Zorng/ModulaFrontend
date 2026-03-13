import 'package:equatable/equatable.dart';

class InventoryCategory extends Equatable {
  const InventoryCategory({
    required this.id,
    required this.name,
    required this.isActive,
    this.description,
  });

  final String id;
  final String name;
  final bool isActive;
  final String? description;

  InventoryCategory copyWith({
    String? id,
    String? name,
    bool? isActive,
    String? description,
  }) {
    return InventoryCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [id, name, isActive, description];
}
