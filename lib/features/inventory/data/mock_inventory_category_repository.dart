import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_category_repository.dart';
import 'package:modular_pos/features/inventory/data/mock_inventory_store.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';

final mockInventoryCategoryRepositoryProvider =
    Provider<InventoryCategoryRepository>((ref) {
      final store = ref.watch(mockInventoryStoreProvider);
      return MockInventoryCategoryRepository(store);
    });

class MockInventoryCategoryRepository extends InventoryCategoryRepository {
  MockInventoryCategoryRepository(this._store);

  final MockInventoryStore _store;

  @override
  Future<List<InventoryCategory>> fetchCategories({
    String status = 'all',
  }) async {
    return _store.fetchCategories(status: status);
  }

  @override
  Future<InventoryCategory> createCategory(InventoryCategory category) async {
    return _store.createCategory(category);
  }

  @override
  Future<InventoryCategory> updateCategory(InventoryCategory category) async {
    return _store.updateCategory(category);
  }

  @override
  Future<void> deleteCategory(String id, {bool? safeMode}) async {
    _store.archiveCategory(id);
  }
}
