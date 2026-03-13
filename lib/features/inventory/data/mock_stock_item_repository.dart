import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/mock_inventory_store.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final mockStockItemRepositoryProvider = Provider<StockItemRepository>((ref) {
  final store = ref.watch(mockInventoryStoreProvider);
  return MockStockItemRepository(store);
});

class MockStockItemRepository extends StockItemRepository {
  MockStockItemRepository(this._store);

  final MockInventoryStore _store;

  @override
  Future<List<StockItem>> fetchMasterStockItems({int pageSize = 200}) async {
    return _store.fetchMasterStockItems(pageSize: pageSize);
  }

  @override
  Future<StockItem> fetchStockItemById(String id) async {
    return _store.fetchStockItemById(id);
  }

  @override
  Future<StockItem> createStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    return _store.createStockItem(
      item,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
  }

  @override
  Future<StockItem> updateStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    return _store.updateStockItem(
      item,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
  }

  @override
  Future<void> archiveStockItem(String id) async {
    _store.archiveStockItem(id);
  }

  @override
  Future<void> restoreStockItem(String id) async {
    _store.restoreStockItem(id);
  }
}
