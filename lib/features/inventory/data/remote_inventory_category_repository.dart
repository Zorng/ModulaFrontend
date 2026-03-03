import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/dto/inventory_category_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/data/inventory_category_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';

final remoteInventoryCategoryRepositoryProvider =
    Provider<InventoryCategoryRepository>((ref) {
      final api = ref.watch(inventoryApiProvider);
      return RemoteInventoryCategoryRepository(api);
    });

class RemoteInventoryCategoryRepository extends InventoryCategoryRepository {
  const RemoteInventoryCategoryRepository(this._api);

  final InventoryApi _api;

  @override
  Future<List<InventoryCategory>> fetchCategories({
    String status = 'all',
  }) async {
    final data = await _api.fetchCategories(status: status);
    return data.map(_toDomain).toList(growable: false);
  }

  @override
  Future<InventoryCategory> createCategory(InventoryCategory category) async {
    final body = {
      'name': category.name,
      'isActive': category.isActive,
      if (category.description != null && category.description!.isNotEmpty)
        'description': category.description,
    };
    final dto = await _api.createCategory(body);
    return _toDomain(dto);
  }

  @override
  Future<InventoryCategory> updateCategory(InventoryCategory category) async {
    final body = {'name': category.name};
    final dto = await _api.updateCategory(category.id, body);
    return _toDomain(dto);
  }

  @override
  Future<void> deleteCategory(String id, {bool? safeMode}) =>
      _api.deleteCategory(id, safeMode: safeMode);
}

InventoryCategory _toDomain(InventoryCategoryDto dto) {
  return InventoryCategory(
    id: dto.id,
    name: dto.name,
    isActive: dto.isActive,
    description: null,
  );
}
