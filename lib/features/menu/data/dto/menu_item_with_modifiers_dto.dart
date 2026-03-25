import 'package:modular_pos/features/menu/data/dto/menu_composition_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_detail_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';

class MenuItemWithModifiersDto {
  const MenuItemWithModifiersDto({
    required this.item,
    required this.modifierGroups,
    required this.categoryName,
    required this.baseComponents,
  });

  final MenuItemDto item;
  final List<ModifierGroupDto> modifierGroups;
  final String? categoryName;
  final List<MenuComponentDto> baseComponents;

  factory MenuItemWithModifiersDto.fromJson(Map<String, dynamic> raw) {
    final detail = MenuItemDetailDto.fromJson(raw);
    return MenuItemWithModifiersDto(
      item: detail.item,
      modifierGroups: detail.modifierGroups,
      categoryName: detail.categoryName,
      baseComponents: detail.baseComponents,
    );
  }
}
