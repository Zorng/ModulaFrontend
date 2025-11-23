// A simple data model for a menu item.
import 'package:modular_pos/features/menu/ui/view/modifiers_management_page.dart';

class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? imagePath;
  final List<ModifierGroupInfo> modifierGroups;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.imagePath,
    this.modifierGroups = const [],
  });

  /// Creates a MenuItem from a JSON object.
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      price: (json['price'] as num).toDouble(),
      imagePath: json['imagePath'],
      modifierGroups: const [], // Assume no modifiers from API for now
    );
  }
}