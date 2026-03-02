import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/data/dto/branch_stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/on_hand_record_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/domain/models/on_hand_record.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final remoteBranchStockRepositoryProvider = Provider<BranchStockRepository>((
  ref,
) {
  final api = ref.watch(inventoryApiProvider);
  return RemoteBranchStockRepository(api);
});

class RemoteBranchStockRepository extends BranchStockRepository {
  const RemoteBranchStockRepository(this._api);

  final InventoryApi _api;

  @override
  Future<List<OnHandRecord>> fetchOnHand({String? branchId}) async {
    final records = await _api.fetchOnHand(branchId: branchId);
    return records.map(_toOnHandDomain).toList(growable: false);
  }

  @override
  Future<List<StockItem>> fetchStockItems({String? branchId}) async {
    // Always fetch master items so we can hydrate unit/piece info.
    final masterDtos = await _api.fetchStockItems(
      status: 'all',
      limit: 200,
      offset: 0,
    );
    final masterById = {for (final dto in masterDtos) dto.id: dto};

    final branchDtos = await _api.fetchBranchStockItems(branchId: branchId);

    if (branchDtos.isNotEmpty) {
      return branchDtos
          .map(
            (assignment) => _toStockItemFromBranchAssignment(
              assignment: assignment,
              masterById: masterById,
              branchIdHint: branchId,
            ),
          )
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
            minThreshold: dto.lowStockThreshold ?? 0,
          ),
        )
        .toList(growable: false);
  }

  @override
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
    branchName: '',
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
