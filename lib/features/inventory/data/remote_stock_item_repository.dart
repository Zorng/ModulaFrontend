import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
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
  Future<List<StockItem>> fetchMasterStockItems({int pageSize = 200}) async {
    final masterDtos = await _api.fetchStockItems(pageSize: pageSize);
    return masterDtos
        .map(
          (dto) => _toStockItem(
            dto: dto,
            branchId: '',
            branchName: '',
            onHand: 0,
            minThreshold: dto.lowStockThreshold ?? 0,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<StockItem> createStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final body = {
      'name': item.name,
      'unitText': item.baseUnit,
      'pieceSize': item.pieceSize,
      if (item.categoryId != null && item.categoryId!.isNotEmpty)
        'categoryId': item.categoryId,
      if (item.barcode != null && item.barcode!.isNotEmpty)
        'barcode': item.barcode,
      'isActive': item.isActive,
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
      'unitText': item.baseUnit,
      'pieceSize': item.pieceSize,
      'isActive': item.isActive,
      if (item.categoryId != null && item.categoryId!.isNotEmpty)
        'categoryId': item.categoryId,
      if (item.barcode != null && item.barcode!.isNotEmpty)
        'barcode': item.barcode,
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
  Future<void> deleteStockItem(String id) => _api.deactivateStockItem(id);
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
    category: '',
    categoryId: dto.categoryId,
    baseUnit: dto.baseUnit,
    pieceSize: 1,
    branchId: branchId,
    branchName: branchName,
    onHand: onHand,
    minThreshold: minThreshold,
    isActive: dto.isActive,
    barcode: null,
    imageUrl: dto.imageUrl,
    lastRestockDate: '',
    expiryDate: '',
    usageTags: const [],
  );
}
