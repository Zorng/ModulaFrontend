import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';

enum InventoryJournalReasonFilter {
  restock('RESTOCK', 'Restock'),
  adjustment('ADJUSTMENT', 'Adjustment'),
  saleDeduction('SALE_DEDUCTION', 'Sale deduction'),
  voidReversal('VOID_REVERSAL', 'Void reversal'),
  other('OTHER', 'Other');

  const InventoryJournalReasonFilter(this.reasonCode, this.label);

  final String reasonCode;
  final String label;
}

InventoryJournalReason? inventoryJournalReasonFilterToDomainReason(
  InventoryJournalReasonFilter? filter,
) {
  return switch (filter) {
    InventoryJournalReasonFilter.restock => InventoryJournalReason.restock,
    InventoryJournalReasonFilter.adjustment => InventoryJournalReason.add,
    InventoryJournalReasonFilter.saleDeduction => InventoryJournalReason.sale,
    InventoryJournalReasonFilter.voidReversal => InventoryJournalReason.voided,
    InventoryJournalReasonFilter.other => InventoryJournalReason.unknown,
    null => null,
  };
}

bool inventoryJournalReasonFilterMatchesEntry(
  InventoryJournalReasonFilter filter,
  InventoryJournalEntry entry,
) {
  return switch (filter) {
    InventoryJournalReasonFilter.restock =>
      entry.reason == InventoryJournalReason.restock,
    InventoryJournalReasonFilter.adjustment =>
      entry.reason == InventoryJournalReason.add ||
          entry.reason == InventoryJournalReason.remove,
    InventoryJournalReasonFilter.saleDeduction =>
      entry.reason == InventoryJournalReason.sale,
    InventoryJournalReasonFilter.voidReversal =>
      entry.reason == InventoryJournalReason.voided,
    InventoryJournalReasonFilter.other =>
      entry.reason == InventoryJournalReason.reopen ||
          entry.reason == InventoryJournalReason.unknown,
  };
}
