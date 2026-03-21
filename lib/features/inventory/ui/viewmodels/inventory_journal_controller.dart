import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_journal_date_filter.dart';
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
    InventoryJournalDateFilter? dateFilter,
    int limit = 10,
    int page = 1,
    bool pageTransition = false,
    bool accumulatePages = false,
  }) async {
    final safeLimit = limit <= 0 ? 10 : limit;
    final safePage = page <= 0 ? 1 : page;
    final safeOffset = (safePage - 1) * safeLimit;
    final resolvedDateFilter = resolveInventoryJournalDateFilter(
      dateFilter ?? state.dateFilter,
    );
    final normalizedBranchId =
        (branchId != null && branchId.isNotEmpty && branchId != 'all')
        ? branchId
        : null;
    final normalizedStockItemId = stockItemId ?? '';
    try {
      state = state.copyWith(
        isLoading: !pageTransition,
        isPageLoading: pageTransition,
        error: null,
        errorCode: null,
        pageSize: safeLimit,
        scope: normalizedBranchId == null
            ? InventoryJournalScope.tenantWide
            : InventoryJournalScope.branch,
        selectedBranchId: normalizedBranchId ?? 'all',
        selectedStockItemId: normalizedStockItemId,
        selectedReason: reason,
        dateFilter: resolvedDateFilter,
      );
      final userBranches =
          ref.read(loginControllerProvider).user?.branches ?? const [];
      final fetched = await _repo.fetch(
        branchId: normalizedBranchId,
        tenantWide: normalizedBranchId == null,
        stockItemId: stockItemId,
        reason: reason,
        date: resolvedDateFilter.date,
        from: resolvedDateFilter.date == null ? resolvedDateFilter.from : null,
        to: resolvedDateFilter.date == null ? resolvedDateFilter.to : null,
        limit: safeLimit,
        offset: safeOffset,
      );

      final entries = fetched.items
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

      if (enriched.isEmpty && safePage > 1) {
        state = state.copyWith(
          isLoading: false,
          isPageLoading: false,
          total: fetched.total,
          error: null,
          errorCode: null,
        );
        return;
      }

      final nextEntries = accumulatePages && safePage > 1
          ? [...state.entries, ...enriched]
          : enriched;
      nextEntries.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      state = state.copyWith(
        isLoading: false,
        isPageLoading: false,
        isAccumulatingPages: accumulatePages,
        entries: nextEntries,
        currentPage: safePage,
        pageOffset: accumulatePages ? 0 : safeOffset,
        total: fetched.total,
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
        isPageLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  Future<void> goToNextPage({
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
  }) async {
    if (state.isLoading || state.isPageLoading) return;
    if (!state.hasNextPage) return;
    final selectedBranchId = branchId ?? state.selectedBranchId;
    final selectedStockItemId = stockItemId ?? state.selectedStockItemId;
    await load(
      branchId: selectedBranchId == 'all' ? null : selectedBranchId,
      stockItemId: selectedStockItemId.isEmpty ? null : selectedStockItemId,
      reason: reason ?? state.selectedReason,
      dateFilter: state.dateFilter,
      limit: state.pageSize,
      page: state.currentPage + 1,
      pageTransition: true,
      accumulatePages: false,
    );
  }

  Future<void> goToPage(
    int page, {
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
  }) async {
    if (state.isLoading || state.isPageLoading) return;
    if (page < 1 || page > state.totalPages || page == state.currentPage) {
      return;
    }
    final selectedBranchId = branchId ?? state.selectedBranchId;
    final selectedStockItemId = stockItemId ?? state.selectedStockItemId;
    await load(
      branchId: selectedBranchId == 'all' ? null : selectedBranchId,
      stockItemId: selectedStockItemId.isEmpty ? null : selectedStockItemId,
      reason: reason ?? state.selectedReason,
      dateFilter: state.dateFilter,
      limit: state.pageSize,
      page: page,
      pageTransition: true,
      accumulatePages: false,
    );
  }

  Future<void> goToPreviousPage({
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
  }) async {
    if (state.isLoading || state.isPageLoading) return;
    if (!state.hasPreviousPage) return;
    final selectedBranchId = branchId ?? state.selectedBranchId;
    final selectedStockItemId = stockItemId ?? state.selectedStockItemId;
    await load(
      branchId: selectedBranchId == 'all' ? null : selectedBranchId,
      stockItemId: selectedStockItemId.isEmpty ? null : selectedStockItemId,
      reason: reason ?? state.selectedReason,
      dateFilter: state.dateFilter,
      limit: state.pageSize,
      page: state.currentPage - 1,
      pageTransition: true,
      accumulatePages: false,
    );
  }

  Future<void> loadNextChunk({
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
  }) async {
    if (state.isLoading || state.isPageLoading) return;
    if (!state.hasNextPage) return;
    final selectedBranchId = branchId ?? state.selectedBranchId;
    final selectedStockItemId = stockItemId ?? state.selectedStockItemId;
    await load(
      branchId: selectedBranchId == 'all' ? null : selectedBranchId,
      stockItemId: selectedStockItemId.isEmpty ? null : selectedStockItemId,
      reason: reason ?? state.selectedReason,
      dateFilter: state.dateFilter,
      limit: state.pageSize,
      page: state.currentPage + 1,
      pageTransition: true,
      accumulatePages: true,
    );
  }

  void recordEntry(InventoryJournalEntry entry) {
    final next = state.currentPage == 1
        ? [entry, ...state.entries].take(state.pageSize).toList(growable: false)
        : [...state.entries];
    next.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    state = state.copyWith(
      entries: next,
      total: state.total + 1,
      isAccumulatingPages: state.isAccumulatingPages,
      error: null,
      errorCode: null,
    );
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
    final fetched = await _stockRepo.fetchMasterStockItems();
    return {for (final item in fetched.items) item.id: item.name};
  }

  bool _hasRealName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.toLowerCase() == 'item') return false;
    return true;
  }
}
