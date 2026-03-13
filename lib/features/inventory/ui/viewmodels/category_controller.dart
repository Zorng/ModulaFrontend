import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_category_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_state.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';

final categoryControllerProvider =
    NotifierProvider<CategoryController, CategoryState>(() {
      return CategoryController();
    });

class CategoryController extends Notifier<CategoryState> {
  late final InventoryCategoryRepository _repository;

  @override
  CategoryState build() {
    _repository = ref.read(inventoryCategoryRepositoryProvider);
    return const CategoryState();
  }

  Future<void> loadCategories({String status = 'all'}) async {
    try {
      state = state.copyWith(isLoading: true, error: null, errorCode: null);
      final categories = await _repository.fetchCategories(status: status);
      state = state.copyWith(isLoading: false, categories: categories);
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to load categories.',
      );
      state = state.copyWith(
        isLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  Future<void> addCategory(
    String name, {
    String? description,
    bool isActive = true,
  }) async {
    try {
      final created = await _repository.createCategory(
        InventoryCategory(
          id: '',
          name: name,
          isActive: isActive,
          description: description,
        ),
      );
      state = state.copyWith(
        categories: [...state.categories, created],
        error: null,
        errorCode: null,
      );
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to create category.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  Future<void> updateCategory(InventoryCategory category) async {
    try {
      final updated = await _repository.updateCategory(category);
      final categories = [
        for (final existing in state.categories)
          if (existing.id == updated.id) updated else existing,
      ];
      state = state.copyWith(
        categories: categories,
        error: null,
        errorCode: null,
      );
      await _refreshInventory();
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to update category.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      state = state.copyWith(
        categories: state.categories
            .where((category) => category.id != id)
            .toList(),
        error: null,
        errorCode: null,
      );
      await _refreshInventory();
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to archive category.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  Future<void> _refreshInventory() async {
    await ref.read(stockInventoryControllerProvider.notifier).loadStockItems();
  }
}
