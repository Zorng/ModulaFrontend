import 'package:modular_pos/features/menu/data/dto/menu_branch_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_category_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class MenuMappers {
  const MenuMappers._();

  static MenuBranch toBranch(MenuBranchDto dto) {
    return MenuBranch(
      id: dto.id,
      name: dto.name,
    );
  }

  static MenuCategory toCategory(MenuCategoryDto dto) {
    return MenuCategory(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      isActive: dto.isActive,
      displayOrder: dto.displayOrder,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  static MenuItem toItem(MenuItemDto dto) {
    return MenuItem(
      id: dto.id,
      name: dto.name,
      categoryId: dto.categoryId,
      price: dto.priceUsd,
      imageUrl: dto.imageUrl,
      modifierGroupIds: dto.modifierGroupIds,
      description: dto.description,
      branchIds: dto.branchIds,
      isActive: dto.isActive,
    );
  }

  static ModifierOption toOption(ModifierOptionDto dto) {
    return ModifierOption(
      id: dto.id,
      name: dto.label,
      price: dto.priceAdjustmentUsd,
      isDefault: dto.isDefault,
    );
  }

  static ModifierGroup toGroup(ModifierGroupDto dto) {
    return ModifierGroup(
      id: dto.id,
      name: dto.name,
      selectionType: dto.selectionType,
      pricingBehavior: dto.pricingBehavior,
      options: dto.options.where((o) => o.isActive).map(toOption).toList(),
      defaultOptionId: dto.defaultOptionId,
      isRequired: dto.isRequired,
    );
  }

  static String formatSelectionType(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'MULTIPLE' || normalized == 'MULTI') {
      return 'MULTI';
    }
    return 'SINGLE';
  }

  static String? formatPricingBehavior(String value) {
    if (value.isEmpty) return null;
    switch (value.trim().toLowerCase()) {
      case 'fixed':
        return 'FIXED';
      case 'none':
        return 'NONE';
      default:
        return 'ADDON';
    }
  }
}
