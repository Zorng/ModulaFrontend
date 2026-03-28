import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/widgets/sales_top_items_panel.dart';

void main() {
  testWidgets('renders top item rows with quantity only', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SalesTopItemsPanel(
            items: [
              SalesTopItem(
                menuItemId: 'menu-item-1',
                itemNameSnapshot: 'Iced Latte',
                quantity: 84,
                revenueUsd: 210,
                revenueKhr: 861000,
              ),
              SalesTopItem(
                menuItemId: 'menu-item-2',
                itemNameSnapshot: 'Croissant',
                quantity: 32,
                revenueUsd: 96,
                revenueKhr: 393600,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Top items'), findsOneWidget);
    expect(find.text('Best-selling items by quantity'), findsOneWidget);
    expect(find.text('Iced Latte'), findsOneWidget);
    expect(find.text('Qty 84'), findsOneWidget);
    expect(find.text('Croissant'), findsOneWidget);
    expect(find.text('Qty 32'), findsOneWidget);
    expect(find.text(r'$210.00'), findsNothing);
    expect(find.text('KHR 861,000'), findsNothing);
  });

  testWidgets('renders empty state when top items are missing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SalesTopItemsPanel(items: [])),
      ),
    );

    expect(find.text('Top items'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);
  });
}
