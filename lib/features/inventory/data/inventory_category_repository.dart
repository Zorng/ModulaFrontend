import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/data/dto/inventory_category_dto.dart';
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
    return data.map(_toDomain).toList(growable: false);
  }

  Future<InventoryCategory> createCategory(InventoryCategory category) async {
    final dto = await _api.createCategory({
      'name': category.name,
      'isActive': category.isActive,
    });
    return _toDomain(dto);
  }

  Future<InventoryCategory> updateCategory(InventoryCategory category) async {
    final dto = await _api.updateCategory(category.id, {
      'name': category.name,
      'isActive': category.isActive,
    });
    return _toDomain(dto);
  }

  Future<void> deleteCategory(String id, {bool? safeMode}) =>
      _api.deleteCategory(id, safeMode: safeMode);
}

InventoryCategory _toDomain(InventoryCategoryDto dto) {
  return InventoryCategory(id: dto.id, name: dto.name, isActive: dto.isActive);
}
