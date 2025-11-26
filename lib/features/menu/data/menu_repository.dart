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

  Future<MenuDataBundle> fetchMenuData({String? branchId}) async {
    final branchesFuture = _api.fetchBranches();
    final categoriesFuture = _api.fetchCategories();
    final modifiersFuture = _api.fetchModifierGroups();
    final itemsFuture = _api.fetchMenuItems(branchId: branchId);
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
    final payload = {
      'name': category.name,
      'description': category.description,
      'isActive': category.isActive,
      'displayOrder': category.displayOrder,
    };
    final json = await _api.createCategory(payload);
    return MenuCategory.fromJson(json);
  }

  Future<MenuCategory> updateCategory(MenuCategory category) async {
    final payload = {
      'id': category.id,
      'name': category.name,
      'description': category.description,
      'isActive': category.isActive,
      'displayOrder': category.displayOrder,
    };
    final json = await _api.updateCategory(payload);
    return MenuCategory.fromJson(json);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _api.deleteCategory(categoryId);
  }

  Future<ModifierGroup> createModifierGroup(ModifierGroup group) async {
    final payload = {
      'name': group.name,
      'selectionType': _formatSelectionType(group.selectionType),
      'pricingBehavior': _formatPricingBehavior(group.pricingBehavior),
      'isRequired': group.isRequired,
    };
    final json = await _api.createModifierGroup(payload);
    var createdGroup = ModifierGroup.fromJson(json);

    if (group.options.isEmpty) {
      return createdGroup;
    }

    final createdOptions = <ModifierOption>[];
    String? defaultOptionId;
    for (final option in group.options) {
      final isDefault =
          group.defaultOptionId != null && group.defaultOptionId == option.id;
      final optionPayload = {
        'modifierGroupId': createdGroup.id,
        'label': option.name,
        'priceAdjustmentUsd': option.price,
        'isDefault': isDefault,
      };
      final optionJson = await _api.addModifierOption(optionPayload);
      if (optionJson.isEmpty) continue;
      final createdOption = ModifierOption.fromJson(optionJson);
      if (createdOption.isDefault) {
        defaultOptionId = createdOption.id;
      }
      createdOptions.add(createdOption);
    }

    if (createdOptions.isNotEmpty) {
      createdGroup = createdGroup.copyWith(
        options: createdOptions,
        defaultOptionId: defaultOptionId ?? createdGroup.defaultOptionId,
      );
    }

    return createdGroup;
  }

  Future<ModifierGroup> updateModifierGroup(ModifierGroup group) async {
    final payload = {
      'id': group.id,
      'name': group.name,
      'selectionType': _formatSelectionType(group.selectionType),
      'pricingBehavior': _formatPricingBehavior(group.pricingBehavior),
      'isRequired': group.isRequired,
    };
    final json = await _api.updateModifierGroup(payload);
    return ModifierGroup.fromJson(json);
  }

  Future<MenuItem> createMenuItem(MenuItem item) async {
    final json = await _api.createMenuItem(_menuItemPayload(item));
    return MenuItem.fromJson(json);
  }

  Future<MenuItem> updateMenuItem(MenuItem item) async {
    final json = await _api.updateMenuItem(_menuItemPayload(item));
    return MenuItem.fromJson(json);
  }

  Future<void> deleteMenuItem(String menuItemId) {
    return _api.deleteMenuItem(menuItemId);
  }

  Future<void> setMenuItemAvailability({
    required String menuItemId,
    required String branchId,
    required bool isAvailable,
  }) {
    return _api.setBranchAvailability(
      menuItemId: menuItemId,
      branchId: branchId,
      isAvailable: isAvailable,
    );
  }

  Future<void> setMenuItemPriceOverride({
    required String menuItemId,
    required String branchId,
    required double priceUsd,
  }) {
    return _api.setPriceOverride(
      menuItemId: menuItemId,
      branchId: branchId,
      priceUsd: priceUsd,
    );
  }

  Map<String, dynamic> _menuItemPayload(MenuItem item) {
    final branchId =
        item.branchIds.isNotEmpty ? item.branchIds.first : null;
    return {
      'id': item.id.isEmpty ? null : item.id,
      'categoryId': item.categoryId,
      'branchId': branchId,
      'name': item.name,
      'description': item.description,
      'priceUsd': item.price,
      'imageUrl': item.imageUrl,
      'modifierGroupIds': item.modifierGroupIds,
    };
  }

  String _formatSelectionType(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'MULTIPLE' || normalized == 'MULTI') {
      return 'MULTIPLE';
    }
    return 'SINGLE';
  }

  String? _formatPricingBehavior(String value) {
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
