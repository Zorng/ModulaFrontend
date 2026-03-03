import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/data/dto/branch_stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/on_hand_record_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_aggregate_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_status.dart';
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
    final records = await _api.fetchOnHand(includeArchivedItems: true);
    final mapped = records
        .map((dto) => _toOnHandDomain(dto, branchIdHint: branchId))
        .toList(growable: false);
    if (branchId == null || branchId.isEmpty) return mapped;
    return mapped
        .where(
          (record) => record.branchId.isEmpty || record.branchId == branchId,
        )
        .toList(growable: false);
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

    if (branchId == null || branchId.isEmpty) {
      final aggregateDtos = await _api.fetchAggregateStock(
        includeArchivedItems: true,
      );
      if (aggregateDtos.isNotEmpty) {
        return aggregateDtos
            .map(
              (aggregate) => _toStockItemFromAggregate(
                aggregate: aggregate,
                masterById: masterById,
              ),
            )
            .toList(growable: false);
      }
    }

    final branchDtos = await _api.fetchBranchStockItems(
      includeArchivedItems: true,
    );

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

OnHandRecord _toOnHandDomain(OnHandRecordDto dto, {String? branchIdHint}) {
  final resolvedBranchId = dto.branchId.isNotEmpty
      ? dto.branchId
      : (branchIdHint ?? '');
  return OnHandRecord(
    stockItemId: dto.stockItemId,
    branchId: resolvedBranchId,
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

StockItem _toStockItemFromAggregate({
  required StockAggregateItemDto aggregate,
  required Map<String, StockItemDto> masterById,
}) {
  final base =
      masterById[aggregate.stockItemId] ??
      StockItemDto(
        id: aggregate.stockItemId,
        tenantId: '',
        categoryId: null,
        name: aggregate.stockItemName,
        baseUnit: aggregate.baseUnit,
        imageUrl: null,
        lowStockThreshold: null,
        status: InventoryStatus.active,
        createdAt: '',
        updatedAt: '',
      );
  return _toStockItem(
    dto: base,
    branchId: 'all',
    branchName: 'All Branches',
    onHand: aggregate.totalOnHandInBaseUnit,
    minThreshold: base.lowStockThreshold ?? 0,
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
