import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/on_hand_record.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_state.dart';

final stockInventoryControllerProvider =
    NotifierProvider<StockInventoryController, StockInventoryState>(() {
      return StockInventoryController();
    });

class StockInventoryController extends Notifier<StockInventoryState> {
  late final StockItemRepository _repository;
  late final BranchStockRepository _branchStockRepository;
  late final InventoryJournalRepository _journalRepository;

  @override
  StockInventoryState build() {
    _repository = ref.read(stockItemRepositoryProvider);
    _branchStockRepository = ref.read(branchStockRepositoryProvider);
    _journalRepository = ref.read(inventoryJournalRepositoryProvider);
    return const StockInventoryState();
  }

  Future<void> loadInventoryItems({
    String? branchId,
    String status = 'all',
  }) async {
    final targetBranchId = _normalizeBranchId(branchId);
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        errorCode: null,
        selectedInventoryBranchId: targetBranchId ?? 'all',
      );
      final items = await _branchStockRepository.fetchStockItems(
        branchId: targetBranchId,
        status: status,
      );
      final branchLookup = _branchLookup();
      final onHandData = await _fetchOnHand(
        branchId: targetBranchId,
        status: status,
      );
      final mapped = _applyOnHand(
        items.map((item) => _withBranchName(item, branchLookup)).toList(),
        onHandData,
      );
      state = state.copyWith(isLoading: false, inventoryItems: mapped);
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to load inventory items.',
      );
      state = state.copyWith(
        isLoading: false,
        inventoryItems: const [],
        error: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  Future<void> loadStockItems({String status = 'all'}) async {
    try {
      state = state.copyWith(isLoading: true, error: null, errorCode: null);
      final items = await _repository.fetchMasterStockItems();
      final mapped = items
          .where((item) => _matchesStatus(item, status))
          .map(_toCatalogItem)
          .toList(growable: false);
      state = state.copyWith(isLoading: false, stockItems: mapped);
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to load stock items.',
      );
      state = state.copyWith(
        isLoading: false,
        stockItems: const [],
        error: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  Future<bool> hasStockItems() async {
    if (state.stockItems.isNotEmpty) {
      return true;
    }

    final items = await _repository.fetchMasterStockItems();
    return items.isNotEmpty;
  }

  Future<void> loadRestockBatches({
    String? branchId,
    String status = 'active',
    String? stockItemId,
    int limit = 200,
    int offset = 0,
    bool append = false,
  }) async {
    final safeLimit = limit <= 0 ? 200 : limit;
    final safeOffset = offset < 0 ? 0 : offset;
    final normalizedStatus = _normalizeListStatus(status);
    final normalizedStockItemId = stockItemId ?? '';
    final normalizedBranchId = _normalizeBranchId(branchId) ?? '';
    final canAppend =
        append &&
        normalizedStatus == state.restockBatchStatus &&
        normalizedStockItemId == state.restockBatchStockItemId &&
        normalizedBranchId == state.restockBatchBranchId;
    try {
      state = state.copyWith(
        isBatchesLoading: !canAppend,
        isLoadingMoreBatches: canAppend,
        error: null,
        errorCode: null,
        restockBatchLimit: safeLimit,
        restockBatchStatus: normalizedStatus,
        restockBatchStockItemId: normalizedStockItemId,
        restockBatchBranchId: normalizedBranchId,
        hasMoreRestockBatches: canAppend ? state.hasMoreRestockBatches : true,
      );
      final batches = await _journalRepository.fetchRestockBatches(
        branchId: normalizedBranchId.isEmpty ? null : normalizedBranchId,
        status: normalizedStatus,
        stockItemId: stockItemId,
        limit: safeLimit,
        offset: safeOffset,
      );
      final nextBatches = canAppend
          ? _mergeBatches(state.batches, batches)
          : batches;
      final hasMore = batches.length == safeLimit;
      state = state.copyWith(
        isBatchesLoading: false,
        isLoadingMoreBatches: false,
        batches: nextBatches,
        restockBatchOffset: safeOffset + batches.length,
        hasMoreRestockBatches: hasMore,
        error: null,
        errorCode: null,
      );
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to load restock batches.',
      );
      state = state.copyWith(
        isBatchesLoading: false,
        isLoadingMoreBatches: false,
        error: mapped.message,
        errorCode: mapped.code,
      );
      rethrow;
    }
  }

  Future<void> loadMoreRestockBatches() async {
    if (state.isBatchesLoading || state.isLoadingMoreBatches) return;
    if (!state.hasMoreRestockBatches) return;
    await loadRestockBatches(
      branchId: state.restockBatchBranchId.isEmpty
          ? null
          : state.restockBatchBranchId,
      status: state.restockBatchStatus,
      stockItemId: state.restockBatchStockItemId.isEmpty
          ? null
          : state.restockBatchStockItemId,
      limit: state.restockBatchLimit,
      offset: state.restockBatchOffset,
      append: true,
    );
  }

  Future<void> updateRestockBatchMetadata({
    required String batchId,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
    String? note,
  }) async {
    try {
      final branchId = _branchIdForBatch(batchId);
      final updated = await _journalRepository.updateRestockBatchMetadata(
        batchId: batchId,
        branchId: branchId,
        expiryDate: expiryDate,
        supplierName: supplierName,
        purchaseCostUsd: purchaseCostUsd,
        note: note,
      );
      final hasExisting = state.batches.any((batch) => batch.id == batchId);
      final nextBatches = hasExisting
          ? [
              for (final batch in state.batches)
                if (batch.id == batchId)
                  batch.copyWith(expiryDate: updated.expiryDate)
                else
                  batch,
            ]
          : [...state.batches, updated];
      state = state.copyWith(
        batches: nextBatches,
        error: null,
        errorCode: null,
      );
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to update restock batch.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  Future<void> archiveRestockBatch({required String batchId}) async {
    try {
      final branchId = _branchIdForBatch(batchId);
      await _journalRepository.archiveRestockBatch(
        batchId: batchId,
        branchId: branchId,
      );
      state = state.copyWith(
        batches: state.batches.where((batch) => batch.id != batchId).toList(),
        error: null,
        errorCode: null,
      );
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to archive restock batch.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  Future<StockItem> addStockItem(
    StockItem draft, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    try {
      final created = await _repository.createStockItem(
        draft,
        imagePath: imagePath,
        imageBytes: imageBytes,
      );
      final mapped = _toCatalogItem(created);
      state = state.copyWith(
        stockItems: [...state.stockItems, mapped],
        error: null,
        errorCode: null,
      );
      return mapped;
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to create stock item.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  Future<StockItem> updateStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    try {
      final updated = await _repository.updateStockItem(
        item,
        imagePath: imagePath,
        imageBytes: imageBytes,
      );
      final stockMapped = _toCatalogItem(updated);
      final nextInventoryItems = [
        for (final existing in state.inventoryItems)
          if (existing.id == updated.id)
            existing.copyWith(
              name: updated.name,
              categoryId: updated.categoryId,
              baseUnit: updated.baseUnit,
              pieceSize: updated.pieceSize,
              isActive: updated.isActive,
              imageUrl: updated.imageUrl,
            )
          else
            existing,
      ];
      final nextStockItems = _upsertStockItem(state.stockItems, stockMapped);
      state = state.copyWith(
        inventoryItems: nextInventoryItems,
        stockItems: nextStockItems,
        error: null,
        errorCode: null,
      );
      return stockMapped;
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to update stock item.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  Future<void> createRestockBatch({
    required String itemId,
    required int baseQty,
    String? restockDate,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
    String? note,
    String? branchId,
  }) async {
    try {
      final item = _findItemOrThrow(itemId);
      final targetBranch =
          _normalizeBranchId(branchId) ?? _normalizeBranchId(item.branchId);
      final occurredAt = _toUtcIso(restockDate);
      if (targetBranch == null) {
        throw const ApiClientException(
          message: 'Branch selection is required for restocking.',
          code: 'BRANCH_CONTEXT_REQUIRED',
          statusCode: 400,
        );
      }
      await _journalRepository.createRestockBatch(
        branchId: targetBranch,
        stockItemId: item.id,
        qty: baseQty,
        receivedAt: occurredAt,
        expiryDate: expiryDate,
        supplierName: supplierName,
        purchaseCostUsd: purchaseCostUsd,
        note: note,
      );
      await _reloadCurrentInventoryLane();
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to restock inventory item.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  @Deprecated('Use createRestockBatch')
  Future<void> restockItem({
    required String itemId,
    required int baseQty,
    String? restockDate,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
    String? note,
    String? branchId,
  }) {
    return createRestockBatch(
      itemId: itemId,
      baseQty: baseQty,
      restockDate: restockDate,
      expiryDate: expiryDate,
      supplierName: supplierName,
      purchaseCostUsd: purchaseCostUsd,
      note: note,
      branchId: branchId,
    );
  }

  Future<void> archiveStockItem(String id) async {
    try {
      await _repository.archiveStockItem(id);
      state = state.copyWith(
        inventoryItems: state.inventoryItems
            .where((item) => item.id != id)
            .toList(),
        stockItems: state.stockItems.where((item) => item.id != id).toList(),
        batches: state.batches
            .where((batch) => batch.stockItemId != id)
            .toList(),
        error: null,
        errorCode: null,
      );
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to archive stock item.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  @Deprecated('Use archiveStockItem')
  Future<void> deleteStockItem(String id) => archiveStockItem(id);

  Future<void> restoreStockItem(String id) async {
    try {
      await _repository.restoreStockItem(id);
      state = state.copyWith(
        inventoryItems: [
          for (final item in state.inventoryItems)
            if (item.id == id) item.copyWith(isActive: true) else item,
        ],
        stockItems: [
          for (final item in state.stockItems)
            if (item.id == id) item.copyWith(isActive: true) else item,
        ],
        error: null,
        errorCode: null,
      );
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to restore stock item.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  StockItem? findById(String id) {
    for (final item in state.stockItems) {
      if (item.id == id) return item;
    }
    for (final item in state.inventoryItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<StockItem> loadStockItemDetail(String id) async {
    try {
      final detail = await _repository.fetchStockItemById(id);
      final existingStock = state.stockItems.where((item) => item.id == id);
      final existingInventory = state.inventoryItems.where(
        (item) => item.id == id,
      );
      final stockMapped = _toCatalogItem(
        existingStock.isEmpty
            ? detail
            : detail.copyWith(
                onHand: existingStock.first.onHand,
                minThreshold: existingStock.first.minThreshold,
              ),
      );
      final nextStockItems = _upsertStockItem(state.stockItems, stockMapped);
      final nextInventoryItems = existingInventory.isEmpty
          ? state.inventoryItems
          : [
              for (final item in state.inventoryItems)
                if (item.id == id)
                  item.copyWith(
                    name: detail.name,
                    categoryId: detail.categoryId,
                    baseUnit: detail.baseUnit,
                    pieceSize: detail.pieceSize,
                    isActive: detail.isActive,
                    imageUrl: detail.imageUrl,
                  )
                else
                  item,
            ];
      state = state.copyWith(
        stockItems: nextStockItems,
        inventoryItems: nextInventoryItems,
        error: null,
        errorCode: null,
      );
      return stockMapped;
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to load stock item detail.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  List<StockBatch> batchesForItem(String itemId) {
    final batches =
        state.batches.where((batch) => batch.stockItemId == itemId).toList()
          ..sort((a, b) {
            if (a.expiryDate == null && b.expiryDate == null) return 0;
            if (a.expiryDate == null) return 1;
            if (b.expiryDate == null) return -1;
            return a.expiryDate!.compareTo(b.expiryDate!);
          });
    return batches;
  }

  Future<void> applyInventoryAdjustment({
    required String stockItemId,
    String? batchId,
    String? branchId,
    String style = 'DELTA',
    int? delta,
    int? countedOnHandInBaseUnit,
    String? note,
  }) async {
    try {
      final normalizedStyle = style.trim().toUpperCase() == 'SET_TO_COUNT'
          ? 'SET_TO_COUNT'
          : 'DELTA';
      final batch = batchId == null
          ? null
          : state.batches.firstWhere(
              (element) => element.id == batchId,
              orElse: () => StockBatch(
                id: batchId,
                stockItemId: stockItemId,
                branchId: 'all',
                onHand: 0,
                receivedDate: _todayString(),
              ),
            );
      final item = _findItemOrThrow(stockItemId);
      final resolvedBranchId = _resolveAdjustmentBranchId(
        explicitBranchId: branchId,
        item: item,
        batch: batch,
      );
      final currentOnHand = await _currentOnHandForAdjustment(
        item: item,
        branchId: resolvedBranchId,
      );
      final resolvedDelta = normalizedStyle == 'DELTA' ? delta : null;
      final resolvedCount = normalizedStyle == 'SET_TO_COUNT'
          ? countedOnHandInBaseUnit
          : null;
      if (normalizedStyle == 'DELTA' &&
          (resolvedDelta == null || resolvedDelta == 0)) {
        throw const ApiClientException(
          message: 'Adjustment quantity must be non-zero.',
          code: 'INVENTORY_ADJUSTMENT_INVALID',
          statusCode: 422,
        );
      }
      if (normalizedStyle == 'SET_TO_COUNT' &&
          (resolvedCount == null || resolvedCount < 0)) {
        throw const ApiClientException(
          message: 'Counted on-hand quantity is invalid.',
          code: 'INVENTORY_QUANTITY_INVALID',
          statusCode: 422,
        );
      }
      final expectedOnHand = normalizedStyle == 'SET_TO_COUNT'
          ? resolvedCount!
          : currentOnHand + resolvedDelta!;
      if (expectedOnHand < 0) {
        throw const ApiClientException(
          message: 'Adjustment exceeds available quantity.',
          code: 'INVENTORY_QUANTITY_INVALID',
          statusCode: 422,
        );
      }
      final resultingOnHand = await _journalRepository.applyAdjustment(
        branchId: resolvedBranchId,
        stockItemId: item.id,
        style: normalizedStyle,
        deltaInBaseUnit: resolvedDelta,
        countedOnHandInBaseUnit: resolvedCount,
        reasonCode: normalizedStyle == 'SET_TO_COUNT'
            ? 'COUNT_CORRECTION'
            : resolvedDelta! < 0
            ? 'WASTE'
            : 'COUNT_CORRECTION',
        note: note,
      );
      final resolvedOnHand = resultingOnHand ?? expectedOnHand;
      final nextBatches = [
        for (final existing in state.batches)
          if (batchId != null &&
              existing.id == batchId &&
              normalizedStyle == 'DELTA')
            existing.copyWith(
              onHand: (existing.onHand + resolvedDelta!) < 0
                  ? 0
                  : existing.onHand + resolvedDelta,
            )
          else if (normalizedStyle == 'SET_TO_COUNT' &&
              state.batches
                      .where((batch) => batch.stockItemId == item.id)
                      .length ==
                  1 &&
              existing.stockItemId == item.id)
            existing.copyWith(onHand: resolvedOnHand)
          else
            existing,
      ];
      state = state.copyWith(
        batches: nextBatches,
        error: null,
        errorCode: null,
      );
      await _reloadCurrentInventoryLane();
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to adjust inventory item.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  @Deprecated('Use applyInventoryAdjustment')
  Future<void> adjustBatch({
    required String batchId,
    required int delta,
    String? note,
  }) {
    final batch = state.batches.firstWhere(
      (existing) => existing.id == batchId,
      orElse: () => StockBatch(
        id: batchId,
        stockItemId: batchId,
        branchId: 'all',
        onHand: 0,
        receivedDate: _todayString(),
      ),
    );
    return applyInventoryAdjustment(
      stockItemId: batch.stockItemId,
      batchId: batchId,
      style: 'DELTA',
      delta: delta,
      note: note,
    );
  }

  void updateBranchAssignment({
    required String stockItemId,
    required String branchId,
    required int minThreshold,
  }) {
    final branchName = _branchLookup()[branchId];
    final updatedItems = [
      for (final item in state.inventoryItems)
        if (item.id == stockItemId)
          item.copyWith(
            branchId: branchId,
            branchName: branchName ?? item.branchName,
            minThreshold: minThreshold,
          )
        else
          item,
    ];
    state = state.copyWith(inventoryItems: updatedItems);
  }

  String _todayString() => DateTime.now().toIso8601String().split('T').first;

  String _branchIdForBatch(String batchId) {
    final batch = state.batches.firstWhere(
      (existing) => existing.id == batchId,
      orElse: () => throw const ApiClientException(
        message:
            'Branch context is missing. Please reselect a branch and try again.',
        code: 'BRANCH_CONTEXT_REQUIRED',
        statusCode: 400,
      ),
    );
    if (_normalizeBranchId(batch.branchId) == null) {
      throw const ApiClientException(
        message:
            'Branch context is missing. Please reselect a branch and try again.',
        code: 'BRANCH_CONTEXT_REQUIRED',
        statusCode: 400,
      );
    }
    return batch.branchId;
  }

  String _resolveAdjustmentBranchId({
    String? explicitBranchId,
    required StockItem item,
    StockBatch? batch,
  }) {
    final branchId =
        _normalizeBranchId(explicitBranchId) ??
        _normalizeBranchId(batch?.branchId) ??
        _normalizeBranchId(item.branchId);
    if (branchId == null) {
      throw const ApiClientException(
        message:
            'Branch context is missing. Please reselect a branch and try again.',
        code: 'BRANCH_CONTEXT_REQUIRED',
        statusCode: 400,
      );
    }
    return branchId;
  }

  Map<String, String> _branchLookup() {
    final user = ref.read(loginControllerProvider).user;
    final branches = user?.branches ?? const [];
    return {
      for (final b in branches)
        (b.branchId.isNotEmpty ? b.branchId : b.id): b.name,
    };
  }

  StockItem _withBranchName(StockItem item, Map<String, String> branchLookup) {
    final branchName = branchLookup[item.branchId];
    if (branchName != null && branchName.isNotEmpty) {
      return item.copyWith(branchName: branchName);
    }
    return item;
  }

  StockItem _toCatalogItem(StockItem item) {
    return item.copyWith(branchId: '', branchName: '', onHand: 0);
  }

  List<StockItem> _applyOnHand(
    List<StockItem> items,
    List<OnHandRecord> onHandData,
  ) {
    if (onHandData.isEmpty) return items;
    final lookup = <String, OnHandRecord>{};
    for (final record in onHandData) {
      if (record.stockItemId.isEmpty) continue;
      final key = '${record.stockItemId}|${record.branchId}';
      lookup[key] = record;
    }
    return items.map((item) {
      final key = '${item.id}|${item.branchId}';
      final data = lookup[key] ?? lookup['${item.id}|'];
      if (data == null) return item;
      final onHand = data.onHand;
      final minThreshold = data.minThreshold;
      return item.copyWith(
        onHand: onHand ?? item.onHand,
        minThreshold: minThreshold ?? item.minThreshold,
      );
    }).toList();
  }

  Future<List<OnHandRecord>> _fetchOnHand({
    String? branchId,
    String status = 'all',
  }) async {
    final targetBranch = _normalizeBranchId(branchId);
    if (targetBranch == null) {
      return const [];
    }
    try {
      final data = await _branchStockRepository.fetchOnHand(
        branchId: targetBranch,
        status: status,
      );
      return data
          .map(
            (record) => record.branchId.isEmpty
                ? OnHandRecord(
                    stockItemId: record.stockItemId,
                    branchId: targetBranch,
                    onHand: record.onHand,
                    minThreshold: record.minThreshold,
                  )
                : record,
          )
          .where(
            (record) =>
                record.branchId.isEmpty || record.branchId == targetBranch,
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  List<StockBatch> _mergeBatches(
    List<StockBatch> existing,
    List<StockBatch> next,
  ) {
    final seen = <String>{for (final batch in existing) batch.id};
    final merged = <StockBatch>[...existing];
    for (final batch in next) {
      if (seen.add(batch.id)) merged.add(batch);
    }
    return merged;
  }

  String _normalizeListStatus(String value) {
    switch (value.trim().toLowerCase()) {
      case 'active':
      case 'archived':
      case 'all':
        return value.trim().toLowerCase();
      default:
        return 'active';
    }
  }

  bool _matchesStatus(StockItem item, String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return item.isActive;
      case 'archived':
        return !item.isActive;
      case 'all':
      default:
        return true;
    }
  }

  String? _normalizeBranchId(String? branchId) {
    if (branchId == null) return null;
    final trimmed = branchId.trim();
    if (trimmed.isEmpty || trimmed == 'all') return null;
    return trimmed;
  }

  Future<int> _currentOnHandForAdjustment({
    required StockItem item,
    required String branchId,
  }) async {
    for (final inventoryItem in state.inventoryItems) {
      if (inventoryItem.id == item.id && inventoryItem.branchId == branchId) {
        return inventoryItem.onHand;
      }
    }

    final records = await _branchStockRepository.fetchOnHand(
      branchId: branchId,
      status: 'all',
    );
    for (final record in records) {
      if (record.stockItemId == item.id) {
        return record.onHand ?? 0;
      }
    }

    if (item.branchId == branchId) {
      return item.onHand;
    }
    return 0;
  }

  StockItem _findItemOrThrow(String id) {
    return findById(id) ??
        (throw const ApiClientException(
          message: 'Stock item could not be found.',
          code: 'STOCK_ITEM_NOT_FOUND',
          statusCode: 404,
        ));
  }

  List<StockItem> _upsertStockItem(List<StockItem> items, StockItem next) {
    final updated = [
      for (final item in items)
        if (item.id == next.id) next else item,
    ];
    if (updated.any((item) => item.id == next.id)) {
      return updated;
    }
    return [...items, next];
  }

  Future<void> _reloadCurrentInventoryLane() async {
    await loadInventoryItems(
      branchId: state.selectedInventoryBranchId,
      status: 'all',
    );
  }

  String? _toUtcIso(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final parsed = DateTime.tryParse(trimmed);
    return parsed?.toUtc().toIso8601String();
  }
}
