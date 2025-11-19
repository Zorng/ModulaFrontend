import 'package:flutter_riverpod/legacy.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';

/// Provider for the menu viewmodel.
final menuViewModelProvider =
    StateNotifierProvider<MenuViewModel, MenuState>((ref) {
  final menuRepository = ref.watch(menuRepositoryProvider);
  return MenuViewModel(menuRepository);
});

class MenuViewModel extends StateNotifier<MenuState> {
  MenuViewModel(this._menuRepository) : super(const MenuState()) {
    fetchMenuItems();
  }

  final MenuRepository _menuRepository;

  Future<void> fetchMenuItems() async {
    try {
      state = state.copyWith(isLoading: true);
      final items = await _menuRepository.getMenuItems();
      state = state.copyWith(
        isLoading: false,
        allItems: items,
        filteredItems: items, // Initially, show all items
        selectedCategory: 'All',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void filterByCategory(String category) {
    final filtered = (category == 'All')
        ? state.allItems
        : state.allItems.where((item) => item.category == category).toList();

    state = state.copyWith(
      selectedCategory: category,
      filteredItems: filtered,
    );
  }

  void searchItems(String query) {
    final lowerCaseQuery = query.toLowerCase();
    final filtered = state.allItems.where((item) {
      final matchesQuery = item.name.toLowerCase().contains(lowerCaseQuery);
      // When searching, filter from the currently selected category
      final matchesCategory = state.selectedCategory == 'All' ||
          item.category == state.selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    state = state.copyWith(filteredItems: filtered);
  }
}