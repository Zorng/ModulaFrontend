import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final mockStockItemRepositoryProvider = Provider<StockItemRepository>((ref) {
  return MockStockItemRepository();
});

class MockStockItemRepository extends StockItemRepository {
  MockStockItemRepository();

  final List<StockItem> _items = <StockItem>[];

  @override
  Future<List<StockItem>> fetchMasterStockItems({int pageSize = 200}) async {
    return _items.take(pageSize).toList(growable: false);
  }

  @override
  Future<StockItem> createStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final created = item.copyWith(
      id: item.id.isNotEmpty ? item.id : 'mock-stock-item-${_items.length + 1}',
      imageUrl:
          item.imageUrl ??
          (imagePath != null && imagePath.isNotEmpty ? imagePath : null),
    );
    _items.add(created);
    return created;
  }

  @override
  Future<StockItem> updateStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    final updated = item.copyWith(
      imageUrl:
          item.imageUrl ??
          (imagePath != null && imagePath.isNotEmpty ? imagePath : null),
    );

    if (index >= 0) {
      _items[index] = updated;
      return updated;
    }

    _items.add(updated);
    return updated;
  }

  @override
  Future<void> deleteStockItem(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}
