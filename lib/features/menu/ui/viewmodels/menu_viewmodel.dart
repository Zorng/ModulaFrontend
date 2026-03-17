import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';

/// Provider for the menu viewmodel.
final menuViewModelProvider = NotifierProvider<MenuViewModel, MenuState>(
  MenuViewModel.new,
);

class MenuViewModel extends Notifier<MenuState> {
  MenuRepository get _menuRepository => ref.read(menuRepositoryProvider);

  ({String message, String? code}) _mapError(Object error) {
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

  @override
  MenuState build() {
    return const MenuState();
  }

  Future<void> loadMenu({
    String? branchId,
    String? status,
    MenuReadLane readLane = MenuReadLane.management,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null, errorCode: null);
      final userBranches = _resolveUserBranches();
      final requestedBranchFilter = (branchId ?? state.selectedBranchId).trim();
      final selectedStatus = _normalizeStatusFilter(status ?? state.selectedStatus);
      final branchIdFilter =
          requestedBranchFilter.isEmpty || requestedBranchFilter == 'all'
          ? null
          : requestedBranchFilter;
      final bundle = await _menuRepository.fetchMenuData(
        readLane: readLane,
        status: selectedStatus,
        branchIdFilter: branchIdFilter,
      );
      final branches = userBranches.isNotEmpty ? userBranches : bundle.branches;
      final selectedBranch = branchIdFilter ?? 'all';
      final selectedCategoryId = state.selectedCategoryId;
      final searchQuery = state.searchQuery;

      // Preserve modifier attachments if bulk fetch doesn't carry them.
      final previousItems = state.allItems;
      final mergedItems = bundle.items.map((item) {
        if (item.modifierGroupIds.isNotEmpty) return item;
        final prev = previousItems.firstWhere(
          (it) => it.id == item.id,
          orElse: () => item,
        );
        return prev.id == item.id
            ? item.copyWith(modifierGroupIds: prev.modifierGroupIds)
            : item;
      }).toList();

      // Merge modifier groups by id to retain options if bundle lacks them.
      final groupMap = {
        for (final g in state.modifierGroups) g.id: g,
        for (final g in bundle.modifierGroups) g.id: g,
      };
      final mergedGroups = groupMap.values.toList();
      final filteredItems = _applyFilters(
        items: mergedItems,
        categoryId: selectedCategoryId,
        branchId: selectedBranch,
        query: searchQuery,
      );

      state = state.copyWith(
        isLoading: false,
        allItems: mergedItems,
        filteredItems: filteredItems,
        categories: bundle.categories,
        modifierGroups: mergedGroups,
        branches: branches,
        hydratedItems: state.hydratedItems,
        hydratedModifierGroups: state.hydratedModifierGroups,
        selectedCategoryId: selectedCategoryId,
        selectedBranchId: selectedBranch,
        selectedStatus: selectedStatus,
        searchQuery: searchQuery,
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

  Future<(MenuItem, List<ModifierGroup>)> loadItemWithModifiers(
    String menuItemId, {
    int retries = 2,
    Duration retryDelay = const Duration(milliseconds: 200),
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final result = await _menuRepository.fetchItemWithModifiers(menuItemId);
        final item = result.$1;
        final groups = result.$2;
        if (item.id.isEmpty) {
          throw Exception('Empty menu item returned for $menuItemId');
        }
        final updatedItems = [
          for (final existing in state.allItems)
            if (existing.id == item.id) item else existing,
          if (state.allItems.every((it) => it.id != item.id)) item,
        ];
        // Merge/replace modifier groups by id.
        final groupMap = {
          for (final g in state.modifierGroups) g.id: g,
          for (final g in state.hydratedModifierGroups.values) g.id: g,
        };
        for (final g in groups) {
          groupMap[g.id] = g;
        }
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
        state = state.copyWith(
          allItems: updatedItems,
          filteredItems: _applyFilters(items: updatedItems),
          modifierGroups: mergedGroups,
          hydratedItems: hydratedItems,
          hydratedModifierGroups: hydratedModifierGroups,
          hydrationErrors: hydrationErrors,
        );
        return (item, groups);
      } catch (e) {
        if (attempt > retries) {
          final mapped = _mapError(e);
          state = state.copyWith(
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
      final categories = await _menuRepository.fetchCategoriesOnly(
        status: status,
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
      final groups = await _menuRepository.fetchModifierGroupsOnly(
        status: normalizedStatus,
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
    final branchId = state.selectedBranchId == 'all'
        ? null
        : state.selectedBranchId;
    try {
      await _menuRepository.restoreCategory(category.id);
      await loadMenu(branchId: branchId);
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
    final previous = state.allItems.firstWhere(
      (existing) => existing.id == item.id,
      orElse: () => item,
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
        state.hydratedItems[menuItemId] ??
        state.allItems.firstWhere(
          (item) => item.id == menuItemId,
          orElse: () => const MenuItem(
            id: '',
            name: '',
            categoryId: '',
            price: 0,
          ),
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
        state.hydratedItems[menuItemId] ??
        state.allItems.firstWhere(
          (item) => item.id == menuItemId,
          orElse: () => const MenuItem(
            id: '',
            name: '',
            categoryId: '',
            price: 0,
          ),
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
}
