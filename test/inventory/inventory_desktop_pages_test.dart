import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_home/inventory_home_page.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/inventory_stock_items_page.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_state.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_state.dart';

import '../test_utils/pump_app.dart';
import 'inventory_test_fakes.dart';

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

  testWidgets('inventory home wide screen renders desktop table', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await pumpApp(
      tester,
      const InventoryHomePage(),
      overrides: inventoryOverrides(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Item Name'), findsOneWidget);
    expect(find.text('Current On Hand'), findsOneWidget);
    expect(find.text('Iced Coffee'), findsOneWidget);
  });

  testWidgets('stock items wide screen renders desktop table', (tester) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await pumpApp(
      tester,
      const InventoryStockItemsPage(),
      overrides: inventoryOverrides(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Item'), findsOneWidget);
    expect(find.text('Threshold'), findsOneWidget);
    expect(find.text('Iced Coffee'), findsOneWidget);
  });

  testWidgets(
    'inventory home view history uses current branch filter and item id',
    (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      FakeInventoryJournalLoadCall? capturedLoad;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => ProviderScope(
              overrides: inventoryOverrides(
                stockInventoryState: const StockInventoryState(
                  selectedInventoryBranchId: 'branch-1',
                  inventoryItems: [
                    StockItem(
                      id: 'item-1',
                      name: 'Iced Coffee',
                      categoryId: 'cat-1',
                      baseUnit: 'ml',
                      pieceSize: 1,
                      branchId: '',
                      branchName: '',
                      onHand: 12,
                      minThreshold: 3,
                      isActive: true,
                    ),
                  ],
                ),
                inventoryJournalController: FakeInventoryJournalController(
                  const InventoryJournalState(),
                  onLoad: (call) => capturedLoad = call,
                ),
              ),
              child: const InventoryHomePage(),
            ),
          ),
          GoRoute(
            path: AppRoute.inventoryJournal.path,
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View history').first);
      await tester.pumpAndSettle();

      expect(capturedLoad, isNotNull);
      expect(capturedLoad!.branchId, 'branch-1');
      expect(capturedLoad!.stockItemId, 'item-1');
      expect(
        router.routeInformationProvider.value.uri.toString(),
        AppRoute.inventoryJournal.path,
      );
    },
  );
}
