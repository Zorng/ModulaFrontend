import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';

/// Provider for the menu viewmodel.
final menuViewModelProvider =
    NotifierProvider<MenuViewModel, MenuState>(MenuViewModel.new);

class MenuViewModel extends Notifier<MenuState> {
  late final MenuRepository _menuRepository;

  @override
  MenuState build() {
    _menuRepository = ref.read(menuRepositoryProvider);
    _init();
    return const MenuState();
  }

  void _init() {
    Future.microtask(loadMenu);
  }

  Future<void> loadMenu() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final bundle = await _menuRepository.fetchMenuData();
      state = state.copyWith(
        isLoading: false,
        allItems: bundle.items,
        filteredItems: bundle.items,
        categories: bundle.categories,
        modifierGroups: bundle.modifierGroups,
        branches: bundle.branches,
        selectedCategoryId: 'all',
        selectedBranchId: 'all',
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

  void filterByBranch(String branchId) {
    final filtered = _applyFilters(branchId: branchId);
    state = state.copyWith(
      selectedBranchId: branchId,
      filteredItems: filtered,
    );
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

  Future<void> addMenuItem(MenuItem item) async {
    final created = await _menuRepository.createMenuItem(item);
    final items = [created, ...state.allItems];
    state = state.copyWith(
      allItems: items,
      filteredItems: _applyFilters(
        items: items,
      ),
    );
  }

  Future<void> updateMenuItem(MenuItem item) async {
    final updated = await _menuRepository.updateMenuItem(item);
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
}
