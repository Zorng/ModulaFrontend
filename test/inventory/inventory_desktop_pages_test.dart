import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_home/inventory_home_page.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/inventory_stock_items_page.dart';

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
}
