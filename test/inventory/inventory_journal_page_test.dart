import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/inventory_journal_page.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_state.dart';

import 'inventory_test_fakes.dart';
import '../test_utils/pump_app.dart';

void _setWideViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 800);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'desktop journal repeats the date divider when a date continues on the next page',
    (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      final continuedDateEntries = [
        InventoryJournalEntry(
          id: 'entry-11',
          itemId: 'item-1',
          itemName: 'Iced Coffee',
          branchId: 'branch-1',
          branchName: 'Main Branch',
          reason: InventoryJournalReason.restock,
          delta: 10,
          note: 'Restock recorded',
          actor: 'Alex',
          createdAt: DateTime.utc(2026, 3, 13, 3),
          occurredAt: DateTime.utc(2026, 3, 13, 3),
        ),
        InventoryJournalEntry(
          id: 'entry-12',
          itemId: 'item-1',
          itemName: 'Iced Coffee',
          branchId: 'branch-1',
          branchName: 'Main Branch',
          reason: InventoryJournalReason.add,
          delta: 2,
          note: 'Adjustment recorded',
          actor: 'Alex',
          createdAt: DateTime.utc(2026, 3, 12, 20),
          occurredAt: DateTime.utc(2026, 3, 12, 20),
        ),
      ];

      await pumpApp(
        tester,
        const InventoryJournalPage(),
        overrides: inventoryOverrides(
          journalState: InventoryJournalState(
            entries: continuedDateEntries,
            currentPage: 2,
            pageOffset: 10,
            hasNextPage: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Showing 11-12 entries'), findsOneWidget);
      expect(find.text('Mar 13, 2026'), findsOneWidget);
      expect(find.text('Iced Coffee'), findsNWidgets(2));
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    },
  );
}
