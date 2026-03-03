import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
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

  Future<void> load({String? branchId, String? stockItemId}) async {
    try {
      state = state.copyWith(isLoading: true, error: null, errorCode: null);
      final userBranches =
          ref.read(loginControllerProvider).user?.branches ?? const [];
      final fetched = await _repo.fetch(
        stockItemId: stockItemId,
        limit: 500,
        offset: 0,
      );

      final entries = fetched
          .where((entry) {
            if (branchId == null || branchId.isEmpty || branchId == 'all') {
              return true;
            }
            return entry.branchId == branchId;
          })
          .map((entry) {
            if (entry.branchId.isNotEmpty) return entry;
            if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
              return _withBranchFallback(
                entry,
                id: branchId,
                name: _lookupBranchName(userBranches, branchId),
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

      enriched.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      state = state.copyWith(
        isLoading: false,
        entries: enriched,
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
        error: mapped.message,
        errorCode: mapped.code,
      );
    }
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
}
