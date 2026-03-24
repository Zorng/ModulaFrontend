import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';
import 'package:modular_pos/features/menu/data/menu_cache_store.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item_detail.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/menu_modifier_option_effect.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';

/// Provider for the menu viewmodel.
final menuViewModelProvider = NotifierProvider<MenuViewModel, MenuState>(
  MenuViewModel.new,
);

final menuRequestTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 12),
);

class MenuViewModel extends Notifier<MenuState> {
  MenuRepository get _menuRepository => ref.read(menuRepositoryProvider);
  MenuCacheStore get _cache => ref.read(menuCacheStoreProvider);
  Duration get _requestTimeout => ref.read(menuRequestTimeoutProvider);

  ({String message, String? code}) _mapError(Object error) {
    if (error is TimeoutException) {
      return (
        message: 'Menu request timed out. Check your connection and try again.',
        code: 'OFFLINE_UNREACHABLE',
      );
    }
    if (error is ApiClientException) {
      return (message: error.message, code: error.code);
    }
    if (error is MenuApiException) {
      return (message: error.message, code: error.code);
    }
    return (message: error.toString(), code: null);
  }

  void _setOperationError(Object error) {
    final mapped = _mapError(error);
    state = state.copyWith(error: mapped.message, errorCode: mapped.code);
  }

  void _clearOperationError() {
    state = state.copyWith(error: null, errorCode: null);
  }

  ({String message, String? code}) _mapCompositionError(Object error) {
    final mapped = _mapError(error);
    final code = (mapped.code ?? '').trim().toUpperCase();
    switch (code) {
      case 'ENTITLEMENT_BLOCKED':
        return (
          message: 'Composition is blocked by current entitlement.',
          code: code,
        );
      case 'ENTITLEMENT_READ_ONLY':
        return (
          message: 'Composition is read-only for current entitlement.',
          code: code,
        );
      case 'INVENTORY_ENTITLEMENT_REQUIRED_FOR_TRACKED_COMPONENTS':
        return (
          message: 'Tracked components require inventory entitlement.',
          code: code,
        );
      default:
        return (message: mapped.message, code: mapped.code);
    }
  }

  void _setCompositionLoading(String menuItemId, bool isLoading) {
    state = state.copyWith(
      detailLoadingByItemId: {
        ...state.detailLoadingByItemId,
        menuItemId: isLoading,
      },
      compositionLoadingByItem: {
        ...state.compositionLoadingByItem,
        menuItemId: isLoading,
      },
    );
  }

  void _setCompositionError(String menuItemId, Object error) {
    final mapped = _mapCompositionError(error);
    final compositionErrorCodes = Map<String, String>.from(
      state.compositionErrorCodes,
    )..remove(menuItemId);
    final normalizedCode = (mapped.code ?? '').trim();
    if (normalizedCode.isNotEmpty) {
      compositionErrorCodes[menuItemId] = normalizedCode;
    }
    state = state.copyWith(
      detailErrorsByItemId: {
        ...state.detailErrorsByItemId,
        menuItemId: mapped.message,
      },
      compositionErrors: {
        ...state.compositionErrors,
        menuItemId: mapped.message,
      },
      compositionLoadedByItem: {
        ...state.compositionLoadedByItem,
        menuItemId: true,
      },
      compositionErrorCodes: compositionErrorCodes,
      error: mapped.message,
      errorCode: mapped.code,
    );
  }

  void _setModifierOptionEffectsLoading(String menuItemId, bool isLoading) {
    state = state.copyWith(
      modifierOptionEffectsLoadingByItemId: {
        ...state.modifierOptionEffectsLoadingByItemId,
        menuItemId: isLoading,
      },
    );
  }

  void _setModifierOptionEffectsError(String menuItemId, Object error) {
    final mapped = _mapCompositionError(error);
    state = state.copyWith(
      modifierOptionEffectsErrorsByItemId: {
        ...state.modifierOptionEffectsErrorsByItemId,
        menuItemId: mapped.message,
      },
      error: mapped.message,
      errorCode: mapped.code,
    );
  }

  @override
  MenuState build() {
    return const MenuState();
  }

  Future<void> loadMenu({
    String? branchId,
    String? status,
    MenuReadLane readLane = MenuReadLane.management,
  }) async {
    final selectedStatus = _normalizeStatusFilter(
      status ?? state.selectedStatus,
    );
    final requestedScope = _resolveCacheScope(
      branchId: branchId,
      readLane: readLane,
      status: selectedStatus,
    );
    try {
      state = state.copyWith(isLoading: true, error: null, errorCode: null);
      final userBranches = _resolveUserBranches();
      final requestedBranchFilter = (branchId ?? state.selectedBranchId).trim();
      final branchIdFilter =
          requestedBranchFilter.isEmpty || requestedBranchFilter == 'all'
          ? null
          : requestedBranchFilter;
      final selectedBranch = branchIdFilter ?? 'all';
      final selectedCategoryId = selectedStatus == 'archived'
          ? 'all'
          : state.selectedCategoryId;
      final searchQuery = state.searchQuery;
      if (requestedScope != null) {
        final cached = await _cache.read(requestedScope);
        if (_sameScope(
              requestedScope,
              _resolveCacheScope(
                branchId: branchId,
                readLane: readLane,
                status: selectedStatus,
              ),
            ) &&
            _hasMenuBundle(cached)) {
          final branches = userBranches.isNotEmpty
              ? userBranches
              : cached!.branches;
          state = state.copyWith(
            isLoading: true,
            allItems: cached!.items,
            filteredItems: _applyFilters(
              items: cached.items,
              categoryId: selectedCategoryId,
              branchId: selectedBranch,
              query: searchQuery,
            ),
            categories: cached.categories,
            modifierGroups: cached.modifierGroups,
            branches: branches,
            selectedCategoryId: selectedCategoryId,
            selectedBranchId: selectedBranch,
            selectedStatus: selectedStatus,
            searchQuery: searchQuery,
            error: null,
            errorCode: null,
          );
        }
      }
      final bundle = await _withTimeout(
        _menuRepository.fetchMenuData(
          readLane: readLane,
          status: selectedStatus,
          branchIdFilter: branchIdFilter,
        ),
      );
      if (!_sameScope(
        requestedScope,
        _resolveCacheScope(
          branchId: branchId,
          readLane: readLane,
          status: selectedStatus,
        ),
      )) {
        return;
      }
      if (requestedScope != null) {
        await _cache.write(scope: requestedScope, bundle: bundle);
      }
      final categories =
          selectedStatus == 'archived' && state.categories.isNotEmpty
          ? state.categories
          : bundle.categories;
      final branches = userBranches.isNotEmpty ? userBranches : bundle.branches;

      final filteredItems = _applyFilters(
        items: bundle.items,
        categoryId: selectedCategoryId,
        branchId: selectedBranch,
        query: searchQuery,
      );

      state = state.copyWith(
        isLoading: false,
        allItems: bundle.items,
        filteredItems: filteredItems,
        categories: categories,
        modifierGroups: bundle.modifierGroups,
        branches: branches,
        hydratedItems: state.hydratedItems,
        hydratedModifierGroups: state.hydratedModifierGroups,
        selectedCategoryId: selectedCategoryId,
        selectedBranchId: selectedBranch,
        selectedStatus: selectedStatus,
        searchQuery: searchQuery,
      );
    } catch (e) {
      if (!_sameScope(
        requestedScope,
        _resolveCacheScope(
          branchId: branchId,
          readLane: readLane,
          status: selectedStatus,
        ),
      )) {
        return;
      }
      final mapped = _mapError(e);
      state = state.copyWith(
        isLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  Future<(MenuItem, List<ModifierGroup>)> loadItemWithModifiers(
    String menuItemId, {
    int retries = 2,
    Duration retryDelay = const Duration(milliseconds: 200),
  }) async {
    final detail = await loadMenuItemDetail(
      menuItemId,
      retries: retries,
      retryDelay: retryDelay,
    );
    return (detail.item, detail.modifierGroups);
  }

  Future<MenuItemDetail> loadMenuItemDetail(
    String menuItemId, {
    int retries = 2,
    Duration retryDelay = const Duration(milliseconds: 200),
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final detail = await _menuRepository.fetchMenuItemDetail(menuItemId);
        final item = detail.item;
        final groups = detail.modifierGroups;
        if (item.id.isEmpty) {
          throw Exception('Empty menu item returned for $menuItemId');
        }
        final updatedItems = [
          for (final existing in state.allItems)
            if (existing.id == item.id) item else existing,
          if (state.allItems.every((it) => it.id != item.id)) item,
        ];
        final groupMap = {
          for (final g in state.modifierGroups) g.id: g,
          for (final g in state.hydratedModifierGroups.values) g.id: g,
          for (final g in groups) g.id: g,
        };
        final mergedGroups = groupMap.values.toList();
        final hydratedItems = Map<String, MenuItem>.from(state.hydratedItems)
          ..[item.id] = item;
        final hydratedModifierGroups = Map<String, ModifierGroup>.from(
          state.hydratedModifierGroups,
        );
        for (final g in groups) {
          hydratedModifierGroups[g.id] = g;
        }
        final hydrationErrors = Map<String, String>.from(state.hydrationErrors)
          ..remove(menuItemId);
        final detailByItemId = Map<String, MenuItemDetail>.from(
          state.detailByItemId,
        )..[item.id] = detail;
        final detailErrorsByItemId = Map<String, String>.from(
          state.detailErrorsByItemId,
        )..remove(menuItemId);
        final baseCompositionByItemId = Map<String, List<MenuComponent>>.from(
          state.baseCompositionByItemId,
        )..[item.id] = detail.baseComponents;
        final preservedEffects =
            detail.modifierOptionEffects.isNotEmpty ||
                !state.modifierOptionEffectsByItemId.containsKey(item.id)
            ? detail.modifierOptionEffects
            : state.modifierOptionEffectsByItemId[item.id] ??
                  const <MenuModifierOptionEffect>[];
        final modifierOptionEffectsByItemId =
            Map<String, List<MenuModifierOptionEffect>>.from(
              state.modifierOptionEffectsByItemId,
            )..[item.id] = preservedEffects;
        final modifierOptionEffectsErrorsByItemId = Map<String, String>.from(
          state.modifierOptionEffectsErrorsByItemId,
        )..remove(menuItemId);
        state = state.copyWith(
          allItems: updatedItems,
          filteredItems: _applyFilters(items: updatedItems),
          modifierGroups: mergedGroups,
          detailByItemId: detailByItemId,
          detailErrorsByItemId: detailErrorsByItemId,
          baseCompositionByItemId: baseCompositionByItemId,
          modifierOptionEffectsByItemId: modifierOptionEffectsByItemId,
          modifierOptionEffectsErrorsByItemId:
              modifierOptionEffectsErrorsByItemId,
          hydratedItems: hydratedItems,
          hydratedModifierGroups: hydratedModifierGroups,
          hydrationErrors: hydrationErrors,
          compositionByItem: baseCompositionByItemId,
        );
        return detail;
      } catch (e) {
        if (attempt > retries) {
          final mapped = _mapError(e);
          state = state.copyWith(
            detailErrorsByItemId: {
              ...state.detailErrorsByItemId,
              menuItemId: mapped.message,
            },
            hydrationErrors: {
              ...state.hydrationErrors,
              menuItemId: mapped.message,
            },
            error: mapped.message,
            errorCode: mapped.code,
          );
          rethrow;
        }
        await Future.delayed(retryDelay);
      }
    }
  }

  Future<void> loadItemComposition(String menuItemId) async {
    _setCompositionLoading(menuItemId, true);
    try {
      final baseComponents = await _menuRepository.fetchMenuItemComposition(
        menuItemId,
      );
      final compositionErrors = Map<String, String>.from(
        state.compositionErrors,
      )..remove(menuItemId);
      final compositionErrorCodes = Map<String, String>.from(
        state.compositionErrorCodes,
      )..remove(menuItemId);
      state = state.copyWith(
        baseCompositionByItemId: {
          ...state.baseCompositionByItemId,
          menuItemId: baseComponents,
        },
        compositionByItem: {
          ...state.compositionByItem,
          menuItemId: baseComponents,
        },
        compositionLoadedByItem: {
          ...state.compositionLoadedByItem,
          menuItemId: true,
        },
        compositionErrors: compositionErrors,
        compositionErrorCodes: compositionErrorCodes,
      );
    } catch (e) {
      _setCompositionError(menuItemId, e);
      rethrow;
    } finally {
      _setCompositionLoading(menuItemId, false);
    }
  }

  Future<void> upsertItemComposition({
    required String menuItemId,
    required List<MenuComponent> baseComponents,
  }) async {
    _setCompositionLoading(menuItemId, true);
    try {
      await _menuRepository.upsertMenuItemComposition(
        menuItemId: menuItemId,
        baseComponents: baseComponents,
      );
      final compositionErrors = Map<String, String>.from(
        state.compositionErrors,
      )..remove(menuItemId);
      final compositionErrorCodes = Map<String, String>.from(
        state.compositionErrorCodes,
      )..remove(menuItemId);
      state = state.copyWith(
        baseCompositionByItemId: {
          ...state.baseCompositionByItemId,
          menuItemId: baseComponents,
        },
        compositionByItem: {
          ...state.compositionByItem,
          menuItemId: baseComponents,
        },
        compositionLoadedByItem: {
          ...state.compositionLoadedByItem,
          menuItemId: true,
        },
        compositionErrors: compositionErrors,
        compositionErrorCodes: compositionErrorCodes,
      );
    } catch (e) {
      _setCompositionError(menuItemId, e);
      rethrow;
    } finally {
      _setCompositionLoading(menuItemId, false);
    }
  }

  Future<void> upsertItemModifierOptionEffects({
    required String menuItemId,
    required List<MenuModifierOptionEffect> effects,
  }) async {
    _setModifierOptionEffectsLoading(menuItemId, true);
    try {
      await _menuRepository.upsertMenuItemModifierOptionEffects(
        menuItemId: menuItemId,
        effects: effects,
      );
      final nextEffects = {
        ...state.modifierOptionEffectsByItemId,
        menuItemId: effects,
      };
      final effectErrors = Map<String, String>.from(
        state.modifierOptionEffectsErrorsByItemId,
      )..remove(menuItemId);
      final currentDetail = state.detailByItemId[menuItemId];
      state = state.copyWith(
        modifierOptionEffectsByItemId: nextEffects,
        modifierOptionEffectsErrorsByItemId: effectErrors,
        detailByItemId: currentDetail == null
            ? state.detailByItemId
            : {
                ...state.detailByItemId,
                menuItemId: MenuItemDetail(
                  item: currentDetail.item,
                  modifierGroups: currentDetail.modifierGroups,
                  baseComponents: currentDetail.baseComponents,
                  modifierOptionEffects: effects,
                  categoryName: currentDetail.categoryName,
                ),
              },
      );
    } catch (e) {
      _setModifierOptionEffectsError(menuItemId, e);
      rethrow;
    } finally {
      _setModifierOptionEffectsLoading(menuItemId, false);
    }
  }

  Future<MenuCompositionEvaluate> evaluateItemComposition({
    required String menuItemId,
    required List<String> selectedModifierOptionIds,
  }) async {
    _setCompositionLoading(menuItemId, true);
    try {
      final evaluation = await _menuRepository.evaluateMenuItemComposition(
        menuItemId: menuItemId,
        selectedModifierOptionIds: selectedModifierOptionIds,
      );
      final compositionErrors = Map<String, String>.from(
        state.compositionErrors,
      )..remove(menuItemId);
      final compositionErrorCodes = Map<String, String>.from(
        state.compositionErrorCodes,
      )..remove(menuItemId);
      state = state.copyWith(
        evaluatedCompositionByItemId: {
          ...state.evaluatedCompositionByItemId,
          menuItemId: evaluation,
        },
        compositionEvaluationByItem: {
          ...state.compositionEvaluationByItem,
          menuItemId: evaluation,
        },
        compositionErrors: compositionErrors,
        compositionErrorCodes: compositionErrorCodes,
      );
      return evaluation;
    } catch (e) {
      _setCompositionError(menuItemId, e);
      rethrow;
    } finally {
      _setCompositionLoading(menuItemId, false);
    }
  }

  Future<void> refreshCategories({String? status}) async {
    try {
      state = state.copyWith(isLoading: true, error: null, errorCode: null);
      final categories = await _withTimeout(
        _menuRepository.fetchCategoriesOnly(status: status),
      );
      state = state.copyWith(
        isLoading: false,
        categories: categories,
        filteredItems: _applyFilters(items: state.allItems),
      );
    } catch (e) {
      final mapped = _mapError(e);
      state = state.copyWith(
        isLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  Future<void> refreshModifierGroups({String status = 'active'}) async {
    try {
      state = state.copyWith(isLoading: true, error: null, errorCode: null);
      final normalizedStatus = status.trim().isEmpty
          ? 'active'
          : status.trim().toLowerCase();
      final groups = await _withTimeout(
        _menuRepository.fetchModifierGroupsOnly(status: normalizedStatus),
      );
      state = state.copyWith(isLoading: false, modifierGroups: groups);
    } catch (e) {
      final mapped = _mapError(e);
      state = state.copyWith(
        isLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  void filterByCategory(String categoryId) {
    final filtered = _applyFilters(categoryId: categoryId);
    state = state.copyWith(
      selectedCategoryId: categoryId,
      filteredItems: filtered,
    );
  }

  void searchItems(String query) {
    final filtered = _applyFilters(query: query);
    state = state.copyWith(searchQuery: query, filteredItems: filtered);
  }

  Future<void> filterByBranch(String branchId) async {
    await loadMenu(branchId: branchId);
  }

  Future<void> filterByStatus(String status) async {
    final normalizedStatus = _normalizeStatusFilter(status);
    final selectedCategoryId = normalizedStatus == 'archived'
        ? 'all'
        : state.selectedCategoryId;
    state = state.copyWith(selectedCategoryId: selectedCategoryId);
    await loadMenu(status: normalizedStatus);
  }

  Future<void> addCategory({
    required String name,
    String description = '',
    bool isActive = true,
  }) async {
    _clearOperationError();
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    final category = MenuCategory(
      id: '',
      name: name,
      status: isActive ? 'ACTIVE' : 'ARCHIVED',
      description: description,
    );
    try {
      final created = await _menuRepository.createCategory(category);
      final categories = [...state.categories, created];
      state = state.copyWith(categories: categories);
      await loadMenu(branchId: branchId);
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  Future<void> updateCategory(MenuCategory category) async {
    _clearOperationError();
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    try {
      final updated = await _menuRepository.updateCategory(category);
      final categories = [
        for (final existing in state.categories)
          if (existing.id == updated.id) updated else existing,
      ];
      state = state.copyWith(categories: categories);
      await loadMenu(branchId: branchId);
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  Future<void> archiveCategory(String categoryId) async {
    _clearOperationError();
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    try {
      await _menuRepository.archiveCategory(categoryId);
      final categories = state.categories
          .where((category) => category.id != categoryId)
          .toList();
      final items = state.allItems
          .where((item) => item.categoryId != categoryId)
          .toList();
      state = state.copyWith(
        categories: categories,
        allItems: items,
        filteredItems: _applyFilters(items: items),
      );
      await loadMenu(branchId: branchId);
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) {
    return archiveCategory(categoryId);
  }

  Future<void> restoreCategory(MenuCategory category) async {
    _clearOperationError();
    try {
      await _menuRepository.restoreCategory(category.id);
      final categories = [
        for (final existing in state.categories)
          if (existing.id == category.id)
            existing.copyWith(status: 'ACTIVE')
          else
            existing,
        if (state.categories.every((existing) => existing.id != category.id))
          category.copyWith(status: 'ACTIVE'),
      ];
      state = state.copyWith(categories: categories);
      await refreshCategories(status: 'active');
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  Future<void> addModifierGroup(ModifierGroup group) async {
    _clearOperationError();
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    try {
      final created = await _menuRepository.createModifierGroup(group);
      final modifierGroups = [...state.modifierGroups, created];
      state = state.copyWith(modifierGroups: modifierGroups);
      await loadMenu(branchId: branchId);
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  Future<void> updateModifierGroup(ModifierGroup group) async {
    _clearOperationError();
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    final previous = state.modifierGroups.firstWhere(
      (existing) => existing.id == group.id,
      orElse: () => group,
    );
    try {
      final updated = await _menuRepository.updateModifierGroup(
        group,
        previous: previous,
      );
      final groups = [
        for (final existing in state.modifierGroups)
          if (existing.id == updated.id) updated else existing,
      ];
      state = state.copyWith(modifierGroups: groups);
      await loadMenu(branchId: branchId);
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  Future<void> archiveModifierGroup(String groupId) async {
    _clearOperationError();
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    try {
      await _menuRepository.archiveModifierGroup(groupId);
      final groups = state.modifierGroups
          .where((group) => group.id != groupId)
          .toList();
      final items = state.allItems
          .map(
            (item) => item.copyWith(
              modifierGroupIds: item.modifierGroupIds
                  .where((id) => id != groupId)
                  .toList(),
            ),
          )
          .toList();
      state = state.copyWith(
        modifierGroups: groups,
        allItems: items,
        filteredItems: _applyFilters(items: items),
      );
      await loadMenu(branchId: branchId);
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  Future<void> restoreModifierGroup(String groupId) async {
    _clearOperationError();
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    try {
      await _menuRepository.restoreModifierGroup(groupId);
      await loadMenu(branchId: branchId);
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  Future<void> deleteModifierGroup(String groupId) {
    return archiveModifierGroup(groupId);
  }

  Future<MenuItem> addMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    _clearOperationError();
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    try {
      final created = await _menuRepository.createMenuItem(
        item,
        imagePath: imagePath,
        imageBytes: imageBytes,
      );
      final items = [created, ...state.allItems];
      state = state.copyWith(
        allItems: items,
        filteredItems: _applyFilters(items: items),
      );
      await loadMenu(branchId: branchId);
      return created;
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  Future<MenuItem> updateMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    _clearOperationError();
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    final previous = state.allItems.cast<MenuItem?>().firstWhere(
          (existing) => existing?.id == item.id,
          orElse: () => state.detailByItemId[item.id]?.item,
        );
    try {
      final updated = await _menuRepository.updateMenuItem(
        item,
        imagePath: imagePath,
        imageBytes: imageBytes,
        previous: previous,
      );
      final items = [
        for (final existing in state.allItems)
          if (existing.id == updated.id) updated else existing,
      ];
      state = state.copyWith(
        allItems: items,
        filteredItems: _applyFilters(items: items),
      );
      await loadMenu(branchId: branchId);
      return updated;
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  Future<void> archiveMenuItem(String menuItemId) async {
    _clearOperationError();
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    final currentItem =
        state.detailByItemId[menuItemId]?.item ??
        state.hydratedItems[menuItemId] ??
        state.allItems.firstWhere(
          (item) => item.id == menuItemId,
          orElse: () =>
              const MenuItem(id: '', name: '', categoryId: '', price: 0),
        );
    try {
      try {
        await _menuRepository.archiveMenuItem(menuItemId);
      } catch (_) {
        if (currentItem.id.isEmpty) rethrow;
        await _menuRepository.updateMenuItem(
          currentItem.copyWith(status: 'ARCHIVED', isActive: false),
        );
      }
      final items = state.allItems
          .where((item) => item.id != menuItemId)
          .toList();
      state = state.copyWith(
        allItems: items,
        filteredItems: _applyFilters(items: items),
      );
      await loadMenu(branchId: branchId);
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  Future<void> restoreMenuItem(String menuItemId) async {
    _clearOperationError();
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    final currentItem =
        state.detailByItemId[menuItemId]?.item ??
        state.hydratedItems[menuItemId] ??
        state.allItems.firstWhere(
          (item) => item.id == menuItemId,
          orElse: () =>
              const MenuItem(id: '', name: '', categoryId: '', price: 0),
        );
    try {
      try {
        await _menuRepository.restoreMenuItem(menuItemId);
      } catch (_) {
        if (currentItem.id.isEmpty) rethrow;
        await _menuRepository.updateMenuItem(
          currentItem.copyWith(status: 'ACTIVE', isActive: true),
        );
      }
      await loadMenu(branchId: branchId);
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String menuItemId) {
    return archiveMenuItem(menuItemId);
  }

  Future<void> setMenuItemVisibility({
    required String menuItemId,
    required List<String> visibleBranchIds,
  }) async {
    _clearOperationError();
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    try {
      await _menuRepository.setMenuItemVisibility(
        menuItemId: menuItemId,
        visibleBranchIds: visibleBranchIds,
      );
      final updatedItems = state.allItems
          .map((item) {
            if (item.id != menuItemId) return item;
            return item.copyWith(
              visibleBranchIds: visibleBranchIds,
              branchIds: visibleBranchIds,
            );
          })
          .toList(growable: false);
      state = state.copyWith(
        allItems: updatedItems,
        filteredItems: _applyFilters(items: updatedItems),
      );
      await loadMenu(branchId: branchId);
    } catch (e) {
      _setOperationError(e);
      rethrow;
    }
  }

  List<MenuItem> _applyFilters({
    List<MenuItem>? items,
    String? categoryId,
    String? branchId,
    String? query,
  }) {
    final source = items ?? state.allItems;
    final activeCategory = categoryId ?? state.selectedCategoryId;
    final activeBranch = branchId ?? state.selectedBranchId;
    final search =
        query?.trim().toLowerCase() ?? state.searchQuery.toLowerCase();

    return source.where((item) {
      final matchesCategory =
          activeCategory == 'all' || item.categoryId == activeCategory;
      final matchesBranch =
          activeBranch == 'all' || item.branchIds.contains(activeBranch);
      final matchesQuery =
          search.isEmpty || item.name.toLowerCase().contains(search);
      return matchesCategory && matchesBranch && matchesQuery;
    }).toList();
  }

  String _normalizeStatusFilter(String value) {
    switch (value.trim().toLowerCase()) {
      case 'archived':
      case 'archive':
      case 'achieve':
        return 'archived';
      case 'active':
      default:
        return 'active';
    }
  }

  List<MenuBranch> _resolveUserBranches() {
    final loginState = ref.read(loginControllerProvider);
    final assignments = loginState.session?.user.branches ?? const [];
    return assignments
        .where((branch) => (branch.branchId.isNotEmpty || branch.id.isNotEmpty))
        .map(
          (branch) => MenuBranch(
            id: branch.branchId.isNotEmpty ? branch.branchId : branch.id,
            name: branch.name.isNotEmpty ? branch.name : 'Branch',
          ),
        )
        .toList();
  }

  MenuCacheQuery? _resolveCacheScope({
    String? branchId,
    required MenuReadLane readLane,
    required String status,
  }) {
    final tenantId =
        (ref.read(authTenantIdProvider) ??
                ref.read(loginControllerProvider).session?.activeTenantId ??
                ref.read(loginControllerProvider).session?.user.tenantId ??
                '')
            .trim();
    if (tenantId.isEmpty) return null;

    final normalizedBranchFilter = (branchId ?? state.selectedBranchId).trim();
    final branchIdFilter =
        normalizedBranchFilter.isEmpty || normalizedBranchFilter == 'all'
        ? null
        : normalizedBranchFilter;

    return MenuCacheQuery(
      tenantId: tenantId,
      scopeKey: buildMenuCacheScopeKey(
        readLane: readLane,
        status: status,
        branchIdFilter: branchIdFilter,
      ),
      readLane: readLane,
      status: status,
      branchIdFilter: branchIdFilter,
    );
  }

  Future<T> _withTimeout<T>(Future<T> future) {
    return future.timeout(_requestTimeout);
  }

  bool _sameScope(MenuCacheQuery? a, MenuCacheQuery? b) {
    if (a == null || b == null) return a == b;
    return a.tenantId == b.tenantId && a.scopeKey == b.scopeKey;
  }

  bool _hasMenuBundle(MenuDataBundle? bundle) {
    if (bundle == null) return false;
    return bundle.items.isNotEmpty ||
        bundle.categories.isNotEmpty ||
        bundle.modifierGroups.isNotEmpty ||
        bundle.branches.isNotEmpty;
  }
}
