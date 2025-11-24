import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/stock_batch_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_state.dart';

final stockInventoryControllerProvider =
    NotifierProvider<StockInventoryController, StockInventoryState>(() {
  return StockInventoryController();
});

class StockInventoryController extends Notifier<StockInventoryState> {
  late final StockItemRepository _repository;
  late final StockBatchRepository _batchRepository;
  bool _hasLoaded = false;

  @override
  StockInventoryState build() {
    _repository = ref.read(stockItemRepositoryProvider);
    _batchRepository = ref.read(stockBatchRepositoryProvider);
    if (!_hasLoaded) {
      _hasLoaded = true;
      Future.microtask(loadStockItems);
    }
    return const StockInventoryState();
  }

  Future<void> loadStockItems() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _repository.fetchStockItems();
      final batches = await _batchRepository.fetchBatches();
      state = state.copyWith(isLoading: false, items: items, batches: batches);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addStockItem(StockItem draft) async {
    try {
      final created = await _repository.createStockItem(draft);
      state = state.copyWith(
        items: [...state.items, created],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateStockItem(StockItem item) async {
    try {
      final updated = await _repository.updateStockItem(item);
      final items = [
        for (final existing in state.items)
          if (existing.id == updated.id) updated else existing,
      ];
      state = state.copyWith(items: items, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> restockItem({
    required String itemId,
    required int baseQty,
    String? restockDate,
    String? expiryDate,
  }) async {
    final item = state.items.firstWhere((element) => element.id == itemId);
    final updated = item.copyWith(
      onHand: item.onHand + baseQty,
      lastRestockDate: restockDate ?? item.lastRestockDate,
      expiryDate: _deriveExpiry(item, expiryDate),
    );
    await updateStockItem(updated);
    final batch = StockBatch(
      id: '',
      stockItemId: item.id,
      branchId: item.branchId,
      onHand: baseQty,
      receivedDate: restockDate ?? _todayString(),
      expiryDate: expiryDate?.isEmpty ?? true ? null : expiryDate,
    );
    final created = await _batchRepository.createBatch(batch);
    state = state.copyWith(batches: [...state.batches, created]);
  }

  Future<void> deleteStockItem(String id) async {
    try {
      await _repository.deleteStockItem(id);
      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
        batches: state.batches.where((batch) => batch.stockItemId != id).toList(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
    final batches = state.batches
        .where((batch) => batch.stockItemId == itemId)
        .toList()
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
    final batch = state.batches.firstWhere((element) => element.id == batchId);
    final newQty = batch.onHand + delta;
    if (newQty < 0) {
      throw StateError('Adjustment exceeds batch quantity');
    }
    if (newQty == 0) {
      await _batchRepository.deleteBatch(batchId);
      state = state.copyWith(
        batches: state.batches.where((element) => element.id != batchId).toList(),
      );
    } else {
      final updatedBatch = batch.copyWith(onHand: newQty);
      await _batchRepository.updateBatch(updatedBatch);
      state = state.copyWith(
        batches: state.batches
            .map((element) => element.id == batchId ? updatedBatch : element)
            .toList(),
      );
    }
    final item = state.items.firstWhere((element) => element.id == batch.stockItemId);
    final updatedItem = item.copyWith(onHand: item.onHand + delta);
    await updateStockItem(updatedItem);
  }

  String _deriveExpiry(StockItem item, String? latest) {
    if (latest == null || latest.isEmpty) return item.expiryDate;
    final existing = item.expiryDate;
    if (existing == '-' || existing.isEmpty) return latest;
    return existing.compareTo(latest) <= 0 ? existing : latest;
  }

  String _todayString() => DateTime.now().toIso8601String().split('T').first;
}
