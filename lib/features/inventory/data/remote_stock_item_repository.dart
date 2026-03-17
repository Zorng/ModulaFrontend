import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/data/inventory_paginated_result.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final remoteStockItemRepositoryProvider = Provider<StockItemRepository>((ref) {
  final api = ref.watch(inventoryApiProvider);
  return RemoteStockItemRepository(api);
});

class RemoteStockItemRepository extends StockItemRepository {
  const RemoteStockItemRepository(this._api);

  final InventoryApi _api;

  @override
  Future<InventoryPaginatedResult<StockItem>> fetchMasterStockItems({
    String status = 'all',
    String? search,
    String? categoryId,
    int pageSize = 200,
    int offset = 0,
  }) async {
    final masterResult = await _api.fetchStockItems(
      status: status,
      search: search,
      categoryId: categoryId,
      limit: pageSize,
      offset: offset,
    );
    return InventoryPaginatedResult<StockItem>(
      items: masterResult.items
          .map(
            (dto) => _toStockItem(
              dto: dto,
              branchId: '',
              branchName: '',
              onHand: 0,
              minThreshold: dto.lowStockThreshold ?? 0,
            ),
          )
          .toList(growable: false),
      limit: masterResult.limit,
      offset: masterResult.offset,
      total: masterResult.total,
      hasMore: masterResult.hasMore,
    );
  }

  @override
  Future<StockItem> fetchStockItemById(String id) async {
    final dto = await _api.fetchStockItemById(id);
    return _toStockItem(
      dto: dto,
      branchId: '',
      branchName: '',
      onHand: 0,
      minThreshold: dto.lowStockThreshold ?? 0,
    );
  }

  @override
  Future<StockItem> createStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final body = {
      'name': item.name,
      'baseUnit': item.baseUnit,
      'categoryId': item.categoryId,
      'lowStockThreshold': item.minThreshold,
    };
    final dto = await _api.createStockItem(
      body,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    return _toStockItem(
      dto: dto,
      branchId: '',
      branchName: '',
      onHand: 0,
      minThreshold: dto.lowStockThreshold ?? 0,
    );
  }

  @override
  Future<StockItem> updateStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final body = {
      'name': item.name,
      'categoryId': item.categoryId,
      'lowStockThreshold': item.minThreshold,
      'imageUrl': item.imageUrl,
    };
    final dto = await _api.updateStockItem(
      item.id,
      body,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    return _toStockItem(
      dto: dto,
      branchId: item.branchId,
      branchName: item.branchName,
      onHand: item.onHand,
      minThreshold: item.minThreshold,
    );
  }

  @override
  Future<void> archiveStockItem(String id) => _api.archiveStockItem(id);

  @override
  Future<void> restoreStockItem(String id) => _api.restoreStockItem(id);
}

StockItem _toStockItem({
  required StockItemDto dto,
  required String branchId,
  required String branchName,
  required int onHand,
  required int minThreshold,
}) {
  return StockItem(
    id: dto.id,
    name: dto.name,
    categoryId: dto.categoryId,
    baseUnit: dto.baseUnit,
    pieceSize: 1,
    branchId: branchId,
    branchName: branchName,
    onHand: onHand,
    minThreshold: minThreshold,
    isActive: dto.isActive,
    imageUrl: dto.imageUrl,
  );
}
