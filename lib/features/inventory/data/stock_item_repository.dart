import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/data/dto/branch_stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/on_hand_record_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';
import 'package:modular_pos/features/inventory/domain/models/on_hand_record.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final stockItemRepositoryProvider = Provider<StockItemRepository>((ref) {
  final api = ref.watch(inventoryApiProvider);
  return StockItemRepository(api);
});

class StockItemRepository {
  const StockItemRepository(this._api);

  final InventoryApi _api;

  Future<List<OnHandRecord>> fetchOnHand({String? branchId}) async {
    final records = await _api.fetchOnHand(branchId: branchId);
    return records.map(_toOnHandDomain).toList(growable: false);
  }

  Future<List<StockItem>> fetchStockItems({String? branchId}) async {
    // Always fetch master items so we can hydrate unit/piece info.
    final masterDtos = await _api.fetchStockItems(pageSize: 200);
    final masterById = {for (final dto in masterDtos) dto.id: dto};

    final branchDtos = await _api.fetchBranchStockItems(branchId: branchId);

    if (branchDtos.isNotEmpty) {
      return branchDtos
          .map((assignment) => _toStockItemFromBranchAssignment(
                assignment: assignment,
                masterById: masterById,
                branchIdHint: branchId,
              ))
          .toList(growable: false);
    }

    // Fallback for flows that need stock items regardless of branch assignment.
    return masterDtos
        .map(
          (dto) => _toStockItem(
            dto: dto,
            branchId: branchId ?? '',
            branchName: '',
            onHand: 0,
            minThreshold: 0,
          ),
        )
        .toList(growable: false);
  }

  /// Fetch only the master stock items (no branch assignment overlay).
  Future<List<StockItem>> fetchMasterStockItems({int pageSize = 200}) async {
    final masterDtos = await _api.fetchStockItems(pageSize: pageSize);
    return masterDtos
        .map(
          (dto) => _toStockItem(
            dto: dto,
            branchId: '',
            branchName: '',
            onHand: 0,
            minThreshold: 0,
          ),
        )
        .toList(growable: false);
  }

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
      if (item.barcode != null && item.barcode!.isNotEmpty) 'barcode': item.barcode,
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
      minThreshold: 0,
    );
  }

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
      if (item.barcode != null && item.barcode!.isNotEmpty) 'barcode': item.barcode,
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

  Future<void> deleteStockItem(String id) => _api.deactivateStockItem(id);

  Future<void> assignToBranch({
    required String stockItemId,
    required String branchId,
    required int minThreshold,
  }) async {
    await _api.assignStockItemToBranch(
      stockItemId: stockItemId,
      branchId: branchId,
      minThreshold: minThreshold,
    );
    // Response is informational; local state is updated by the caller.
  }
}

OnHandRecord _toOnHandDomain(OnHandRecordDto dto) {
  return OnHandRecord(
    stockItemId: dto.stockItemId,
    branchId: dto.branchId,
    onHand: dto.onHand,
    minThreshold: dto.minThreshold,
  );
}

StockItem _toStockItemFromBranchAssignment({
  required BranchStockItemDto assignment,
  required Map<String, StockItemDto> masterById,
  String? branchIdHint,
}) {
  final base = masterById[assignment.stockItemId] ?? assignment.stockItem;
  final resolvedBranchId = assignment.branchId.isNotEmpty
      ? assignment.branchId
      : (branchIdHint ?? '');
  return _toStockItem(
    dto: base,
    branchId: resolvedBranchId,
    branchName: assignment.branchName,
    onHand: assignment.onHand ?? 0,
    minThreshold: assignment.minThreshold ?? 0,
  );
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
    category: 'Uncategorized',
    categoryId: dto.categoryId,
    baseUnit: dto.unitText,
    pieceSize: dto.pieceSize,
    branchId: branchId,
    branchName: branchName,
    onHand: onHand,
    minThreshold: minThreshold,
    isActive: dto.isActive,
    barcode: dto.barcode,
    imageUrl: dto.imageUrl,
    lastRestockDate: '-',
    expiryDate: '-',
    usageTags: dto.usageTags,
  );
}
