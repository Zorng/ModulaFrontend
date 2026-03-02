import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class MockMenuRepository extends MenuRepository {
  const MockMenuRepository() : super();

  @override
  Future<MenuDataBundle> fetchMenuData({
    MenuReadLane readLane = MenuReadLane.management,
    String status = 'active',
    String? categoryId,
    String? search,
    int? limit,
    int? offset,
    String? branchIdFilter,
  }) async {
    return const MenuDataBundle(
      items: <MenuItem>[],
      categories: <MenuCategory>[],
      modifierGroups: <ModifierGroup>[],
      branches: <MenuBranch>[],
    );
  }

  @override
  Future<List<MenuCategory>> fetchCategoriesOnly({String? status}) async {
    return const <MenuCategory>[];
  }

  @override
  Future<(MenuItem, List<ModifierGroup>)> fetchItemWithModifiers(
    String menuItemId, {
    bool retrying = false,
  }) async {
    return (
      MenuItem(id: menuItemId, name: 'Mock Item', categoryId: '', price: 0),
      <ModifierGroup>[],
    );
  }

  @override
  Future<List<MenuComponent>> fetchMenuItemComposition(
    String menuItemId,
  ) async {
    return const <MenuComponent>[];
  }

  @override
  Future<void> upsertMenuItemComposition({
    required String menuItemId,
    required List<MenuComponent> baseComponents,
  }) async {}

  @override
  Future<MenuCompositionEvaluate> evaluateMenuItemComposition({
    required String menuItemId,
    required List<String> selectedModifierOptionIds,
  }) async {
    return const MenuCompositionEvaluate(
      menuItemId: '',
      components: <MenuComponent>[],
    );
  }

  @override
  Future<List<ModifierGroup>> fetchModifierGroupsOnly({String? status}) async {
    return const <ModifierGroup>[];
  }

  @override
  Future<MenuCategory> createCategory(MenuCategory category) async {
    if (category.id.isNotEmpty) return category;
    return category.copyWith(id: 'mock-category-id');
  }

  @override
  Future<MenuCategory> updateCategory(MenuCategory category) async {
    return category;
  }

  @override
  Future<void> archiveCategory(String categoryId) async {}

  @override
  Future<ModifierGroup> createModifierGroup(ModifierGroup group) async {
    if (group.id.isNotEmpty) return group;
    return group.copyWith(id: 'mock-modifier-group-id');
  }

  @override
  Future<ModifierGroup> updateModifierGroup(
    ModifierGroup group, {
    ModifierGroup? previous,
  }) async {
    return group;
  }

  @override
  Future<void> archiveModifierGroup(String groupId) async {}

  @override
  Future<MenuItem> createMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    if (item.id.isNotEmpty) return item;
    return item.copyWith(id: 'mock-menu-item-id');
  }

  @override
  Future<MenuItem> updateMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
    MenuItem? previous,
  }) async {
    return item;
  }

  @override
  Future<void> archiveMenuItem(String menuItemId) async {}

  @override
  Future<void> restoreMenuItem(String menuItemId) async {}

  @override
  Future<void> setMenuItemVisibility({
    required String menuItemId,
    required List<String> visibleBranchIds,
  }) async {}

  @override
  Future<void> setMenuItemAvailability({
    required String menuItemId,
    required String branchId,
    required bool isAvailable,
  }) async {}

  @override
  Future<void> setMenuItemPriceOverride({
    required String menuItemId,
    required String branchId,
    required double priceUsd,
  }) async {}
}
