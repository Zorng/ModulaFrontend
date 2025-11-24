import 'package:flutter_riverpod/legacy.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';

final inventoryJournalControllerProvider =
    StateNotifierProvider<
      InventoryJournalController,
      List<InventoryJournalEntry>
    >((ref) => InventoryJournalController());

class InventoryJournalController
    extends StateNotifier<List<InventoryJournalEntry>> {
  InventoryJournalController() : super(_seedEntries());

  void recordEntry(InventoryJournalEntry entry) {
    final next = [entry, ...state];
    next.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = next;
  }
}

List<InventoryJournalEntry> _seedEntries() {
  // Mock tenant: single branch, just onboarded, no items/journal entries yet.
  return const [];
}
