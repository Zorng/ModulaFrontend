import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

/// Provider for the menu repository.
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final menuApi = ref.watch(menuApiProvider);
  return MenuRepository(menuApi);
});

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

/// Repository for the menu feature.
///
/// It uses the [MenuApi] to fetch raw data and parses it into domain models.
class MenuRepository {
  const MenuRepository(this._api);
  final MenuApi _api;

  Future<MenuDataBundle> fetchMenuData() async {
    final branchesFuture = _api.fetchBranches();
    final categoriesFuture = _api.fetchCategories();
    final modifiersFuture = _api.fetchModifierGroups();
    final itemsFuture = _api.fetchMenuItems();
    final branchesRaw = await branchesFuture;
    final categoriesRaw = await categoriesFuture;
    final modifiersRaw = await modifiersFuture;
    final itemsRaw = await itemsFuture;

    final branches =
        branchesRaw.map((json) => MenuBranch.fromJson(json)).toList();
    final categories =
        categoriesRaw.map((json) => MenuCategory.fromJson(json)).toList();
    final modifierGroups =
        modifiersRaw.map((json) => ModifierGroup.fromJson(json)).toList();
    final items =
        itemsRaw.map((json) => MenuItem.fromJson(json)).toList();

    return MenuDataBundle(
      items: items,
      categories: categories,
      modifierGroups: modifierGroups,
      branches: branches,
    );
  }

  Future<MenuCategory> createCategory(MenuCategory category) async {
    final json = await _api.createCategory(category.toJson());
    return MenuCategory.fromJson(json);
  }

  Future<MenuCategory> updateCategory(MenuCategory category) async {
    final json = await _api.updateCategory(category.toJson());
    return MenuCategory.fromJson(json);
  }

  Future<ModifierGroup> createModifierGroup(ModifierGroup group) async {
    final json = await _api.createModifierGroup(group.toJson());
    return ModifierGroup.fromJson(json);
  }

  Future<ModifierGroup> updateModifierGroup(ModifierGroup group) async {
    final json = await _api.updateModifierGroup(group.toJson());
    return ModifierGroup.fromJson(json);
  }

  Future<MenuItem> createMenuItem(MenuItem item) async {
    final json = await _api.createMenuItem(item.toJson());
    return MenuItem.fromJson(json);
  }

  Future<MenuItem> updateMenuItem(MenuItem item) async {
    final json = await _api.updateMenuItem(item.toJson());
    return MenuItem.fromJson(json);
  }
}
