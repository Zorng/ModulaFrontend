import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';
import 'package:modular_pos/features/menu/data/menu_mappers.dart';
import 'package:modular_pos/features/menu/data/dto/menu_branch_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';
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

  void _logIgnoredError(String context, Object error, StackTrace stackTrace) {
    AppLog.e(
      '[MenuRepository] Ignored error: $context',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<MenuDataBundle> fetchMenuData({
    String? branchId,
    List<String>? branchIdsForHydration,
  }) async {
    final branchesRaw = await _api.fetchBranches();

    // Fetch pieces separately to avoid snapshot staleness.
    final categoriesFuture = _api.fetchCategories();
    final modifiersFuture = _api.fetchModifierGroups();
    final itemsFuture = _api.fetchMenuItems(branchId: branchId);
    final categoriesRaw = await categoriesFuture;
    final modifiersRaw = await modifiersFuture;
    List<MenuItemDto> itemsRaw = const [];
    try {
      itemsRaw = await itemsFuture;
      if (branchId != null && branchId.isNotEmpty) {
        itemsRaw = _ensureBranchOnItems(itemsRaw, branchId);
      } else {
        final fallbackBranchIds =
            branchIdsForHydration ?? _extractBranchIds(branchesRaw);
        itemsRaw = await _hydrateBranchAssignments(itemsRaw, fallbackBranchIds);
      }
    } catch (e, st) {
      _logIgnoredError('fetchMenuData/items', e, st);
      // If menu items fail to load (e.g., invalid branch), still return categories/modifiers/branches.
      itemsRaw = const [];
    }

    final branches = branchesRaw
        .map(MenuMappers.toBranch)
        .toList(growable: false);
    final categories = categoriesRaw
        .where((dto) => dto.isActive)
        .map(MenuMappers.toCategory)
        .toList(growable: false);
    final modifierGroups = await _hydrateModifierOptions(
      modifiersRaw.where((dto) => dto.isActive).toList(growable: false),
    );
    final items = itemsRaw
        .where((dto) => dto.isActive)
        .map(MenuMappers.toItem)
        .toList(growable: false);

    return MenuDataBundle(
      items: items,
      categories: categories,
      modifierGroups: modifierGroups,
      branches: branches,
    );
  }

  Future<List<MenuCategory>> fetchCategoriesOnly({bool? isActive}) async {
    final categoriesRaw = await _api.fetchCategories(isActive: isActive);
    return categoriesRaw.map(MenuMappers.toCategory).toList(growable: false);
  }

  Future<(MenuItem, List<ModifierGroup>)> fetchItemWithModifiers(
    String menuItemId, {
    bool retrying = false,
  }) async {
    final response = await _api.fetchMenuItemWithModifiers(menuItemId);
    final itemDto = response.item;
    if (itemDto.id.isEmpty) {
      return (
        const MenuItem(id: '', name: '', categoryId: '', price: 0),
        <ModifierGroup>[],
      );
    }

    final modifierDtos = response.modifierGroups;
    if (modifierDtos.isEmpty && !retrying) {
      return fetchItemWithModifiers(menuItemId, retrying: true);
    }

    final modifiers =
        modifierDtos.map(MenuMappers.toGroup).toList(growable: false);
    final item = MenuMappers.toItem(
      itemDto.copyWith(
        modifierGroupIds:
            modifiers.map((m) => m.id).where((id) => id.isNotEmpty).toList(),
      ),
    );

    return (item, modifiers);
  }

  Future<List<ModifierGroup>> fetchModifierGroupsOnly() async {
    final modifiersRaw = await _api.fetchModifierGroups();
    return _hydrateModifierOptions(modifiersRaw);
  }

  Future<MenuCategory> createCategory(MenuCategory category) async {
    final payload = {
      'name': category.name,
      'description': category.description,
      'isActive': category.isActive,
      'displayOrder': category.displayOrder,
    };
    final dto = await _api.createCategory(payload);
    return MenuMappers.toCategory(dto);
  }

  Future<MenuCategory> updateCategory(MenuCategory category) async {
    final payload = {
      'id': category.id,
      'name': category.name,
      'description': category.description,
      'isActive': category.isActive,
      'displayOrder': category.displayOrder,
    };
    final dto = await _api.updateCategory(payload);
    return MenuMappers.toCategory(dto);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _api.deleteCategory(categoryId);
  }

  Future<ModifierGroup> createModifierGroup(ModifierGroup group) async {
    final payload = {
      'name': group.name,
      'selectionType': MenuMappers.formatSelectionType(group.selectionType),
      'pricingBehavior': MenuMappers.formatPricingBehavior(
        group.pricingBehavior,
      ),
      'isRequired': group.isRequired,
    };
    final dto = await _api.createModifierGroup(payload);
    var createdGroup = MenuMappers.toGroup(dto);

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
      final createdOptionDto = await _api.addModifierOption(optionPayload);
      final createdOption = MenuMappers.toOption(createdOptionDto);
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

  Future<ModifierGroup> updateModifierGroup(
    ModifierGroup group, {
    ModifierGroup? previous,
  }) async {
    final payload = {
      'id': group.id,
      'name': group.name,
      'selectionType': MenuMappers.formatSelectionType(group.selectionType),
      'pricingBehavior': MenuMappers.formatPricingBehavior(
        group.pricingBehavior,
      ),
      'isRequired': group.isRequired,
    };
    final dto = await _api.updateModifierGroup(payload);
    final baseGroup = MenuMappers.toGroup(dto);

    final prevOptionsById = {
      for (final option in (previous?.options ?? const <ModifierOption>[]))
        option.id: option,
    };

    final updatedOptions = <ModifierOption>[];
    String? resolvedDefaultId =
        group.defaultOptionId ?? baseGroup.defaultOptionId;

    for (final option in group.options) {
      final isExisting =
          option.id.isNotEmpty && prevOptionsById.containsKey(option.id);
      if (isExisting) {
        try {
          await _api.updateModifierOption(option.id, {
            'label': option.name,
            'name': option.name,
            'priceAdjustmentUsd': option.price,
            'isDefault': option.isDefault,
            'modifierGroupId': group.id,
          });
        } catch (e, st) {
          _logIgnoredError('updateModifierGroup/updateModifierOption', e, st);
        }
        updatedOptions.add(option);
        if (option.isDefault) resolvedDefaultId = option.id;
      } else {
        try {
          final createdDto = await _api.addModifierOption({
            'modifierGroupId': group.id,
            'label': option.name,
            'priceAdjustmentUsd': option.price,
            'isDefault': option.isDefault,
          });
          final created = MenuMappers.toOption(createdDto);
          updatedOptions.add(created);
          if (option.isDefault || created.isDefault) {
            resolvedDefaultId = created.id;
          }
        } catch (e, st) {
          _logIgnoredError('updateModifierGroup/addModifierOption', e, st);
          updatedOptions.add(option);
        }
      }
    }

    final newIds = group.options.map((opt) => opt.id).toSet();
    for (final prev in prevOptionsById.values) {
      if (prev.id.isEmpty) continue;
      if (!newIds.contains(prev.id)) {
        try {
          await _api.deleteModifierOption(prev.id);
        } catch (e, st) {
          _logIgnoredError('updateModifierGroup/deleteModifierOption', e, st);
        }
      }
    }

    return baseGroup.copyWith(
      options: updatedOptions,
      defaultOptionId: resolvedDefaultId,
    );
  }

  Future<void> deleteModifierGroup(String groupId) async {
    await _api.deleteModifierGroup(groupId);
  }

  Future<MenuItem> createMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final dto = await _api.createMenuItem(
      _menuItemPayload(item),
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    final created = MenuMappers.toItem(dto);
    await _syncBranchAvailability(created.id, item.branchIds);
    await _syncModifierAttachments(created.id, item.modifierGroupIds);
    return created.copyWith(
      branchIds: item.branchIds,
      modifierGroupIds: item.modifierGroupIds,
    );
  }

  Future<MenuItem> updateMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
    MenuItem? previous,
  }) async {
    final dto = await _api.updateMenuItem(
      _menuItemPayload(item),
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    final updated = MenuMappers.toItem(dto);
    await _syncBranchAvailability(updated.id, item.branchIds);
    await _syncModifierAttachmentsDiff(
      menuItemId: updated.id,
      previousIds: previous?.modifierGroupIds ?? const [],
      nextIds: item.modifierGroupIds,
    );
    return updated.copyWith(
      branchIds: item.branchIds,
      modifierGroupIds: item.modifierGroupIds,
    );
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
    final branchId = item.branchIds.isNotEmpty ? item.branchIds.first : null;
    return {
      'id': item.id.isEmpty ? null : item.id,
      if (item.categoryId.isNotEmpty) 'categoryId': item.categoryId,
      'branchId': branchId,
      'name': item.name,
      'description': item.description,
      'priceUsd': item.price,
      'imageUrl': item.imageUrl,
      'modifierGroupIds': item.modifierGroupIds,
    };
  }

  Future<void> _syncBranchAvailability(
    String menuItemId,
    List<String> branchIds,
  ) async {
    if (menuItemId.isEmpty || branchIds.isEmpty) return;
    final uniqueBranchIds = branchIds.toSet();
    final futures = <Future<void>>[];
    for (final branchId in uniqueBranchIds) {
      if (branchId.isEmpty) continue;
      futures.add(
        _api.setBranchAvailability(
          menuItemId: menuItemId,
          branchId: branchId,
          isAvailable: true,
        ),
      );
    }
    await Future.wait(futures);
  }

  Future<void> _syncModifierAttachments(
    String menuItemId,
    List<String> modifierGroupIds,
  ) async {
    if (menuItemId.isEmpty || modifierGroupIds.isEmpty) return;
    final uniqueModifierIds = modifierGroupIds.toSet();
    final futures = <Future<void>>[];
    for (final modifierId in uniqueModifierIds) {
      if (modifierId.isEmpty) continue;
      futures.add(
        _api.attachModifierToItem(menuItemId, {'modifierGroupId': modifierId}),
      );
    }
    await Future.wait(futures);
  }

  Future<void> _syncModifierAttachmentsDiff({
    required String menuItemId,
    required List<String> previousIds,
    required List<String> nextIds,
  }) async {
    if (menuItemId.isEmpty) return;
    final prev = previousIds.toSet();
    final next = nextIds.toSet();
    final additions = next.difference(prev);
    final removals = prev.difference(next);

    final futures = <Future<void>>[];
    for (final id in additions) {
      if (id.isEmpty) continue;
      futures.add(
        _api.attachModifierToItem(menuItemId, {'modifierGroupId': id}),
      );
    }
    for (final id in removals) {
      if (id.isEmpty) continue;
      futures.add(
        _api.detachModifierFromItem(
          menuItemId: menuItemId,
          modifierGroupId: id,
        ),
      );
    }
    await Future.wait(futures);
  }

  List<MenuItemDto> _ensureBranchOnItems(
    List<MenuItemDto> items,
    String branchId,
  ) {
    if (branchId.isEmpty) return items;
    return items
        .map((item) {
          if (item.branchIds.contains(branchId)) return item;
          return item.copyWith(branchIds: [...item.branchIds, branchId]);
        })
        .toList(growable: false);
  }

  Future<List<MenuItemDto>> _hydrateBranchAssignments(
    List<MenuItemDto> baseItems,
    List<String> branchIds,
  ) async {
    if (baseItems.isEmpty || branchIds.isEmpty) return baseItems;
    final assignments = <String, Set<String>>{};
    await Future.wait(
      branchIds.map((branchId) async {
        try {
          final branchItems = await _api.fetchMenuItems(branchId: branchId);
          for (final raw in branchItems) {
            final itemId = raw.id;
            if (itemId.isEmpty) continue;
            assignments.putIfAbsent(itemId, () => <String>{}).add(branchId);
          }
        } catch (e, st) {
          _logIgnoredError('_hydrateBranchAssignments/$branchId', e, st);
          // Ignore branch failures—items will simply lack branch info for that branch.
        }
      }),
    );

    if (assignments.isEmpty) return baseItems;
    return baseItems.map((item) {
      final itemId = item.id;
      if (itemId.isEmpty) return item;
      final assignedBranches = assignments[itemId];
      if (assignedBranches == null || assignedBranches.isEmpty) return item;
      final existing = item.branchIds.toSet();
      existing.addAll(assignedBranches);
      return item.copyWith(branchIds: existing.toList(growable: false));
    }).toList(growable: false);
  }

  List<String> _extractBranchIds(List<MenuBranchDto> branches) {
    return branches.map((b) => b.id).where((id) => id.isNotEmpty).toList();
  }

  Future<List<ModifierGroup>> _hydrateModifierOptions(
    List<ModifierGroupDto> modifiersRaw,
  ) async {
    final groups =
        modifiersRaw.map(MenuMappers.toGroup).toList(growable: false);
    if (groups.isEmpty) return groups;

    final futures = groups.map((group) async {
      if (group.options.isNotEmpty || group.id.isEmpty) return group;
      try {
        final optionsRaw = await _api.fetchModifierOptions(group.id);
        final options = optionsRaw
            .where((o) => o.isActive)
            .map(MenuMappers.toOption)
            .toList(growable: false);
        return group.copyWith(options: options);
      } catch (e, st) {
        _logIgnoredError('_hydrateModifierOptions/${group.id}', e, st);
        return group;
      }
    });

    return Future.wait(futures);
  }
}
