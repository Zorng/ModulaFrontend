import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_category_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';

final mockInventoryCategoryRepositoryProvider =
    Provider<InventoryCategoryRepository>((ref) {
      return const MockInventoryCategoryRepository();
    });

class MockInventoryCategoryRepository extends InventoryCategoryRepository {
  const MockInventoryCategoryRepository();

  @override
  Future<List<InventoryCategory>> fetchCategories({
    String status = 'all',
  }) async {
    return const <InventoryCategory>[];
  }

  @override
  Future<InventoryCategory> createCategory(InventoryCategory category) async {
    if (category.id.isNotEmpty) return category;
    return category.copyWith(id: 'mock-inv-category-id');
  }

  @override
  Future<InventoryCategory> updateCategory(InventoryCategory category) async {
    return category;
  }

  @override
  Future<void> deleteCategory(String id, {bool? safeMode}) async {}
}
