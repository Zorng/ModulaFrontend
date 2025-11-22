import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_category_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_state.dart';

final categoryControllerProvider =
    NotifierProvider<CategoryController, CategoryState>(() {
  return CategoryController();
});

class CategoryController extends Notifier<CategoryState> {
  late final InventoryCategoryRepository _repository;
  bool _hasLoaded = false;

  @override
  CategoryState build() {
    _repository = ref.read(inventoryCategoryRepositoryProvider);
    if (!_hasLoaded) {
      _hasLoaded = true;
      Future.microtask(loadCategories);
    }
    return const CategoryState();
  }

  Future<void> loadCategories() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final categories = await _repository.fetchCategories();
      state = state.copyWith(isLoading: false, categories: categories);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addCategory(String name) async {
    try {
      final created = await _repository.createCategory(
        InventoryCategory(id: '', name: name, isActive: true),
      );
      state = state.copyWith(categories: [...state.categories, created]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateCategory(InventoryCategory category) async {
    try {
      final updated = await _repository.updateCategory(category);
      final categories = [
        for (final existing in state.categories)
          if (existing.id == updated.id) updated else existing,
      ];
      state = state.copyWith(categories: categories, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      state = state.copyWith(
        categories: state.categories.where((category) => category.id != id).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
