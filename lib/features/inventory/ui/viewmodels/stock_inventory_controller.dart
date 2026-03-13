import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/on_hand_record.dart';
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

  Future<void> loadStockItems({String? branchId, String status = 'all'}) async {
    try {
      state = state.copyWith(isLoading: true, error: null, errorCode: null);
      final items = await _fetchItems(branchId: branchId, status: status);
      final branchLookup = _branchLookup();
      final onHandData = await _fetchOnHand(branchId: branchId, status: status);
      final mapped = _applyOnHand(
        items.map((item) => _withBranchName(item, branchLookup)).toList(),
        onHandData,
      );
      state = state.copyWith(
        isLoading: false,
        items: mapped,
        batches: const [],
      );
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to load stock items.',
      );
      state = state.copyWith(
        isLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  Future<void> loadRestockBatches({
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
    final canAppend =
        append &&
        normalizedStatus == state.restockBatchStatus &&
        normalizedStockItemId == state.restockBatchStockItemId;
    try {
      state = state.copyWith(
        isBatchesLoading: !canAppend,
        isLoadingMoreBatches: canAppend,
        error: null,
        errorCode: null,
        restockBatchLimit: safeLimit,
        restockBatchStatus: normalizedStatus,
        restockBatchStockItemId: normalizedStockItemId,
        hasMoreRestockBatches: canAppend ? state.hasMoreRestockBatches : true,
      );
      final batches = await _journalRepository.fetchRestockBatches(
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
      final updated = await _journalRepository.updateRestockBatchMetadata(
        batchId: batchId,
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
      await _journalRepository.archiveRestockBatch(batchId: batchId);
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
      final mapped = _withBranchName(created, _branchLookup());
      state = state.copyWith(
        items: [...state.items, mapped],
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
      final mapped = _withBranchName(updated, _branchLookup());
      final items = [
        for (final existing in state.items)
          if (existing.id == updated.id) mapped else existing,
      ];
      state = state.copyWith(items: items, error: null, errorCode: null);
      return mapped;
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
      final item = state.items.firstWhere((element) => element.id == itemId);
      final targetBranch =
          branchId ?? (item.branchId.isNotEmpty ? item.branchId : null);
      final occurredAt = _toUtcIso(restockDate);
      await _journalRepository.createRestockBatch(
        branchId: targetBranch ?? '',
        stockItemId: item.id,
        qty: baseQty,
        receivedAt: occurredAt,
        expiryDate: expiryDate,
        supplierName: supplierName,
        purchaseCostUsd: purchaseCostUsd,
        note: note,
      );
      // Refresh inventory for the relevant branch to pick up backend on-hand changes.
      final reloadBranch =
          (branchId != null && branchId.isNotEmpty && branchId != 'all')
          ? branchId
          : null;
      await loadStockItems(branchId: reloadBranch);
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
        items: state.items.where((item) => item.id != id).toList(),
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
      final items = [
        for (final item in state.items)
          if (item.id == id) item.copyWith(isActive: true) else item,
      ];
      state = state.copyWith(items: items, error: null, errorCode: null);
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
    try {
      return state.items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<StockItem> loadStockItemDetail(String id) async {
    try {
      final detail = await _repository.fetchStockItemById(id);
      final existing = findById(id);
      final merged = existing == null
          ? detail
          : detail.copyWith(
              branchId: existing.branchId,
              branchName: existing.branchName,
              onHand: existing.onHand,
              minThreshold: existing.minThreshold,
            );
      final items = [
        for (final item in state.items)
          if (item.id == merged.id) merged else item,
      ];
      final hasMerged = items.any((item) => item.id == merged.id);
      state = state.copyWith(
        items: hasMerged ? items : [...state.items, merged],
        error: null,
        errorCode: null,
      );
      return merged;
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
      final item = state.items.firstWhere(
        (element) =>
            element.id == stockItemId ||
            (batch != null && element.id == batch.stockItemId),
        orElse: () => state.items.first,
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
          : item.onHand + resolvedDelta!;
      if (expectedOnHand < 0) {
        throw const ApiClientException(
          message: 'Adjustment exceeds available quantity.',
          code: 'INVENTORY_QUANTITY_INVALID',
          statusCode: 422,
        );
      }
      final resultingOnHand = await _journalRepository.applyAdjustment(
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
      final nextItems = [
        for (final existing in state.items)
          if (existing.id == item.id)
            existing.copyWith(onHand: resolvedOnHand)
          else
            existing,
      ];
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
        items: nextItems,
        batches: nextBatches,
        error: null,
        errorCode: null,
      );
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
      for (final item in state.items)
        if (item.id == stockItemId)
          item.copyWith(
            branchId: branchId,
            branchName: branchName ?? item.branchName,
            minThreshold: minThreshold,
          )
        else
          item,
    ];
    state = state.copyWith(items: updatedItems);
  }

  String _todayString() => DateTime.now().toIso8601String().split('T').first;

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
    final targetBranch =
        (branchId != null && branchId.isNotEmpty && branchId != 'all')
        ? branchId
        : null;
    if (targetBranch == null) {
      // All-branch mode uses aggregate stock endpoint values directly.
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
      // Branch stock projection is non-critical for rendering the catalog list.
      return const [];
    }
  }

  Future<List<StockItem>> _fetchItems({
    String? branchId,
    String status = 'all',
  }) async {
    final targetBranch =
        (branchId != null && branchId.isNotEmpty && branchId != 'all')
        ? branchId
        : null;
    try {
      final items = await _branchStockRepository.fetchStockItems(
        branchId: targetBranch,
        status: status,
      );
      if (items.isNotEmpty) return items;
    } catch (_) {
      // Fall back to master stock-item catalog when branch stock read fails.
    }
    final master = await _repository.fetchMasterStockItems();
    final normalizedStatus = status.trim().toLowerCase();
    final branchName = targetBranch != null
        ? (_branchLookup()[targetBranch] ?? '')
        : '';
    return master
        .map(
          (item) => item.copyWith(
            branchId: targetBranch ?? item.branchId,
            branchName: targetBranch != null ? branchName : item.branchName,
            onHand: 0,
          ),
        )
        .where((item) {
          switch (normalizedStatus) {
            case 'active':
              return item.isActive;
            case 'archived':
              return !item.isActive;
            case 'all':
            default:
              return true;
          }
        })
        .toList(growable: false);
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
}

String? _toUtcIso(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;
  final parsed = DateTime.tryParse(dateString);
  if (parsed == null) return null;
  return parsed.toUtc().toIso8601String();
}

String _normalizeListStatus(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'active':
    case 'archived':
    case 'all':
      return raw.trim().toLowerCase();
    default:
      return 'all';
  }
}
