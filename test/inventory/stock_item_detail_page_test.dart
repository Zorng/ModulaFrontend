import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_item_detail/stock_item_detail_page.dart';

import '../test_utils/pump_app.dart';
import 'inventory_test_fakes.dart';

void main() {
  testWidgets('renders stock item details for provided item', (
    tester,
  ) async {
    await pumpApp(
      tester,
      StockItemDetailPage(item: testStockItems.first),
      overrides: inventoryOverrides(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stock item details'), findsOneWidget);
    expect(find.text('Iced Coffee'), findsOneWidget);
    expect(find.text('ml'), findsOneWidget);
  });
}
