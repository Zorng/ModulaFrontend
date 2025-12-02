import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';

final inventoryCategoryRepositoryProvider =
    Provider<InventoryCategoryRepository>((ref) {
  final api = ref.watch(inventoryApiProvider);
  return InventoryCategoryRepository(api);
});

class InventoryCategoryRepository {
  const InventoryCategoryRepository(this._api);

  final InventoryApi _api;

  Future<List<InventoryCategory>> fetchCategories({bool? isActive}) async {
    final data = await _api.fetchCategories(isActive: isActive);
    return data
        .whereType<Map<String, dynamic>>()
        .map(InventoryCategory.fromJson)
        .toList();
  }

  Future<InventoryCategory> createCategory(InventoryCategory category) async {
    final json = await _api.createCategory({
      'name': category.name,
      'isActive': category.isActive,
    });
    return InventoryCategory.fromJson(_unwrap(json));
  }

  Future<InventoryCategory> updateCategory(InventoryCategory category) async {
    final json = await _api.updateCategory(category.id, {
      'name': category.name,
      'isActive': category.isActive,
    });
    return InventoryCategory.fromJson(_unwrap(json));
  }

  Future<void> deleteCategory(String id, {bool? safeMode}) =>
      _api.deleteCategory(id, safeMode: safeMode);

  Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    return data is Map<String, dynamic> ? data : json;
  }
}
