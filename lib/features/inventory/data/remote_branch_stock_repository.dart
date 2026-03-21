import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/data/dto/branch_stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/on_hand_record_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_aggregate_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/data/inventory_paginated_result.dart';
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
  Future<InventoryPaginatedResult<StockItem>> fetchStockItems({
    String? branchId,
    String status = 'all',
    String? search,
    String? categoryId,
    String stockLevel = 'all',
    int pageSize = 50,
    int offset = 0,
  }) async {
    final normalizedStatus = _normalizeInventoryStatus(status);
    final normalizedSearch = _normalizeInventoryQuery(search);
    final normalizedCategoryId = _normalizeInventoryQuery(categoryId);
    final normalizedStockLevel = _normalizeInventoryStockLevel(stockLevel);
    final includeArchivedItems = normalizedStatus != 'active';
    final safePageSize = pageSize <= 0 ? 50 : pageSize;
    final safeOffset = offset < 0 ? 0 : offset;
    final requiresFullScan =
        normalizedSearch != null ||
        normalizedCategoryId != null ||
        normalizedStockLevel != 'all';

    // Always fetch master items so we can hydrate unit/piece info.
    final masterItems = await _fetchAllMasterStockItems(
      _api,
      status: normalizedStatus,
      search: normalizedSearch,
      categoryId: normalizedCategoryId,
    );
    final masterById = {for (final dto in masterItems) dto.id: dto};

    if (!requiresFullScan && (branchId == null || branchId.isEmpty)) {
      final aggregateResult = await _api.fetchAggregateStock(
        includeArchivedItems: includeArchivedItems,
        limit: safePageSize,
        offset: safeOffset,
      );
      final items = aggregateResult.items
          .map(
            (aggregate) => _toStockItemFromAggregate(
              aggregate: aggregate,
              masterById: masterById,
            ),
          )
          .where((item) => _matchesStatus(item, normalizedStatus))
          .toList(growable: false);
      return InventoryPaginatedResult<StockItem>(
        items: items,
        limit: aggregateResult.limit,
        offset: aggregateResult.offset,
        total: aggregateResult.total,
        hasMore: aggregateResult.hasMore,
      );
    }

    if (!requiresFullScan) {
      final branchResult = await _api.fetchBranchStockItems(
        branchId: branchId!,
        includeArchivedItems: includeArchivedItems,
        limit: safePageSize,
        offset: safeOffset,
      );

      final items = branchResult.items
          .map(
            (assignment) => _toStockItemFromBranchAssignment(
              assignment: assignment,
              masterById: masterById,
              branchIdHint: branchId,
            ),
          )
          .where((item) => _matchesStatus(item, normalizedStatus))
          .toList(growable: false);
      return InventoryPaginatedResult<StockItem>(
        items: items,
        limit: branchResult.limit,
        offset: branchResult.offset,
        total: branchResult.total,
        hasMore: branchResult.hasMore,
      );
    }

    final filteredItems = branchId == null || branchId.isEmpty
        ? (await _fetchAllAggregateStockItems(
                _api,
                includeArchivedItems: includeArchivedItems,
              ))
              .where(
                (aggregate) => masterById.containsKey(aggregate.stockItemId),
              )
              .map(
                (aggregate) => _toStockItemFromAggregate(
                  aggregate: aggregate,
                  masterById: masterById,
                ),
              )
              .where(
                (item) =>
                    _matchesStatus(item, normalizedStatus) &&
                    _matchesInventoryStockLevel(item, normalizedStockLevel),
              )
              .toList(growable: false)
        : (await _fetchAllBranchStockItems(
                _api,
                branchId: branchId,
                includeArchivedItems: includeArchivedItems,
              ))
              .where(
                (assignment) => masterById.containsKey(assignment.stockItemId),
              )
              .map(
                (assignment) => _toStockItemFromBranchAssignment(
                  assignment: assignment,
                  masterById: masterById,
                  branchIdHint: branchId,
                ),
              )
              .where(
                (item) =>
                    _matchesStatus(item, normalizedStatus) &&
                    _matchesInventoryStockLevel(item, normalizedStockLevel),
              )
              .toList(growable: true);
    filteredItems.sort((a, b) => a.name.compareTo(b.name));

    return _pageFilteredStockItems(
      filteredItems,
      pageSize: safePageSize,
      offset: safeOffset,
    );
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

String? _normalizeInventoryQuery(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String _normalizeInventoryStockLevel(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'in_stock':
    case 'low_stock':
    case 'out_of_stock':
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

bool _matchesInventoryStockLevel(StockItem item, String stockLevel) {
  switch (stockLevel) {
    case 'in_stock':
      return item.onHand > item.minThreshold;
    case 'low_stock':
      return item.onHand > 0 && item.onHand <= item.minThreshold;
    case 'out_of_stock':
      return item.onHand <= 0;
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

Future<List<StockItemDto>> _fetchAllMasterStockItems(
  InventoryApi api, {
  required String status,
  String? search,
  String? categoryId,
}) async {
  const pageSize = 1000;
  var offset = 0;
  var hasMore = true;
  final items = <StockItemDto>[];

  while (hasMore) {
    final result = await api.fetchStockItems(
      status: status,
      search: search,
      categoryId: categoryId,
      limit: pageSize,
      offset: offset,
    );
    items.addAll(result.items);
    hasMore = result.hasMore;
    offset += result.items.length;
    if (result.items.isEmpty) break;
  }

  return items;
}

Future<List<StockAggregateItemDto>> _fetchAllAggregateStockItems(
  InventoryApi api, {
  required bool includeArchivedItems,
}) async {
  const pageSize = 200;
  var offset = 0;
  var hasMore = true;
  final items = <StockAggregateItemDto>[];

  while (hasMore) {
    final result = await api.fetchAggregateStock(
      includeArchivedItems: includeArchivedItems,
      limit: pageSize,
      offset: offset,
    );
    items.addAll(result.items);
    hasMore = result.hasMore;
    offset += result.items.length;
    if (result.items.isEmpty) break;
  }

  return items;
}

Future<List<BranchStockItemDto>> _fetchAllBranchStockItems(
  InventoryApi api, {
  required String branchId,
  required bool includeArchivedItems,
}) async {
  const pageSize = 200;
  var offset = 0;
  var hasMore = true;
  final items = <BranchStockItemDto>[];

  while (hasMore) {
    final result = await api.fetchBranchStockItems(
      branchId: branchId,
      includeArchivedItems: includeArchivedItems,
      limit: pageSize,
      offset: offset,
    );
    items.addAll(result.items);
    hasMore = result.hasMore;
    offset += result.items.length;
    if (result.items.isEmpty) break;
  }

  return items;
}

InventoryPaginatedResult<StockItem> _pageFilteredStockItems(
  List<StockItem> items, {
  required int pageSize,
  required int offset,
}) {
  final safeOffset = offset.clamp(0, items.length).toInt();
  final end = (safeOffset + pageSize).clamp(0, items.length).toInt();
  return InventoryPaginatedResult<StockItem>(
    items: items.sublist(safeOffset, end),
    limit: pageSize,
    offset: safeOffset,
    total: items.length,
    hasMore: end < items.length,
  );
}
