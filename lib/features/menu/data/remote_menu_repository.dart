import 'package:flutter/foundation.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';
import 'package:modular_pos/features/menu/data/dto/menu_composition_dto.dart';
import 'package:modular_pos/features/menu/data/menu_mappers.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class RemoteMenuRepository extends MenuRepository {
  const RemoteMenuRepository(this._api) : super();

  final MenuApi _api;

  void _logIgnoredError(String context, Object error, StackTrace stackTrace) {
    AppLog.e(
      '[RemoteMenuRepository] Ignored error: $context',
      error: error,
      stackTrace: stackTrace,
    );
  }

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
    final branchesRaw = await _api.fetchBranches();
    final includeAllBranches = readLane == MenuReadLane.management;
    final normalizedStatus = status.trim().isEmpty
        ? 'active'
        : status.trim().toLowerCase();

    // Fetch pieces separately to avoid snapshot staleness.
    final categoriesFuture = Future.wait([
      _api.fetchCategories(status: 'active'),
    ]);
    final modifiersFuture = _api.fetchModifierGroups(status: normalizedStatus);
    final itemsFuture = _api.fetchMenuItems(
      includeAllBranches: includeAllBranches,
      status: normalizedStatus,
      categoryId: categoryId,
      search: search,
      limit: limit,
      offset: offset,
      branchId: includeAllBranches ? branchIdFilter : null,
    );
    final categoriesRawGroups = await categoriesFuture;
    final modifiersRaw = await modifiersFuture;
    final itemsRaw = await itemsFuture;
    final categoriesRaw = categoriesRawGroups
        .expand((group) => group)
        .toList(growable: false);

    final branches = branchesRaw
        .map(MenuMappers.toBranch)
        .toList(growable: false);
    final modifierGroups = modifiersRaw
        .where((dto) => _matchesRequestedStatus(dto.status, normalizedStatus))
        .map(MenuMappers.toGroup)
        .toList(growable: false);
    final items = itemsRaw
        .where((dto) => _matchesRequestedStatus(dto.status, normalizedStatus))
        .map(MenuMappers.toItem)
        .toList(growable: false);
    final categories = categoriesRaw
        .map(MenuMappers.toCategory)
        .fold<Map<String, MenuCategory>>({}, (acc, category) {
          acc.putIfAbsent(category.id, () => category);
          return acc;
        })
        .values
        .toList(growable: false);

    return MenuDataBundle(
      items: items,
      categories: categories,
      modifierGroups: modifierGroups,
      branches: branches,
    );
  }

  @override
  Future<List<MenuCategory>> fetchCategoriesOnly({String? status}) async {
    final requestedStatus = (status ?? '').trim().toLowerCase();
    final normalizedStatus = requestedStatus.isEmpty ? 'active' : requestedStatus;
    final categoriesRaw = await _api.fetchCategories(status: normalizedStatus);
    return categoriesRaw
        .where((dto) => _matchesRequestedStatus(dto.status, normalizedStatus))
        .map(MenuMappers.toCategory)
        .toList(growable: false);
  }

  @override
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

    final modifiers = response.modifierGroups
        .map(MenuMappers.toGroup)
        .toList(growable: false);
    final item = MenuMappers.toItem(
      itemDto.copyWith(
        modifierGroupIds: modifiers
            .map((m) => m.id)
            .where((id) => id.isNotEmpty)
            .toList(),
      ),
    );

    return (item, modifiers);
  }

  @override
  Future<List<MenuComponent>> fetchMenuItemComposition(
    String menuItemId,
  ) async {
    final response = await _api.fetchMenuItemWithModifiers(menuItemId);
    return response.baseComponents
        .map(MenuMappers.toCompositionComponent)
        .toList(growable: false);
  }

  @override
  Future<void> upsertMenuItemComposition({
    required String menuItemId,
    required List<MenuComponent> baseComponents,
  }) {
    return _api.upsertMenuItemComposition(
      menuItemId: menuItemId,
      baseComponents: baseComponents
          .map(
            (component) => MenuComponentDto(
              stockItemId: component.stockItemId,
              quantityInBaseUnit: component.quantityInBaseUnit,
              trackingMode: component.trackingMode,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<MenuCompositionEvaluate> evaluateMenuItemComposition({
    required String menuItemId,
    required List<String> selectedModifierOptionIds,
  }) async {
    final dto = await _api.evaluateMenuItemComposition(
      menuItemId: menuItemId,
      selectedModifierOptionIds: selectedModifierOptionIds,
    );
    return MenuMappers.toCompositionEvaluate(dto);
  }

  @override
  Future<List<ModifierGroup>> fetchModifierGroupsOnly({String? status}) async {
    final requestedStatus = (status ?? '').trim().toLowerCase();
    final normalizedStatus = requestedStatus.isEmpty ? 'active' : requestedStatus;
    final modifiersRaw = await _api.fetchModifierGroups(status: normalizedStatus);
    return modifiersRaw
        .where((dto) => _matchesRequestedStatus(dto.status, normalizedStatus))
        .map(MenuMappers.toGroup)
        .toList(growable: false);
  }

  @override
  Future<MenuCategory> createCategory(MenuCategory category) async {
    final payload = {
      'name': category.name,
      'description': category.description,
      'status': category.status,
    };
    final dto = await _api.createCategory(payload);
    return MenuMappers.toCategory(dto);
  }

  @override
  Future<MenuCategory> updateCategory(MenuCategory category) async {
    final payload = {
      'id': category.id,
      'name': category.name,
      'description': category.description,
      'status': category.status,
    };
    final dto = await _api.updateCategory(payload);
    return MenuMappers.toCategory(dto);
  }

  @override
  Future<void> archiveCategory(String categoryId) async {
    await _api.deleteCategory(categoryId);
  }

  @override
  Future<void> restoreCategory(String categoryId) async {
    await _api.restoreCategory(categoryId);
  }

  @override
  Future<ModifierGroup> createModifierGroup(ModifierGroup group) async {
    final payload = {
      'name': group.name,
      'selectionMode': MenuMappers.formatSelectionType(group.selectionType),
      'minSelections': group.minSelections,
      'maxSelections': group.maxSelections,
      'isRequired': group.isRequired ?? false,
    };
    final dto = await _api.createModifierGroup(payload);
    var createdGroup = MenuMappers.toGroup(dto);

    if (group.options.isEmpty) {
      return createdGroup;
    }

    final createdOptions = <ModifierOption>[];
    String? defaultOptionId;
    for (final option in group.options) {
      final optionPayload = {
        'groupId': createdGroup.id,
        'label': option.name,
        'priceDelta': option.priceDelta,
        'componentDeltas': option.componentDeltas
            .map((entry) => entry.toJson())
            .toList(growable: false),
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

  @override
  Future<ModifierGroup> updateModifierGroup(
    ModifierGroup group, {
    ModifierGroup? previous,
  }) async {
    final payload = {
      'id': group.id,
      'name': group.name,
      'selectionMode': MenuMappers.formatSelectionType(group.selectionType),
      'minSelections': group.minSelections,
      'maxSelections': group.maxSelections,
      'isRequired': group.isRequired ?? false,
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
            'priceDelta': option.priceDelta,
            'componentDeltas': option.componentDeltas
                .map((entry) => entry.toJson())
                .toList(growable: false),
            'groupId': group.id,
          });
        } catch (e, st) {
          _logIgnoredError('updateModifierGroup/updateModifierOption', e, st);
        }
        updatedOptions.add(option);
        if (option.isDefault) resolvedDefaultId = option.id;
      } else {
        try {
          final createdDto = await _api.addModifierOption({
            'groupId': group.id,
            'label': option.name,
            'priceDelta': option.priceDelta,
            'componentDeltas': option.componentDeltas
                .map((entry) => entry.toJson())
                .toList(growable: false),
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
          await _api.deleteModifierOption(prev.id, groupId: group.id);
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

  @override
  Future<void> archiveModifierGroup(String groupId) async {
    await _api.deleteModifierGroup(groupId);
  }

  @override
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
    return created.copyWith(
      visibleBranchIds: item.visibleBranchIds,
      branchIds: item.visibleBranchIds,
      modifierGroupIds: item.modifierGroupIds,
    );
  }

  @override
  Future<MenuItem> updateMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
    MenuItem? previous,
  }) async {
    final dto = await _api.updateMenuItem(
      _menuItemPayload(item, previous: previous),
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    final updated = MenuMappers.toItem(dto);
    return updated.copyWith(
      visibleBranchIds: item.visibleBranchIds,
      branchIds: item.visibleBranchIds,
      modifierGroupIds: item.modifierGroupIds,
    );
  }

  @override
  Future<void> archiveMenuItem(String menuItemId) {
    return _api.deleteMenuItem(menuItemId);
  }

  @override
  Future<void> restoreMenuItem(String menuItemId) {
    return _api.restoreMenuItem(menuItemId);
  }

  @override
  Future<void> setMenuItemVisibility({
    required String menuItemId,
    required List<String> visibleBranchIds,
  }) {
    return _api.setItemVisibility(
      menuItemId: menuItemId,
      visibleBranchIds: visibleBranchIds,
    );
  }

  @override
  Future<void> setMenuItemAvailability({
    required String menuItemId,
    required String branchId,
    required bool isAvailable,
  }) {
    return _api.setItemVisibility(
      menuItemId: menuItemId,
      visibleBranchIds: isAvailable ? <String>[branchId] : const <String>[],
    );
  }

  @override
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

  Map<String, dynamic> _menuItemPayload(MenuItem item, {MenuItem? previous}) {
    final visibleBranchIds = item.visibleBranchIds.isNotEmpty
        ? item.visibleBranchIds
        : item.branchIds;
    if (previous == null) {
      return {
        'id': item.id.isEmpty ? null : item.id,
        'name': item.name,
        'basePrice': item.basePrice,
        'status': item.status,
        'categoryId': item.categoryId.isEmpty ? null : item.categoryId,
        'imageUrl': item.imageUrl,
        'modifierGroupIds': item.modifierGroupIds,
        'visibleBranchIds': visibleBranchIds,
      };
    }

    final payload = <String, dynamic>{
      'id': item.id.isEmpty ? null : item.id,
    };
    if (item.name != previous.name) {
      payload['name'] = item.name;
    }
    if (item.basePrice != previous.basePrice) {
      payload['basePrice'] = item.basePrice;
    }
    if (item.status != previous.status) {
      payload['status'] = item.status;
    }
    if (item.categoryId != previous.categoryId) {
      payload['categoryId'] = item.categoryId.isEmpty ? null : item.categoryId;
    }
    if (item.imageUrl != previous.imageUrl) {
      payload['imageUrl'] = item.imageUrl;
    }
    if (!listEquals(item.modifierGroupIds, previous.modifierGroupIds)) {
      payload['modifierGroupIds'] = item.modifierGroupIds;
    }
    if (!listEquals(visibleBranchIds, previous.visibleBranchIds)) {
      payload['visibleBranchIds'] = visibleBranchIds;
    }
    return payload;
  }

  bool _matchesRequestedStatus(String status, String requestedStatus) {
    final normalizedStatus = status.trim().toUpperCase();
    final isArchived =
        normalizedStatus == 'ARCHIVED' ||
        normalizedStatus == 'ARCHIVE' ||
        normalizedStatus == 'INACTIVE';
    switch (requestedStatus.trim().toLowerCase()) {
      case 'active':
        return !isArchived;
      case 'archived':
        return isArchived;
      case 'all':
        return true;
      default:
        return true;
    }
  }
}
