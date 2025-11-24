import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/stock_item_api.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final stockItemRepositoryProvider = Provider<StockItemRepository>((ref) {
  final api = ref.watch(stockItemApiProvider);
  return StockItemRepository(api);
});

class StockItemRepository {
  const StockItemRepository(this._api);

  final StockItemApi _api;

  Future<List<StockItem>> fetchStockItems() => _api.fetchItems();

  Future<StockItem> createStockItem(StockItem item) => _api.createItem(item);

  Future<StockItem> updateStockItem(StockItem item) => _api.updateItem(item);

  Future<void> deleteStockItem(String id) => _api.deleteItem(id);
}
