import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_state.dart';

final stockInventoryControllerProvider =
    NotifierProvider<StockInventoryController, StockInventoryState>(() {
  return StockInventoryController();
});

class StockInventoryController extends Notifier<StockInventoryState> {
  late final StockItemRepository _repository;
  bool _hasLoaded = false;

  @override
  StockInventoryState build() {
    _repository = ref.read(stockItemRepositoryProvider);
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
      state = state.copyWith(isLoading: false, items: items);
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
      expiryDate: expiryDate ?? item.expiryDate,
    );
    await updateStockItem(updated);
  }

  Future<void> deleteStockItem(String id) async {
    try {
      await _repository.deleteStockItem(id);
      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
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
}
