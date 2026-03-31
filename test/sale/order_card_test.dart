import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/order_card.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

Order _orderWithLines(List<OrderLine> lines) {
  return Order(
    id: 'order-1',
    saleId: 'sale-1',
    number: 'ORDER-001',
    status: 'pending',
    ticketStatus: 'PAID',
    placedAt: DateTime(2026, 3, 31, 10),
    orderType: 'take_away',
    paymentMethod: 'cash',
    totalUsd: 12,
    totalKhr: 48000,
    tenderCurrency: 'usd',
    tenderAmount: 12,
    changeAmount: 0,
    lines: lines,
  );
}

void main() {
  testWidgets(
    'fixed-height order card previews three items and keeps footer pinned',
    (tester) async {
      final order = _orderWithLines(const [
        OrderLine(name: 'Americano', modifiers: [], quantity: 1),
        OrderLine(name: 'Latte', modifiers: [], quantity: 1),
        OrderLine(name: 'Mocha', modifiers: [], quantity: 1),
        OrderLine(name: 'Flat White', modifiers: [], quantity: 1),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                height: 340,
                child: OrderCard(order: order, fillHeight: true, onTap: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Americano'), findsOneWidget);
      expect(find.text('Latte'), findsOneWidget);
      expect(find.text('Mocha'), findsOneWidget);
      expect(find.text('Flat White'), findsNothing);
      expect(find.text('See 1 more'), findsOneWidget);
      expect(find.text('\$12.00'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('\$12.00')).dy,
        greaterThan(tester.getTopLeft(find.text('See 1 more')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
