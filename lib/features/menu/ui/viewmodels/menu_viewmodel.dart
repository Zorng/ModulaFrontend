import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';

/// Provider for the menu viewmodel.
final menuViewModelProvider =
    NotifierProvider<MenuViewModel, MenuState>(MenuViewModel.new);

class MenuViewModel extends Notifier<MenuState> {
  bool _hasRequestedInitialLoad = false;

  MenuRepository get _menuRepository => ref.read(menuRepositoryProvider);

  @override
  MenuState build() {
    final loginState = ref.watch(loginControllerProvider);
    if (loginState.session == null) {
      _hasRequestedInitialLoad = false;
    } else if (!_hasRequestedInitialLoad) {
      _hasRequestedInitialLoad = true;
      Future.microtask(loadMenu);
    }
    return const MenuState();
  }

  Future<void> loadMenu({
    String? branchId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final userBranches = _resolveUserBranches();
      final fallbackBranchId =
          userBranches.isNotEmpty ? userBranches.first.id : null;
      final isExplicitAll = branchId == 'all';
      final wasAllPreviously =
          branchId == null && state.selectedBranchId == 'all';
      final noAssignedBranches = userBranches.isEmpty;
      final shouldFetchAll = isExplicitAll ||
          wasAllPreviously ||
          (noAssignedBranches && branchId == null);
      final requestedBranchId = shouldFetchAll
          ? null
          : branchId ??
              (state.selectedBranchId != 'all' ? state.selectedBranchId : null) ??
              fallbackBranchId;
      final snapshotBranchId = requestedBranchId ?? fallbackBranchId;
      if (snapshotBranchId != null) {
        // Quick snapshot fetch for debugging payload structure.
        try {
          final snapshot =
              await _menuRepository.fetchMenuSnapshot(snapshotBranchId);
          debugPrint('Menu snapshot payload: $snapshot');
        } catch (e) {
          debugPrint('Menu snapshot failed: $e');
        }
      }
      final bundle = await _menuRepository.fetchMenuData(
        branchId: requestedBranchId,
        branchIdsForHydration: shouldFetchAll
            ? userBranches.map((b) => b.id).toList()
            : null,
      );
      final branches =
          userBranches.isNotEmpty ? userBranches : bundle.branches;
      final selectedBranch = shouldFetchAll
          ? 'all'
          : requestedBranchId ?? (branches.isNotEmpty ? branches.first.id : 'all');

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

      state = state.copyWith(
        isLoading: false,
        allItems: mergedItems,
        filteredItems: _applyFilters(items: mergedItems),
        categories: bundle.categories,
        modifierGroups: mergedGroups,
        branches: branches,
        hydratedItems: state.hydratedItems,
        hydratedModifierGroups: state.hydratedModifierGroups,
        selectedCategoryId: 'all',
        selectedBranchId: selectedBranch,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
        final hydratedModifierGroups =
            Map<String, ModifierGroup>.from(state.hydratedModifierGroups);
        for (final g in groups) {
          hydratedModifierGroups[g.id] = g;
        }
        state = state.copyWith(
          allItems: updatedItems,
          filteredItems: _applyFilters(items: updatedItems),
          modifierGroups: mergedGroups,
          hydratedItems: hydratedItems,
          hydratedModifierGroups: hydratedModifierGroups,
          hydrationErrors: {
            ...state.hydrationErrors..remove(menuItemId),
          },
        );
        return (item, groups);
      } catch (e) {
        if (attempt > retries) {
          state = state.copyWith(
            hydrationErrors: {
              ...state.hydrationErrors,
              menuItemId: e.toString(),
            },
          );
          rethrow;
        }
        await Future.delayed(retryDelay);
      }
    }
  }

  Future<void> refreshCategories({bool? isActive}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final categories =
          await _menuRepository.fetchCategoriesOnly(isActive: isActive);
      state = state.copyWith(
        isLoading: false,
        categories: categories,
        filteredItems: _applyFilters(items: state.allItems),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshModifierGroups() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final groups = await _menuRepository.fetchModifierGroupsOnly();
      state = state.copyWith(
        isLoading: false,
        modifierGroups: groups,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
    state = state.copyWith(
      searchQuery: query,
      filteredItems: filtered,
    );
  }

  Future<void> filterByBranch(String branchId) async {
    await loadMenu(branchId: branchId);
  }

  Future<void> addCategory({
    required String name,
    String description = '',
    bool isActive = true,
  }) async {
    final branchId = state.selectedBranchId == 'all' ? null : state.selectedBranchId;
    final category = MenuCategory(
      id: '',
      name: name,
      description: description,
      isActive: isActive,
    );
    final created = await _menuRepository.createCategory(category);
    final categories = [...state.categories, created];
    state = state.copyWith(categories: categories);
    await loadMenu(branchId: branchId);
  }

  Future<void> updateCategory(MenuCategory category) async {
    final branchId = state.selectedBranchId == 'all' ? null : state.selectedBranchId;
    final updated = await _menuRepository.updateCategory(category);
    final categories = [
      for (final existing in state.categories)
        if (existing.id == updated.id) updated else existing,
    ];
    state = state.copyWith(categories: categories);
    await loadMenu(branchId: branchId);
  }

  Future<void> deleteCategory(String categoryId) async {
    final branchId = state.selectedBranchId == 'all' ? null : state.selectedBranchId;
    await _menuRepository.deleteCategory(categoryId);
    final categories =
        state.categories.where((category) => category.id != categoryId).toList();
    final items =
        state.allItems.where((item) => item.categoryId != categoryId).toList();
    state = state.copyWith(
      categories: categories,
      allItems: items,
      filteredItems: _applyFilters(items: items),
    );
    await loadMenu(branchId: branchId);
  }

  Future<void> addModifierGroup(ModifierGroup group) async {
    final branchId = state.selectedBranchId == 'all' ? null : state.selectedBranchId;
    final created = await _menuRepository.createModifierGroup(group);
    final modifierGroups = [...state.modifierGroups, created];
    state = state.copyWith(modifierGroups: modifierGroups);
    await loadMenu(branchId: branchId);
  }

  Future<void> updateModifierGroup(ModifierGroup group) async {
    final branchId = state.selectedBranchId == 'all' ? null : state.selectedBranchId;
    final previous = state.modifierGroups
        .firstWhere((existing) => existing.id == group.id, orElse: () => group);
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
  }

  Future<void> deleteModifierGroup(String groupId) async {
    final branchId = state.selectedBranchId == 'all' ? null : state.selectedBranchId;
    await _menuRepository.deleteModifierGroup(groupId);
    final groups =
        state.modifierGroups.where((group) => group.id != groupId).toList();
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
  }

  Future<MenuItem> addMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final branchId = state.selectedBranchId == 'all' ? null : state.selectedBranchId;
    final created =
        await _menuRepository.createMenuItem(
      item,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    final items = [created, ...state.allItems];
    state = state.copyWith(
      allItems: items,
      filteredItems: _applyFilters(
        items: items,
      ),
    );
    await loadMenu(branchId: branchId);
    return created;
  }

  Future<MenuItem> updateMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final branchId = state.selectedBranchId == 'all' ? null : state.selectedBranchId;
    final previous = state.allItems
        .firstWhere((existing) => existing.id == item.id, orElse: () => item);
    final updated =
        await _menuRepository.updateMenuItem(
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
      filteredItems: _applyFilters(
        items: items,
      ),
    );
    await loadMenu(branchId: branchId);
    return updated;
  }

  Future<void> deleteMenuItem(String menuItemId) async {
    final branchId = state.selectedBranchId == 'all' ? null : state.selectedBranchId;
    await _menuRepository.deleteMenuItem(menuItemId);
    final items =
        state.allItems.where((item) => item.id != menuItemId).toList();
    state = state.copyWith(
      allItems: items,
      filteredItems: _applyFilters(items: items),
    );
    await loadMenu(branchId: branchId);
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
    final search = query?.trim().toLowerCase() ?? state.searchQuery.toLowerCase();

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

  List<MenuBranch> _resolveUserBranches() {
    final loginState = ref.read(loginControllerProvider);
    final assignments = loginState.session?.user.branches ?? const [];
    return assignments
        .where((branch) =>
            branch.active &&
            (branch.branchId.isNotEmpty || branch.id.isNotEmpty))
        .map(
          (branch) => MenuBranch(
            id: branch.branchId.isNotEmpty ? branch.branchId : branch.id,
            name: branch.name.isNotEmpty ? branch.name : 'Branch',
          ),
        )
        .toList();
  }
}
