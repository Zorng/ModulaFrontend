import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

final inventoryJournalControllerProvider =
    NotifierProvider<InventoryJournalController, List<InventoryJournalEntry>>(
  InventoryJournalController.new,
);

class InventoryJournalController extends Notifier<List<InventoryJournalEntry>> {
  late final InventoryJournalRepository _repo;
  late final StockItemRepository _stockRepo;

  @override
  List<InventoryJournalEntry> build() {
    _repo = ref.read(inventoryJournalRepositoryProvider);
    _stockRepo = ref.read(stockItemRepositoryProvider);
    return const [];
  }

  Future<void> load({String? branchId, String? stockItemId}) async {
    final userBranches = ref.read(loginControllerProvider).user?.branches ?? const [];
    final entries = <InventoryJournalEntry>[];

    // When a specific branch is requested, only fetch that branch.
    if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
      final fetched = await _repo.fetch(branchId: branchId, stockItemId: stockItemId);
      entries.addAll(
        fetched.map(
          (e) => _withBranchFallback(
            e,
            id: branchId,
            name: _lookupBranchName(userBranches, branchId),
          ),
        ),
      );
    } else if (userBranches.isNotEmpty) {
      // Otherwise, fetch all branches the user has access to.
      for (final branch in userBranches) {
        final id = branch.branchId.isNotEmpty ? branch.branchId : branch.id;
        final fetched = await _repo.fetch(branchId: id, stockItemId: stockItemId);
        entries.addAll(
          fetched.map(
            (e) => _withBranchFallback(e, id: id, name: branch.name),
          ),
        );
      }
    } else {
      // Fallback to whatever the backend returns when no branch filter is provided.
      entries.addAll(await _repo.fetch(stockItemId: stockItemId));
    }

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
    state = enriched;
  }

  void recordEntry(InventoryJournalEntry entry) {
    final next = [entry, ...state];
    next.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    state = next;
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
