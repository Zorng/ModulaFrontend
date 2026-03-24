import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/menu_modifier_option_effect.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class MenuItemDetail {
  const MenuItemDetail({
    required this.item,
    required this.modifierGroups,
    required this.baseComponents,
    required this.modifierOptionEffects,
    this.categoryName,
  });

  final MenuItem item;
  final List<ModifierGroup> modifierGroups;
  final List<MenuComponent> baseComponents;
  final List<MenuModifierOptionEffect> modifierOptionEffects;
  final String? categoryName;
}
