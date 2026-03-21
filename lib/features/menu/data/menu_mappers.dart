import 'package:modular_pos/features/menu/data/dto/menu_branch_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_category_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_composition_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class MenuMappers {
  const MenuMappers._();

  static MenuBranch toBranch(MenuBranchDto dto) {
    return MenuBranch(id: dto.id, name: dto.name);
  }

  static MenuCategory toCategory(MenuCategoryDto dto) {
    final status = normalizeStatus(dto.status, fallbackIsActive: dto.isActive);
    return MenuCategory(
      id: dto.id,
      tenantId: dto.tenantId,
      name: dto.name,
      status: status,
      description: dto.description,
      displayOrder: dto.displayOrder,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  static MenuItem toItem(MenuItemDto dto) {
    final status = normalizeStatus(dto.status, fallbackIsActive: dto.isActive);
    final visibleBranchIds = dto.visibleBranchIds;

    return MenuItem(
      id: dto.id,
      tenantId: dto.tenantId,
      name: dto.name,
      categoryId: dto.categoryId,
      price: dto.basePrice,
      basePrice: dto.basePrice,
      status: status,
      imageUrl: dto.imageUrl,
      modifierGroupIds: dto.modifierGroupIds,
      description: dto.description,
      visibleBranchIds: visibleBranchIds,
      branchIds: visibleBranchIds,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      isActive: status != 'ARCHIVED',
    );
  }

  static ModifierOption toOption(ModifierOptionDto dto) {
    final status = normalizeStatus(dto.status, fallbackIsActive: dto.isActive);
    final deltas = dto.componentDeltas
        .map(toModifierDelta)
        .toList(growable: false);

    return ModifierOption(
      id: dto.id,
      groupId: dto.groupId,
      name: dto.label,
      price: dto.priceDelta,
      priceDelta: dto.priceDelta,
      status: status,
      componentDeltas: deltas,
      isDefault: dto.isDefault,
      isActive: status != 'ARCHIVED',
    );
  }

  static ModifierGroup toGroup(ModifierGroupDto dto) {
    final status = normalizeStatus(dto.status, fallbackIsActive: dto.isActive);
    final selectionMode = normalizeSelectionMode(dto.selectionMode);
    final selectionType = selectionMode == 'MULTI' ? 'multiple' : 'single';

    return ModifierGroup(
      id: dto.id,
      tenantId: dto.tenantId,
      name: dto.name,
      selectionType: selectionType,
      pricingBehavior: dto.pricingBehavior,
      selectionMode: selectionMode,
      minSelections: dto.minSelections,
      maxSelections: dto.maxSelections,
      options: dto.options
          .where((entry) => entry.status != 'ARCHIVED')
          .map(toOption)
          .toList(),
      defaultOptionId: dto.defaultOptionId,
      isRequired: dto.isRequired,
      status: status,
      isActive: status != 'ARCHIVED',
    );
  }

  static ModifierDelta toModifierDelta(ModifierDeltaDto dto) {
    return ModifierDelta(
      stockItemId: dto.stockItemId,
      quantityDeltaInBaseUnit: dto.quantityDeltaInBaseUnit,
      trackingMode: dto.trackingMode,
    );
  }

  static MenuComponent toCompositionComponent(MenuComponentDto dto) {
    return MenuComponent(
      stockItemId: dto.stockItemId,
      quantityInBaseUnit: dto.quantityInBaseUnit,
      trackingMode: dto.trackingMode,
    );
  }

  static MenuCompositionEvaluate toCompositionEvaluate(
    MenuCompositionEvaluateDto dto,
  ) {
    return MenuCompositionEvaluate(
      menuItemId: dto.menuItemId,
      components: dto.components
          .map(toCompositionComponent)
          .toList(growable: false),
    );
  }

  static String normalizeSelectionMode(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'MULTIPLE' || normalized == 'MULTI') {
      return 'MULTI';
    }
    return 'SINGLE';
  }

  static String formatSelectionType(String value) {
    return normalizeSelectionMode(value);
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

  static String normalizeStatus(
    String? value, {
    required bool fallbackIsActive,
  }) {
    final normalized = (value ?? '').trim().toUpperCase();
    if (normalized == 'ACTIVE') return normalized;
    if (normalized == 'ARCHIVED' ||
        normalized == 'ARCHIVE' ||
        normalized == 'INACTIVE') {
      return 'ARCHIVED';
    }
    return fallbackIsActive ? 'ACTIVE' : 'ARCHIVED';
  }
}
