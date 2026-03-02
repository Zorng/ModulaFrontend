import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/mock_inventory_category_repository.dart';
import 'package:modular_pos/features/inventory/data/remote_inventory_category_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart'
    show useMockInventoryRepositoryProvider;
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';

final inventoryCategoryRepositoryProvider =
    Provider<InventoryCategoryRepository>((ref) {
      final useMock = ref.watch(useMockInventoryRepositoryProvider);
      if (useMock) {
        return ref.watch(mockInventoryCategoryRepositoryProvider);
      }
      return ref.watch(remoteInventoryCategoryRepositoryProvider);
    });

abstract class InventoryCategoryRepository {
  const InventoryCategoryRepository();

  Future<List<InventoryCategory>> fetchCategories({String status = 'all'});

  Future<InventoryCategory> createCategory(InventoryCategory category);

  Future<InventoryCategory> updateCategory(InventoryCategory category);

  Future<void> deleteCategory(String id, {bool? safeMode});
}
