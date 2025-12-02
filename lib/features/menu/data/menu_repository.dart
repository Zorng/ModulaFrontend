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
    List<Map<String, dynamic>> itemsRaw = const [];
    try {
      itemsRaw = await itemsFuture;
      if (branchId != null && branchId.isNotEmpty) {
        itemsRaw = _ensureBranchOnItems(itemsRaw, branchId);
      } else {
        final fallbackBranchIds =
            branchIdsForHydration ?? _extractBranchIds(branchesRaw);
        itemsRaw = await _hydrateBranchAssignments(
          itemsRaw,
          fallbackBranchIds,
        );
      }
    } catch (_) {
      // If menu items fail to load (e.g., invalid branch), still return categories/modifiers/branches.
      itemsRaw = const [];
    }

    final branches =
        branchesRaw.map((json) => MenuBranch.fromJson(json)).toList();
    final categories = categoriesRaw
        .where(_isActive)
        .map((json) => MenuCategory.fromJson(json))
        .toList();
    final modifierGroups = await _hydrateModifierOptions(
      modifiersRaw.where(_isActive).toList(),
    );
    final items = itemsRaw
        .where(_isActive)
        .map((json) => MenuItem.fromJson(json))
        .toList();

    return MenuDataBundle(
      items: items,
      categories: categories,
      modifierGroups: modifierGroups,
      branches: branches,
    );
  }

  Future<List<MenuCategory>> fetchCategoriesOnly({bool? isActive}) async {
    final categoriesRaw = await _api.fetchCategories(isActive: isActive);
    return categoriesRaw.map((json) => MenuCategory.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> fetchMenuSnapshot(String branchId) {
    return _api.fetchMenuSnapshot(branchId);
  }

  Future<(MenuItem, List<ModifierGroup>)> fetchItemWithModifiers(
    String menuItemId, {
    bool retrying = false,
  }) async {
    final raw = await _api.fetchMenuItemWithModifiers(menuItemId);
    // Backend may wrap the payload under "data" or return the item at the top level.
    final payload = raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'])
        : Map<String, dynamic>.from(raw);

    if (payload.isEmpty) {
      return (
        const MenuItem(id: '', name: '', categoryId: '', price: 0),
        <ModifierGroup>[]
      );
    }

    final rawModifiers = payload['modifiers'] as List<dynamic>? ?? const [];
    final modifiers = <ModifierGroup>[];
    if (rawModifiers.isNotEmpty) {
      for (final entry in rawModifiers) {
        if (entry is! Map) continue;
        final entryMap = Map<String, dynamic>.from(entry);
        final groupJson =
            Map<String, dynamic>.from(entryMap['group'] as Map? ?? const {});
        final optionsJson = entryMap['options'] as List<dynamic>? ?? const [];
        final options = optionsJson.map((opt) {
          if (opt is! Map) return const ModifierOption(id: '', name: '', price: 0);
          final optMap = Map<String, dynamic>.from(opt);
          final priceRaw = optMap['priceAdjustmentUsd'];
          final parsedPrice = priceRaw is num
              ? priceRaw.toDouble()
              : double.tryParse(priceRaw?.toString() ?? '') ?? 0;
          return ModifierOption(
            id: optMap['id']?.toString() ?? '',
            name: optMap['label']?.toString() ?? 'Option',
            price: parsedPrice,
            isDefault: optMap['isDefault'] as bool? ?? false,
          );
        }).where((opt) => opt.id.isNotEmpty).toList();
        final defaultOpt = options.firstWhere(
          (o) => o.isDefault,
          orElse: () =>
              options.isNotEmpty ? options.first : const ModifierOption(id: '', name: '', price: 0),
        );
        final groupId = groupJson['id']?.toString() ?? '';
        if (groupId.isEmpty) continue;
        modifiers.add(
          ModifierGroup(
            id: groupId,
            name: groupJson['name']?.toString() ?? 'Modifier Group',
            selectionType:
                (groupJson['selectionType']?.toString().toLowerCase() ?? 'single'),
            pricingBehavior: 'addon',
            options: options,
            defaultOptionId: defaultOpt.id.isNotEmpty ? defaultOpt.id : null,
            isRequired: entryMap['isRequired'] as bool?,
          ),
        );
      }
    } else if (!retrying) {
      // Retry once when backend occasionally responds without modifiers.
      return fetchItemWithModifiers(menuItemId, retrying: true);
    } else if (rawModifiers.isNotEmpty && modifiers.isEmpty) {
      throw Exception('Failed to parse modifiers for item $menuItemId');
    }

    final item = MenuItem(
      id: payload['id']?.toString() ?? '',
      categoryId: payload['categoryId']?.toString() ?? '',
      name: payload['name']?.toString() ?? 'Menu Item',
      description: payload['description']?.toString() ?? '',
      price: (payload['priceUsd'] as num?)?.toDouble() ?? 0,
      imageUrl: payload['imageUrl']?.toString(),
      modifierGroupIds: modifiers.map((m) => m.id).where((id) => id.isNotEmpty).toList(),
      branchIds: const [],
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

  Future<ModifierGroup> updateModifierGroup(
    ModifierGroup group, {
    ModifierGroup? previous,
  }) async {
    final payload = {
      'id': group.id,
      'name': group.name,
      'selectionType': _formatSelectionType(group.selectionType),
      'pricingBehavior': _formatPricingBehavior(group.pricingBehavior),
      'isRequired': group.isRequired,
    };
    final json = await _api.updateModifierGroup(payload);
    final baseGroup = ModifierGroup.fromJson(json);

    final prevOptionsById = {
      for (final option in (previous?.options ?? const <ModifierOption>[]))
        option.id: option,
    };

    final updatedOptions = <ModifierOption>[];
    String? resolvedDefaultId = group.defaultOptionId ?? baseGroup.defaultOptionId;

    for (final option in group.options) {
      final isExisting = option.id.isNotEmpty && prevOptionsById.containsKey(option.id);
      if (isExisting) {
        try {
          await _api.updateModifierOption(
            option.id,
            {
              'label': option.name,
              'name': option.name,
              'priceAdjustmentUsd': option.price,
              'isDefault': option.isDefault,
              'modifierGroupId': group.id,
            },
          );
        } catch (_) {}
        updatedOptions.add(option);
        if (option.isDefault) resolvedDefaultId = option.id;
      } else {
        try {
          final createdJson = await _api.addModifierOption({
            'modifierGroupId': group.id,
            'label': option.name,
            'priceAdjustmentUsd': option.price,
            'isDefault': option.isDefault,
          });
          final created = ModifierOption.fromJson(createdJson);
          updatedOptions.add(created);
          if (option.isDefault || created.isDefault) {
            resolvedDefaultId = created.id;
          }
        } catch (_) {
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
        } catch (_) {}
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
    final json =
        await _api.createMenuItem(
      _menuItemPayload(item),
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    final created = MenuItem.fromJson(json);
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
    final json =
        await _api.updateMenuItem(
      _menuItemPayload(item),
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    final updated = MenuItem.fromJson(json);
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
        _api.attachModifierToItem(
          menuItemId,
          {'modifierGroupId': modifierId},
        ),
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
        _api.attachModifierToItem(
          menuItemId,
          {'modifierGroupId': id},
        ),
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

  String _formatSelectionType(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'MULTIPLE' || normalized == 'MULTI') {
      return 'MULTI';
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

  Map<String, dynamic> _normalizeModifierJson(Map<String, dynamic> json) {
    if (json.containsKey('props') && json['props'] is Map) {
      final props =
          Map<String, dynamic>.from(json['props'] as Map);
      final remainder = Map<String, dynamic>.from(json)..remove('props');
      return {...props, ...remainder};
    }
    return json;
  }

  List<Map<String, dynamic>> _ensureBranchOnItems(
    List<Map<String, dynamic>> items,
    String branchId,
  ) {
    if (branchId.isEmpty) return items;
    return items.map((item) {
      final existing = (item['branchIds'] as List?)
              ?.map((e) => e.toString())
              .toSet() ??
          <String>{};
      if (existing.contains(branchId)) return item;
      return {
        ...item,
        'branchIds': [...existing, branchId],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _hydrateBranchAssignments(
    List<Map<String, dynamic>> baseItems,
    List<String> branchIds,
  ) async {
    if (baseItems.isEmpty || branchIds.isEmpty) return baseItems;
    final assignments = <String, Set<String>>{};
    await Future.wait(
      branchIds.map((branchId) async {
        try {
          final branchItems =
              await _api.fetchMenuItems(branchId: branchId);
          for (final raw in branchItems) {
            final itemId = raw['id']?.toString();
            if (itemId == null || itemId.isEmpty) continue;
            assignments.putIfAbsent(itemId, () => <String>{}).add(branchId);
          }
        } catch (_) {
          // Ignore branch failures—items will simply lack branch info for that branch.
        }
      }),
    );

    if (assignments.isEmpty) return baseItems;
    return baseItems.map((item) {
      final itemId = item['id']?.toString();
      if (itemId == null || itemId.isEmpty) return item;
      final assignedBranches = assignments[itemId];
      if (assignedBranches == null || assignedBranches.isEmpty) return item;
      final existing = (item['branchIds'] as List?)
              ?.map((e) => e.toString())
              .toSet() ??
          <String>{};
      existing.addAll(assignedBranches);
      return {
        ...item,
        'branchIds': existing.toList(),
      };
    }).toList();
  }

  List<String> _extractBranchIds(List<Map<String, dynamic>> branches) {
    return branches
        .map((branch) => branch['id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();
  }

  Future<List<ModifierGroup>> _hydrateModifierOptions(
    List<Map<String, dynamic>> modifiersRaw,
  ) async {
    final groups = modifiersRaw
        .map(_normalizeModifierJson)
        .where(_isActive)
        .map(ModifierGroup.fromJson)
        .toList();
    if (groups.isEmpty) return groups;

    final futures = groups.map((group) async {
      if (group.options.isNotEmpty || group.id.isEmpty) return group;
      try {
        final optionsRaw = await _api.fetchModifierOptions(group.id);
        final options = optionsRaw
            .map(_normalizeOptionJson)
            .where(_isActive)
            .map(ModifierOption.fromJson)
            .toList();
        return group.copyWith(options: options);
      } catch (_) {
        return group;
      }
    });

    return Future.wait(futures);
  }

  Map<String, dynamic> _normalizeOptionJson(Map<String, dynamic> json) {
    if (json.containsKey('props') && json['props'] is Map) {
      final props = Map<String, dynamic>.from(json['props'] as Map);
      final remainder = Map<String, dynamic>.from(json)..remove('props');
      return {...remainder, ...props};
    }
    return json;
  }

  bool _isActive(Map<String, dynamic> json) {
    final normalized = _normalizeModifierJson(json);
    final value = normalized['isActive'];
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return !(lower == 'false' || lower == '0');
    }
    return true;
  }

  MenuDataBundle _bundleFromSnapshot(
    Map<String, dynamic> snapshot,
    String branchId,
    List<Map<String, dynamic>> branchesRaw, {
    List<String>? overrideBranchIds,
  }) {
    final branchList =
        branchesRaw.map((json) => MenuBranch.fromJson(json)).toList();
    final categoriesRaw = snapshot['categories'] as List<dynamic>? ?? const [];
    final categories = <MenuCategory>[];
    final items = <MenuItem>[];
    final modifierMap = <String, Map<String, dynamic>>{};

    for (final rawCategory in categoriesRaw) {
      if (rawCategory is! Map<String, dynamic>) continue;
      if (!_isActive(rawCategory)) continue;
      final category = MenuCategory.fromJson(rawCategory);
      categories.add(category);
      final itemList = rawCategory['items'] as List<dynamic>? ?? const [];
      for (final rawItem in itemList) {
        if (rawItem is! Map<String, dynamic>) continue;
        final normalizedItem = _normalizeModifierJson(rawItem);
        if (!_isActive(normalizedItem)) continue;
        final itemMap = Map<String, dynamic>.from(normalizedItem)
          ..putIfAbsent('categoryId', () => category.id)
          ..putIfAbsent('branchIds', () => overrideBranchIds ?? [branchId]);
        items.add(MenuItem.fromJson(itemMap));

        final mods = normalizedItem['modifiers'] as List<dynamic>? ?? const [];
        for (final mod in mods) {
          if (mod is! Map<String, dynamic>) continue;
          final normalizedMod = _normalizeModifierJson(mod);
          if (!_isActive(normalizedMod)) continue;
          final modId = normalizedMod['groupId']?.toString() ??
              normalizedMod['id']?.toString() ??
              '';
          if (modId.isEmpty) continue;
          final existing = modifierMap[modId];
          final existingOptions =
              (existing?['options'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>()
                  .map(_normalizeOptionJson)
                  .where(_isActive)
                  .toList();
          final newOptions =
              (normalizedMod['options'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>()
                  .map(_normalizeOptionJson)
                  .where(_isActive)
                  .toList();

          final mergedOptions = <String, Map<String, dynamic>>{};
          for (final opt in existingOptions.whereType<Map<String, dynamic>>()) {
            final id = opt['id']?.toString() ?? '';
            if (id.isEmpty) continue;
            mergedOptions[id] = opt;
          }
          for (final opt in newOptions) {
            final id = opt['id']?.toString() ?? '';
            if (id.isEmpty) continue;
            mergedOptions[id] = opt;
          }

          modifierMap[modId] = {
            'id': modId,
            'name': normalizedMod['groupName'] ??
                normalizedMod['name'] ??
                existing?['name'] ??
                'Modifier Group',
            'selectionType': (normalizedMod['selectionType'] ??
                    existing?['selectionType'] ??
                    'single')
                .toString(),
            'pricingBehavior':
                (normalizedMod['pricingBehavior'] ??
                        existing?['pricingBehavior'] ??
                        'addon')
                    .toString(),
            'options': mergedOptions.values.toList(),
            'defaultOptionId':
                normalizedMod['defaultOptionId'] ?? existing?['defaultOptionId'],
            'isRequired':
                normalizedMod['isRequired'] ?? existing?['isRequired'],
          };
        }
      }
    }

    final modifierGroups = modifierMap.values
        .map((json) => ModifierGroup.fromJson(_normalizeModifierJson(json)))
        .toList();

    return MenuDataBundle(
      items: items,
      categories: categories,
      modifierGroups: modifierGroups,
      branches: branchList,
    );
  }
}
