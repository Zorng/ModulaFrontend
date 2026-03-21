import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/inventory_stock_items_page.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_state.dart';

import '../test_utils/pump_app.dart';
import 'inventory_test_fakes.dart';

void _setWideViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 800);
}

void _setNarrowViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1000, 800);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

const _stockPageItem = StockItem(
  id: 'item-1',
  name: 'Iced Coffee',
  categoryId: 'cat-1',
  baseUnit: 'ml',
  pieceSize: 1,
  branchId: '',
  branchName: '',
  onHand: 0,
  minThreshold: 3,
  isActive: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop stock items page shows numeric pagination', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await pumpApp(
      tester,
      const InventoryStockItemsPage(),
      overrides: inventoryOverrides(
        stockInventoryState: const StockInventoryState(
          stockItems: [_stockPageItem],
          stockItemsCurrentPage: 8,
          stockItemsOffset: 70,
          stockItemsPageSize: 10,
          stockItemsTotal: 200,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Showing 71-71 entries'), findsOneWidget);
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
    'desktop stock items page routes page taps through the controller',
    (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      var requestedPage = 0;

      await pumpApp(
        tester,
        const InventoryStockItemsPage(),
        overrides: inventoryOverrides(
          stockInventoryController: FakeStockInventoryController(
            const StockInventoryState(
              stockItems: [_stockPageItem],
              stockItemsCurrentPage: 8,
              stockItemsOffset: 70,
              stockItemsPageSize: 10,
              stockItemsTotal: 200,
            ),
            onGoToStockItemsPage: (page) => requestedPage = page,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '10'));
      await tester.pumpAndSettle();

      expect(requestedPage, 10);
    },
  );

  testWidgets('mobile stock items page uses lazy-load footer', (tester) async {
    _setNarrowViewport(tester);
    addTearDown(() => _resetViewport(tester));

    var loadMoreCalls = 0;

    await pumpApp(
      tester,
      const InventoryStockItemsPage(),
      overrides: inventoryOverrides(
        stockInventoryController: FakeStockInventoryController(
          const StockInventoryState(
            stockItems: [_stockPageItem],
            stockItemsCurrentPage: 1,
            stockItemsPageSize: 10,
            stockItemsTotal: 20,
          ),
          onLoadMoreStockItems: () => loadMoreCalls += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '1'), findsNothing);
    expect(find.text('Load more'), findsOneWidget);

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(loadMoreCalls, 1);
  });
}
