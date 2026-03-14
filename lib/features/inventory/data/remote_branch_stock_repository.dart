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
  Future<List<OnHandRecord>> fetchOnHand({
    String? branchId,
    String status = 'all',
  }) async {
    final targetBranch = (branchId ?? '').trim().isEmpty
        ? null
        : branchId?.trim();
    if (targetBranch == null) {
      return const <OnHandRecord>[];
    }
    final normalizedStatus = _normalizeInventoryStatus(status);
    final records = await _api.fetchOnHand(
      branchId: targetBranch,
      includeArchivedItems: normalizedStatus != 'active',
    );
    final mapped = records
        .map((dto) => _toOnHandDomain(dto, branchIdHint: targetBranch))
        .toList(growable: false);
    return mapped
        .where(
          (record) =>
              record.branchId.isEmpty || record.branchId == targetBranch,
        )
        .toList(growable: false);
  }

  @override
  Future<List<StockItem>> fetchStockItems({
    String? branchId,
    String status = 'all',
  }) async {
    final normalizedStatus = _normalizeInventoryStatus(status);
    final includeArchivedItems = normalizedStatus != 'active';

    // Always fetch master items so we can hydrate unit/piece info.
    final masterDtos = await _api.fetchStockItems(
      status: normalizedStatus,
      limit: 200,
      offset: 0,
    );
    final masterById = {for (final dto in masterDtos) dto.id: dto};

    if (branchId == null || branchId.isEmpty) {
      final aggregateDtos = await _api.fetchAggregateStock(
        includeArchivedItems: includeArchivedItems,
      );
      return aggregateDtos
          .map(
            (aggregate) => _toStockItemFromAggregate(
              aggregate: aggregate,
              masterById: masterById,
            ),
          )
          .where((item) => _matchesStatus(item, normalizedStatus))
          .toList(growable: false);
    }

    final branchDtos = await _api.fetchBranchStockItems(
      branchId: branchId,
      includeArchivedItems: includeArchivedItems,
    );

    return branchDtos
        .map(
          (assignment) => _toStockItemFromBranchAssignment(
            assignment: assignment,
            masterById: masterById,
            branchIdHint: branchId,
          ),
        )
        .where((item) => _matchesStatus(item, normalizedStatus))
        .toList(growable: false);
  }

  @override
  Future<void> assignToBranch({
    required String stockItemId,
    required String branchId,
    required int minThreshold,
  }) async {
    throw UnsupportedError(
      'Branch assignment is not supported by the current inventory contract.',
    );
  }
}

String _normalizeInventoryStatus(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'active':
    case 'archived':
    case 'all':
      return raw.trim().toLowerCase();
    default:
      return 'all';
  }
}

bool _matchesStatus(StockItem item, String status) {
  switch (status) {
    case 'active':
      return item.isActive;
    case 'archived':
      return !item.isActive;
    case 'all':
    default:
      return true;
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
  final mapped = _toStockItem(
    dto: base,
    branchId: resolvedBranchId,
    branchName: '',
    onHand: assignment.onHand ?? 0,
    minThreshold: assignment.minThreshold ?? 0,
  );
  final assignmentImageUrl = _normalizeImageUrl(assignment.stockItem.imageUrl);
  if (assignmentImageUrl == null || assignmentImageUrl == mapped.imageUrl) {
    return mapped;
  }
  return mapped.copyWith(imageUrl: assignmentImageUrl);
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

String? _normalizeImageUrl(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
