import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';

final inventoryJournalControllerProvider =
    StateNotifierProvider<
      InventoryJournalController,
      List<InventoryJournalEntry>
    >((ref) => InventoryJournalController(ref));

class InventoryJournalController
    extends StateNotifier<List<InventoryJournalEntry>> {
  InventoryJournalController(this.ref) : super(const []);

  final Ref ref;

  InventoryJournalRepository get _repo =>
      ref.read(inventoryJournalRepositoryProvider);

  Future<void> load({String? stockItemId}) async {
    final entries = await _repo.fetch(stockItemId: stockItemId);
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = entries;
  }

  void recordEntry(InventoryJournalEntry entry) {
    final next = [entry, ...state];
    next.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = next;
  }
}
