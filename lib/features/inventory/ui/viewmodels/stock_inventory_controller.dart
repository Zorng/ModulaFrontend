import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_state.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';

final stockInventoryControllerProvider =
    NotifierProvider<StockInventoryController, StockInventoryState>(() {
      return StockInventoryController();
    });

class StockInventoryController extends Notifier<StockInventoryState> {
  late final StockItemRepository _repository;
  late final InventoryJournalRepository _journalRepository;
  bool _hasLoaded = false;

  @override
  StockInventoryState build() {
    _repository = ref.read(stockItemRepositoryProvider);
    _journalRepository = ref.read(inventoryJournalRepositoryProvider);
    if (!_hasLoaded) {
      _hasLoaded = true;
      Future.microtask(loadStockItems);
    }
    return const StockInventoryState();
  }

  Future<void> loadStockItems({String? branchId}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final items = await _fetchItems(branchId: branchId);
      final categoryLookup = await _categoryLookup();
      final branchLookup = _branchLookup();
      final onHandData = await _fetchOnHand(branchId: branchId);
      final mapped = _applyOnHand(
        items
            .map(
              (item) => _withBranchName(
                _withCategoryName(item, categoryLookup),
                branchLookup,
              ),
            )
            .toList(),
        onHandData,
      );
      state = state.copyWith(
        isLoading: false,
        items: mapped,
        batches: const [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
      final mapped = _withBranchName(
        _withCategoryName(created, await _categoryLookup()),
        _branchLookup(),
      );
      state = state.copyWith(items: [...state.items, mapped], error: null);
      return mapped;
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
      final mapped = _withBranchName(
        _withCategoryName(updated, await _categoryLookup()),
        _branchLookup(),
      );
      final items = [
        for (final existing in state.items)
          if (existing.id == updated.id) mapped else existing,
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
    String? note,
    String? branchId,
  }) async {
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

  String _resolveCategory(StockItem item, Map<String, String> categoryLookup) {
    if (item.categoryId != null &&
        item.categoryId!.isNotEmpty &&
        categoryLookup[item.categoryId!] != null) {
      return categoryLookup[item.categoryId!]!;
    }
    if (item.category.isNotEmpty) return item.category;
    return 'Uncategorized';
  }

  Map<String, String> _branchLookup() {
    final user = ref.read(loginControllerProvider).user;
    final branches = user?.branches ?? const [];
    return {
      for (final b in branches)
        (b.branchId.isNotEmpty ? b.branchId : b.id): b.name,
    };
  }

  Future<Map<String, String>> _categoryLookup() async {
    // Ensure categories are loaded so the display name is available.
    final categoryNotifier = ref.read(categoryControllerProvider.notifier);
    if (ref.read(categoryControllerProvider).categories.isEmpty) {
      await categoryNotifier.loadCategories();
    }
    final categories = ref.read(categoryControllerProvider).categories;
    return {for (final c in categories) c.id: c.name};
  }

  StockItem _withCategoryName(
    StockItem item,
    Map<String, String> categoryLookup,
  ) {
    return item.copyWith(category: _resolveCategory(item, categoryLookup));
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
    List<dynamic> onHandData,
  ) {
    if (onHandData.isEmpty) return items;
    final lookup = <String, Map<String, dynamic>>{};
    for (final raw in onHandData) {
      if (raw is! Map<String, dynamic>) continue;
      final stockItemId =
          (raw['stockItemId'] ?? raw['stock_item_id'] ?? raw['id'] ?? '')
              .toString();
      if (stockItemId.isEmpty) continue;
      final branchId = (raw['branchId'] ?? raw['branch_id'] ?? '').toString();
      final key = '$stockItemId|$branchId';
      lookup[key] = raw;
    }
    return items.map((item) {
      final key = '${item.id}|${item.branchId}';
      final data = lookup[key] ?? lookup['${item.id}|'];
      if (data == null) return item;
      final onHand =
          _asInt(data['onHand']) ??
          _asInt(data['onHandQty']) ??
          _asInt(data['onHandExact']) ??
          _asInt(data['quantity']) ??
          _asInt(data['qty']);
      final minThreshold =
          _asInt(data['minThreshold']) ?? _asInt(data['threshold']);
      return item.copyWith(
        onHand: onHand ?? item.onHand,
        minThreshold: minThreshold ?? item.minThreshold,
      );
    }).toList();
  }

  Future<List<dynamic>> _fetchOnHand({String? branchId}) async {
    // If a specific branch is selected, fetch on-hand once.
    if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
      final data = await _repository.fetchOnHand(branchId: branchId);
      // Guard against backend sending the wrong branchId by filtering and stamping the requested id.
      return data
          .whereType<Map<String, dynamic>>()
          .where((raw) {
            final payloadBranch =
                (raw['branchId'] ?? raw['branch_id'] ?? '').toString();
            return payloadBranch.isEmpty || payloadBranch == branchId;
          })
          .map((raw) => {
                ...raw,
                'branchId': branchId,
                'branch_id': branchId,
              })
          .toList();
    }
    // Aggregate on-hand across all user branches.
    final branches =
        ref.read(loginControllerProvider).user?.branches ?? const [];
    if (branches.isEmpty) return const [];
    final aggregated = <String, Map<String, dynamic>>{};
    for (final branch in branches) {
      final id = branch.branchId.isNotEmpty ? branch.branchId : branch.id;
      final data = await _repository.fetchOnHand(branchId: id);
      for (final raw in data.whereType<Map<String, dynamic>>()) {
        final stockItemId =
            (raw['stockItemId'] ?? raw['stock_item_id'] ?? raw['id'] ?? '')
                .toString();
        if (stockItemId.isEmpty) continue;
        final payloadBranch =
            (raw['branchId'] ?? raw['branch_id'] ?? '').toString();
        // Ignore records that explicitly refer to a different branch to avoid bleeding counts across branches.
        if (payloadBranch.isNotEmpty && payloadBranch != id) continue;
        final key = '$stockItemId|$id';
        aggregated[key] = {
          ...raw,
          'branchId': id,
          'branch_id': id,
        };
      }
    }
    return aggregated.values.toList();
  }

  Future<List<StockItem>> _fetchItems({String? branchId}) async {
    // If a specific branch is selected, fetch only that branch.
    if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
      return _repository.fetchStockItems(branchId: branchId);
    }

    final branches =
        ref.read(loginControllerProvider).user?.branches ?? const [];
    if (branches.isEmpty) {
      return _repository.fetchStockItems();
    }

    final results = <StockItem>[];
    for (final branch in branches) {
      final id = branch.branchId.isNotEmpty ? branch.branchId : branch.id;
      final items = await _repository.fetchStockItems(branchId: id);
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

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _toUtcIso(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;
  final parsed = DateTime.tryParse(dateString);
  if (parsed == null) return null;
  return parsed.toUtc().toIso8601String();
}
