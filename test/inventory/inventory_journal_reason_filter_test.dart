import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_journal_reason_filter.dart';

void main() {
  test('inventoryJournalReasonFilterToDomainReason maps contract filters', () {
    expect(
      inventoryJournalReasonFilterToDomainReason(
        InventoryJournalReasonFilter.restock,
      ),
      InventoryJournalReason.restock,
    );
    expect(
      inventoryJournalReasonFilterToDomainReason(
        InventoryJournalReasonFilter.adjustment,
      ),
      InventoryJournalReason.add,
    );
    expect(
      inventoryJournalReasonFilterToDomainReason(
        InventoryJournalReasonFilter.saleDeduction,
      ),
      InventoryJournalReason.sale,
    );
    expect(
      inventoryJournalReasonFilterToDomainReason(
        InventoryJournalReasonFilter.voidReversal,
      ),
      InventoryJournalReason.voided,
    );
    expect(
      inventoryJournalReasonFilterToDomainReason(
        InventoryJournalReasonFilter.other,
      ),
      InventoryJournalReason.unknown,
    );
    expect(inventoryJournalReasonFilterToDomainReason(null), isNull);
  });

  test(
    'inventoryJournalReasonFilterMatchesEntry groups domain reasons by contract filter',
    () {
      final base = DateTime.utc(2026, 3, 6);
      InventoryJournalEntry entry(InventoryJournalReason reason, int delta) {
        return InventoryJournalEntry(
          id: '$reason-$delta',
          itemId: 'item-1',
          itemName: 'Milk',
          branchId: 'branch-1',
          branchName: 'Main Branch',
          reason: reason,
          delta: delta,
          note: '',
          actor: 'Tester',
          createdAt: base,
          occurredAt: base,
        );
      }

      expect(
        inventoryJournalReasonFilterMatchesEntry(
          InventoryJournalReasonFilter.adjustment,
          entry(InventoryJournalReason.add, 5),
        ),
        isTrue,
      );
      expect(
        inventoryJournalReasonFilterMatchesEntry(
          InventoryJournalReasonFilter.adjustment,
          entry(InventoryJournalReason.remove, -3),
        ),
        isTrue,
      );
      expect(
        inventoryJournalReasonFilterMatchesEntry(
          InventoryJournalReasonFilter.other,
          entry(InventoryJournalReason.reopen, 2),
        ),
        isTrue,
      );
      expect(
        inventoryJournalReasonFilterMatchesEntry(
          InventoryJournalReasonFilter.other,
          entry(InventoryJournalReason.unknown, -1),
        ),
        isTrue,
      );
      expect(
        inventoryJournalReasonFilterMatchesEntry(
          InventoryJournalReasonFilter.saleDeduction,
          entry(InventoryJournalReason.remove, -1),
        ),
        isFalse,
      );
    },
  );
}
