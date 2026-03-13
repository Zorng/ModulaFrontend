import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_state.dart';

final inventoryJournalControllerProvider =
    NotifierProvider<InventoryJournalController, InventoryJournalState>(
      InventoryJournalController.new,
    );

class InventoryJournalController extends Notifier<InventoryJournalState> {
  late final InventoryJournalRepository _repo;
  late final StockItemRepository _stockRepo;

  @override
  InventoryJournalState build() {
    _repo = ref.read(inventoryJournalRepositoryProvider);
    _stockRepo = ref.read(stockItemRepositoryProvider);
    return const InventoryJournalState();
  }

  Future<void> load({
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
    int limit = 50,
    int offset = 0,
    bool append = false,
  }) async {
    final safeLimit = limit <= 0 ? 50 : limit;
    final safeOffset = offset < 0 ? 0 : offset;
    final normalizedBranchId =
        (branchId != null && branchId.isNotEmpty && branchId != 'all')
        ? branchId
        : null;
    final normalizedStockItemId = stockItemId ?? '';
    try {
      state = state.copyWith(
        isLoading: !append,
        isLoadingMore: append,
        error: null,
        errorCode: null,
        limit: safeLimit,
        scope: normalizedBranchId == null
            ? InventoryJournalScope.tenantWide
            : InventoryJournalScope.branch,
        selectedBranchId: normalizedBranchId ?? 'all',
        selectedStockItemId: normalizedStockItemId,
        selectedReason: reason,
      );
      final userBranches =
          ref.read(loginControllerProvider).user?.branches ?? const [];
      final fetched = await _repo.fetch(
        branchId: normalizedBranchId,
        tenantWide: normalizedBranchId == null,
        stockItemId: stockItemId,
        reason: reason,
        limit: safeLimit,
        offset: safeOffset,
      );

      final entries = fetched
          .where((entry) {
            if (normalizedBranchId == null) {
              return true;
            }
            return entry.branchId == normalizedBranchId;
          })
          .map((entry) {
            if (entry.branchId.isNotEmpty) return entry;
            if (normalizedBranchId != null) {
              return _withBranchFallback(
                entry,
                id: normalizedBranchId,
                name: _lookupBranchName(userBranches, normalizedBranchId),
              );
            }
            return entry;
          })
          .toList(growable: false);

      // Enrich missing item names from stock items.
      final nameLookup = await _itemNameLookup();
      final enriched = entries
          .map(
            (e) => _hasRealName(e.itemName)
                ? e
                : e.copyWith(itemName: nameLookup[e.itemId] ?? e.itemName),
          )
          .toList();

      final nextEntries = append
          ? _mergeEntries(state.entries, enriched)
          : enriched;
      nextEntries.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      final hasMore = fetched.length == safeLimit;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        entries: nextEntries,
        offset: safeOffset + fetched.length,
        hasMore: hasMore,
        error: null,
        errorCode: null,
      );
    } catch (e) {
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to load inventory journal.',
      );
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  Future<void> loadMore({
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
  }) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!state.hasMore) return;
    final selectedBranchId = branchId ?? state.selectedBranchId;
    final selectedStockItemId = stockItemId ?? state.selectedStockItemId;
    await load(
      branchId: selectedBranchId == 'all' ? null : selectedBranchId,
      stockItemId: selectedStockItemId.isEmpty ? null : selectedStockItemId,
      reason: reason ?? state.selectedReason,
      limit: state.limit,
      offset: state.offset,
      append: true,
    );
  }

  void recordEntry(InventoryJournalEntry entry) {
    final next = [entry, ...state.entries];
    next.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    state = state.copyWith(entries: next, error: null, errorCode: null);
  }

  InventoryJournalEntry _withBranchFallback(
    InventoryJournalEntry entry, {
    required String id,
    String? name,
  }) {
    final branchName = entry.branchName.isNotEmpty
        ? entry.branchName
        : (name ?? entry.branchName);
    final branchId = entry.branchId.isNotEmpty ? entry.branchId : id;
    return entry.copyWith(branchId: branchId, branchName: branchName);
  }

  String _lookupBranchName(List<UserBranch> branches, String id) {
    for (final b in branches) {
      final branchId = b.branchId.isNotEmpty ? b.branchId : b.id;
      if (branchId == id) return b.name;
    }
    return '';
  }

  Future<Map<String, String>> _itemNameLookup() async {
    final items = await _stockRepo.fetchMasterStockItems();
    return {for (final item in items) item.id: item.name};
  }

  bool _hasRealName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.toLowerCase() == 'item') return false;
    return true;
  }

  List<InventoryJournalEntry> _mergeEntries(
    List<InventoryJournalEntry> existing,
    List<InventoryJournalEntry> next,
  ) {
    final seen = <String>{for (final entry in existing) entry.id};
    final merged = <InventoryJournalEntry>[...existing];
    for (final entry in next) {
      if (seen.add(entry.id)) merged.add(entry);
    }
    return merged;
  }
}
