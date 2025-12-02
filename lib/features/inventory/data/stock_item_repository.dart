import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final stockItemRepositoryProvider = Provider<StockItemRepository>((ref) {
  final api = ref.watch(inventoryApiProvider);
  return StockItemRepository(api);
});

class StockItemRepository {
  const StockItemRepository(this._api);

  final InventoryApi _api;

  Future<List<StockItem>> fetchStockItems() async {
    final data = await _api.fetchStockItems(pageSize: 100);
    return data
        .whereType<Map<String, dynamic>>()
        .map(StockItem.fromJson)
        .toList();
  }

  Future<StockItem> createStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final body = {
      'name': item.name,
      'unitText': item.baseUnit,
      if (item.categoryId != null && item.categoryId!.isNotEmpty)
        'categoryId': item.categoryId,
      if (item.barcode != null && item.barcode!.isNotEmpty) 'barcode': item.barcode,
      'isActive': item.isActive,
    };
    final json = await _api.createStockItem(
      body,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    return StockItem.fromJson(_unwrap(json, fallback: item));
  }

  Future<StockItem> updateStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final body = {
      'name': item.name,
      'unitText': item.baseUnit,
      'isActive': item.isActive,
      if (item.categoryId != null && item.categoryId!.isNotEmpty)
        'categoryId': item.categoryId,
      if (item.barcode != null && item.barcode!.isNotEmpty) 'barcode': item.barcode,
    };
    final json = await _api.updateStockItem(
      item.id,
      body,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    return StockItem.fromJson(_unwrap(json, fallback: item));
  }

  Future<void> deleteStockItem(String id) => _api.deactivateStockItem(id);

  Map<String, dynamic> _unwrap(Map<String, dynamic> json, {StockItem? fallback}) {
    if (json['data'] is Map<String, dynamic>) return json['data'] as Map<String, dynamic>;
    if (json.isNotEmpty) return json;
    return fallback?.toJson() ?? {};
  }
}
