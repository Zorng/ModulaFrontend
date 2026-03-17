import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';
import 'package:modular_pos/features/menu/data/mock_menu_repository.dart';
import 'package:modular_pos/features/menu/data/remote_menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

final useMockMenuRepositoryProvider = Provider<bool>((ref) => false);

final remoteMenuRepositoryProvider = Provider<MenuRepository>((ref) {
  final menuApi = ref.watch(menuApiProvider);
  return RemoteMenuRepository(menuApi);
});

final mockMenuRepositoryProvider = Provider<MenuRepository>((ref) {
  return const MockMenuRepository();
});

/// Primary provider consumed by viewmodels.
///
/// Override [useMockMenuRepositoryProvider] in tests/dev harness to switch to
/// [MockMenuRepository], otherwise [RemoteMenuRepository] is used.
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final useMock = ref.watch(useMockMenuRepositoryProvider);
  if (useMock) {
    return ref.watch(mockMenuRepositoryProvider);
  }
  return ref.watch(remoteMenuRepositoryProvider);
});

enum MenuReadLane { branchContext, management }

class MenuDataBundle {
  const MenuDataBundle({
    required this.items,
    required this.categories,
    required this.modifierGroups,
    required this.branches,
  });

  final List<MenuItem> items;
  final List<MenuCategory> categories;
  final List<ModifierGroup> modifierGroups;
  final List<MenuBranch> branches;
}

abstract class MenuRepository {
  const MenuRepository();

  Future<MenuDataBundle> fetchMenuData({
    MenuReadLane readLane = MenuReadLane.management,
    String status = 'active',
    String? categoryId,
    String? search,
    int? limit,
    int? offset,
    String? branchIdFilter,
  });

  Future<List<MenuCategory>> fetchCategoriesOnly({String? status});

  Future<(MenuItem, List<ModifierGroup>)> fetchItemWithModifiers(
    String menuItemId, {
    bool retrying = false,
  });

  Future<List<MenuComponent>> fetchMenuItemComposition(String menuItemId);

  Future<void> upsertMenuItemComposition({
    required String menuItemId,
    required List<MenuComponent> baseComponents,
  });

  Future<MenuCompositionEvaluate> evaluateMenuItemComposition({
    required String menuItemId,
    required List<String> selectedModifierOptionIds,
  });

  Future<List<ModifierGroup>> fetchModifierGroupsOnly({String? status});

  Future<MenuCategory> createCategory(MenuCategory category);

  Future<MenuCategory> updateCategory(MenuCategory category);

  Future<void> archiveCategory(String categoryId);

  Future<void> restoreCategory(String categoryId);

  Future<void> deleteCategory(String categoryId) {
    return archiveCategory(categoryId);
  }

  Future<ModifierGroup> createModifierGroup(ModifierGroup group);

  Future<ModifierGroup> updateModifierGroup(
    ModifierGroup group, {
    ModifierGroup? previous,
  });

  Future<void> archiveModifierGroup(String groupId);

  Future<void> deleteModifierGroup(String groupId) {
    return archiveModifierGroup(groupId);
  }

  Future<MenuItem> createMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
  });

  Future<MenuItem> updateMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
    MenuItem? previous,
  });

  Future<void> archiveMenuItem(String menuItemId);

  Future<void> restoreMenuItem(String menuItemId);

  Future<void> deleteMenuItem(String menuItemId) {
    return archiveMenuItem(menuItemId);
  }

  Future<void> setMenuItemVisibility({
    required String menuItemId,
    required List<String> visibleBranchIds,
  });

  Future<void> setMenuItemAvailability({
    required String menuItemId,
    required String branchId,
    required bool isAvailable,
  }) {
    return setMenuItemVisibility(
      menuItemId: menuItemId,
      visibleBranchIds: isAvailable ? <String>[branchId] : const <String>[],
    );
  }

  Future<void> setMenuItemPriceOverride({
    required String menuItemId,
    required String branchId,
    required double priceUsd,
  });
}
