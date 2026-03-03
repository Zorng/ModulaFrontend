import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_journal_reason_label.dart';

void main() {
  test('inventoryJournalReasonLabel maps known reasons to UI labels', () {
    expect(
      inventoryJournalReasonLabel(InventoryJournalReason.restock),
      'Restock',
    );
    expect(inventoryJournalReasonLabel(InventoryJournalReason.add), 'Add');
    expect(
      inventoryJournalReasonLabel(InventoryJournalReason.remove),
      'Remove',
    );
    expect(inventoryJournalReasonLabel(InventoryJournalReason.sale), 'Sale');
    expect(inventoryJournalReasonLabel(InventoryJournalReason.voided), 'Void');
    expect(
      inventoryJournalReasonLabel(InventoryJournalReason.reopen),
      'Reopen',
    );
    expect(
      inventoryJournalReasonLabel(InventoryJournalReason.unknown),
      'Other',
    );
  });

  test('inventoryJournalEntryReasonLabel resolves unknown reason by delta', () {
    final base = DateTime.utc(2026, 3, 3);
    final positiveUnknown = InventoryJournalEntry(
      id: 'entry-1',
      itemId: 'item-1',
      itemName: 'Milk',
      branchId: 'branch-1',
      branchName: 'Main Branch',
      reason: InventoryJournalReason.unknown,
      delta: 5,
      note: '',
      actor: 'Tester',
      createdAt: base,
      occurredAt: base,
    );
    final negativeUnknown = positiveUnknown.copyWith(id: 'entry-2', delta: -3);

    expect(inventoryJournalEntryReasonLabel(positiveUnknown), 'Add');
    expect(inventoryJournalEntryReasonLabel(negativeUnknown), 'Remove');
  });
}
