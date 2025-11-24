import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/stock_item_api.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';

final inventoryCategoryRepositoryProvider =
    Provider<InventoryCategoryRepository>((ref) {
  final api = ref.watch(stockItemApiProvider);
  return InventoryCategoryRepository(api);
});

class InventoryCategoryRepository {
  const InventoryCategoryRepository(this._api);

  final StockItemApi _api;

  Future<List<InventoryCategory>> fetchCategories() => _api.fetchCategories();

  Future<InventoryCategory> createCategory(InventoryCategory category) =>
      _api.createCategory(category);

  Future<InventoryCategory> updateCategory(InventoryCategory category) =>
      _api.updateCategory(category);

  Future<void> deleteCategory(String id) => _api.deleteCategory(id);
}
