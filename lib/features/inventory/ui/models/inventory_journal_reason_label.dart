import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';

String inventoryJournalReasonLabel(InventoryJournalReason reason) {
  return switch (reason) {
    InventoryJournalReason.restock => 'Restock',
    InventoryJournalReason.add => 'Add',
    InventoryJournalReason.remove => 'Remove',
    InventoryJournalReason.sale => 'Sale',
    InventoryJournalReason.voided => 'Void',
    InventoryJournalReason.reopen => 'Reopen',
    InventoryJournalReason.unknown => 'Other',
  };
}

String inventoryJournalEntryReasonLabel(InventoryJournalEntry entry) {
  if (entry.reason == InventoryJournalReason.unknown) {
    return entry.delta >= 0 ? 'Add' : 'Remove';
  }
  return inventoryJournalReasonLabel(entry.reason);
}
