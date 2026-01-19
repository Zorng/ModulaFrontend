import 'package:modular_pos/features/menu/domain/models/menu_category.dart';

String resolveCategoryName(
  List<MenuCategory> categories,
  String categoryId,
) {
  for (final category in categories) {
    if (category.id == categoryId) return category.name;
  }
  return 'Unassigned category';
}

