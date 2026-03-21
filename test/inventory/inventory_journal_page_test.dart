import 'package:flutter/material.dart';
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
            total: 20,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Showing 11-12 entries'), findsOneWidget);
      expect(find.text('Mar 13, 2026'), findsOneWidget);
      expect(find.text('Iced Coffee'), findsNWidgets(2));
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '1'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '2'), findsOneWidget);
    },
  );

  testWidgets('desktop journal shows a numeric pagination window', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    final entries = [
      InventoryJournalEntry(
        id: 'entry-71',
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
    ];

    await pumpApp(
      tester,
      const InventoryJournalPage(),
      overrides: inventoryOverrides(
        journalState: InventoryJournalState(
          entries: entries,
          currentPage: 8,
          pageOffset: 70,
          pageSize: 10,
          total: 200,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '1'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '6'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '7'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '8'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '9'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '10'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '20'), findsOneWidget);
    expect(find.text('...'), findsNWidgets(2));
  });

  testWidgets(
    'desktop journal page numbers trigger page navigation through the controller',
    (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      var requestedPage = 0;

      await pumpApp(
        tester,
        const InventoryJournalPage(),
        overrides: inventoryOverrides(
          journalState: InventoryJournalState(
            entries: [
              InventoryJournalEntry(
                id: 'entry-71',
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
            ],
            currentPage: 8,
            pageOffset: 70,
            pageSize: 10,
            total: 200,
          ),
          inventoryJournalController: FakeInventoryJournalController(
            InventoryJournalState(
              entries: [
                InventoryJournalEntry(
                  id: 'entry-71',
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
              ],
              currentPage: 8,
              pageOffset: 70,
              pageSize: 10,
              total: 200,
            ),
            onGoToPage: (page) => requestedPage = page,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '10'));
      await tester.pumpAndSettle();

      expect(requestedPage, 10);
    },
  );

  testWidgets(
    'desktop journal disables next on the last page and highlights the current page',
    (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await pumpApp(
        tester,
        const InventoryJournalPage(),
        overrides: inventoryOverrides(
          journalState: InventoryJournalState(
            entries: [
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
            ],
            currentPage: 2,
            pageOffset: 10,
            pageSize: 10,
            total: 20,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nextButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Next'),
      );
      expect(nextButton.onPressed, isNull);

      final currentPageButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '2'),
      );
      final otherPageButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '1'),
      );
      expect(
        currentPageButton.style?.backgroundColor?.resolve({}),
        isNot(equals(otherPageButton.style?.backgroundColor?.resolve({}))),
      );
    },
  );
}
