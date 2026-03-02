import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> loadStockItems({String? branchId}) async {
    try {
      state = state.copyWith(isLoading: true, error: null, errorCode: null);
      final items = await _fetchItems(branchId: branchId);
      final branchLookup = _branchLookup();
      final onHandData = await _fetchOnHand(branchId: branchId);
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

  Future<void> updateStockItem(
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
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to update stock item.',
      );
      state = state.copyWith(error: mapped.message, errorCode: mapped.code);
      rethrow;
    }
  }

  Future<void> restockItem({
    required String itemId,
    required int baseQty,
    String? restockDate,
    String? expiryDate,
    String? note,
    String? branchId,
  }) async {
    try {
      final item = state.items.firstWhere((element) => element.id == itemId);
      final targetBranch =
          branchId ?? (item.branchId.isNotEmpty ? item.branchId : null);
      final occurredAt = _toUtcIso(restockDate);
      await _journalRepository.receive(
        branchId: targetBranch ?? '',
        stockItemId: item.id,
        qty: baseQty,
        note: note,
        occurredAt: occurredAt,
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

  Future<void> deleteStockItem(String id) async {
    try {
      await _repository.deleteStockItem(id);
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
        fallbackMessage: 'Failed to delete stock item.',
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

  Future<void> adjustBatch({
    required String batchId,
    required int delta,
  }) async {
    final batch = state.batches.firstWhere(
      (element) => element.id == batchId,
      orElse: () => state.batches.isNotEmpty
          ? state.batches.first
          : StockBatch(
              id: batchId,
              stockItemId: batchId,
              branchId: 'all',
              onHand: 0,
              receivedDate: _todayString(),
            ),
    );
    final item = state.items.firstWhere(
      (element) => element.id == batch.stockItemId || element.id == batchId,
      orElse: () => state.items.first,
    );
    final newQty = item.onHand + delta;
    if (newQty < 0) {
      throw StateError('Adjustment exceeds available quantity');
    }
    await _journalRepository.correct(
      branchId: item.branchId,
      stockItemId: item.id,
      delta: delta,
      note: 'Manual adjustment',
    );
    final updatedItem = item.copyWith(onHand: newQty);
    await updateStockItem(updatedItem);
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

  Future<List<OnHandRecord>> _fetchOnHand({String? branchId}) async {
    // If a specific branch is selected, fetch on-hand once.
    if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
      final data = await _branchStockRepository.fetchOnHand(branchId: branchId);
      return data
          .map(
            (record) => record.branchId.isEmpty
                ? OnHandRecord(
                    stockItemId: record.stockItemId,
                    branchId: branchId,
                    onHand: record.onHand,
                    minThreshold: record.minThreshold,
                  )
                : record,
          )
          .where((record) => record.branchId == branchId)
          .toList(growable: false);
    }
    // Aggregate on-hand across all user branches.
    final branches =
        ref.read(loginControllerProvider).user?.branches ?? const [];
    if (branches.isEmpty) return const [];
    final aggregated = <String, OnHandRecord>{};
    for (final branch in branches) {
      final id = branch.branchId.isNotEmpty ? branch.branchId : branch.id;
      final data = await _branchStockRepository.fetchOnHand(branchId: id);
      for (final record in data) {
        if (record.stockItemId.isEmpty) continue;
        final key = '${record.stockItemId}|$id';
        aggregated[key] = record.branchId.isEmpty
            ? OnHandRecord(
                stockItemId: record.stockItemId,
                branchId: id,
                onHand: record.onHand,
                minThreshold: record.minThreshold,
              )
            : record;
      }
    }
    return aggregated.values.toList();
  }

  Future<List<StockItem>> _fetchItems({String? branchId}) async {
    // If a specific branch is selected, fetch only that branch.
    if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
      return _branchStockRepository.fetchStockItems(branchId: branchId);
    }

    final branches =
        ref.read(loginControllerProvider).user?.branches ?? const [];
    if (branches.isEmpty) {
      return _branchStockRepository.fetchStockItems();
    }

    final results = <StockItem>[];
    for (final branch in branches) {
      final id = branch.branchId.isNotEmpty ? branch.branchId : branch.id;
      final items = await _branchStockRepository.fetchStockItems(branchId: id);
      results.addAll(items);
    }

    // Deduplicate by stock item id + branch.
    final seen = <String>{};
    final deduped = <StockItem>[];
    for (final item in results) {
      final key = '${item.id}|${item.branchId}';
      if (seen.add(key)) {
        deduped.add(item);
      }
    }
    return deduped;
  }
}

String? _toUtcIso(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;
  final parsed = DateTime.tryParse(dateString);
  if (parsed == null) return null;
  return parsed.toUtc().toIso8601String();
}
