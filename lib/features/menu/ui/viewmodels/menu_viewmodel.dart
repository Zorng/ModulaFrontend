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

  Future<void> loadMenu({String? branchId}) async {
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
      state = state.copyWith(
        isLoading: false,
        allItems: bundle.items,
        filteredItems: bundle.items,
        categories: bundle.categories,
        modifierGroups: bundle.modifierGroups,
        branches: branches,
        selectedCategoryId: 'all',
        selectedBranchId: selectedBranch,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
    final category = MenuCategory(
      id: '',
      name: name,
      description: description,
      isActive: isActive,
    );
    final created = await _menuRepository.createCategory(category);
    final categories = [...state.categories, created];
    state = state.copyWith(categories: categories);
  }

  Future<void> updateCategory(MenuCategory category) async {
    final updated = await _menuRepository.updateCategory(category);
    final categories = [
      for (final existing in state.categories)
        if (existing.id == updated.id) updated else existing,
    ];
    state = state.copyWith(categories: categories);
  }

  Future<void> addModifierGroup(ModifierGroup group) async {
    final created = await _menuRepository.createModifierGroup(group);
    final modifierGroups = [...state.modifierGroups, created];
    state = state.copyWith(modifierGroups: modifierGroups);
  }

  Future<void> updateModifierGroup(ModifierGroup group) async {
    final updated = await _menuRepository.updateModifierGroup(group);
    final groups = [
      for (final existing in state.modifierGroups)
        if (existing.id == updated.id) updated else existing,
    ];
    state = state.copyWith(modifierGroups: groups);
  }

  Future<void> addMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
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
  }

  Future<void> updateMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final updated =
        await _menuRepository.updateMenuItem(
      item,
      imagePath: imagePath,
      imageBytes: imageBytes,
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
