import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_item_card.dart';

import '../test_utils/pump_app.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

const _cardItem = StockItem(
  id: 'item-1',
  name: 'Matcha Powder',
  categoryId: 'cat-1',
  baseUnit: 'g',
  pieceSize: 500,
  branchId: 'branch-1',
  branchName: 'Main Branch',
  onHand: 1000,
  minThreshold: 1200,
  isActive: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCard(WidgetTester tester) {
    return pumpApp(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: InventoryItemCard(
            item: _cardItem,
            categoryLabel: 'Beverages',
            onAdjust: () {},
            onViewHistory: () {},
          ),
        ),
      ),
    );
  }

  testWidgets(
    'inventory item card shows status above quantity and stretches actions on small screens',
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      addTearDown(() => _resetViewport(tester));

      await pumpCard(tester);
      await tester.pumpAndSettle();

      final cardWidth = tester.getSize(find.byType(Card)).width;
      final statusTop = tester.getTopLeft(find.text('Low')).dy;
      final quantityTop = tester.getTopLeft(find.text('2 pcs')).dy;
      final historyWidth = tester
          .getSize(find.widgetWithText(OutlinedButton, 'View history'))
          .width;
      final adjustWidth = tester
          .getSize(find.widgetWithText(FilledButton, 'Adjust'))
          .width;

      expect(statusTop, lessThan(quantityTop));
      expect(historyWidth, greaterThan(cardWidth * 0.35));
      expect(adjustWidth, greaterThan(cardWidth * 0.35));
      expect((historyWidth - adjustWidth).abs(), lessThan(1));
    },
  );

  testWidgets(
    'inventory item card uses fixed-width actions on larger card layouts',
    (tester) async {
      _setViewport(tester, const Size(900, 844));
      addTearDown(() => _resetViewport(tester));

      await pumpCard(tester);
      await tester.pumpAndSettle();

      final cardWidth = tester.getSize(find.byType(Card)).width;
      final historyWidth = tester
          .getSize(find.widgetWithText(OutlinedButton, 'View history'))
          .width;
      final adjustWidth = tester
          .getSize(find.widgetWithText(FilledButton, 'Adjust'))
          .width;

      expect(historyWidth, moreOrLessEquals(148, epsilon: 0.1));
      expect(adjustWidth, moreOrLessEquals(148, epsilon: 0.1));
      expect(historyWidth, lessThan(cardWidth * 0.25));
      expect(adjustWidth, lessThan(cardWidth * 0.25));
    },
  );
}
