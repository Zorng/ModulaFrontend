import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/features/inventory/data/mock_stock_item_repository.dart';
import 'package:modular_pos/features/inventory/data/remote_stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final useMockInventoryRepositoryProvider = Provider<bool>(
  (ref) => AppEnv.useMockInventoryRepository,
);

final stockItemRepositoryProvider = Provider<StockItemRepository>((ref) {
  final useMock = ref.watch(useMockInventoryRepositoryProvider);
  if (useMock) {
    return ref.watch(mockStockItemRepositoryProvider);
  }
  return ref.watch(remoteStockItemRepositoryProvider);
});

abstract class StockItemRepository {
  const StockItemRepository();

  Future<List<StockItem>> fetchMasterStockItems({int pageSize = 200});

  Future<StockItem> createStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  });

  Future<StockItem> updateStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  });

  Future<void> deleteStockItem(String id);
}
