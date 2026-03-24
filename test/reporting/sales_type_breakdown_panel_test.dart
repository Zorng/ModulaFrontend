import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/widgets/sales_type_breakdown_panel.dart';

void main() {
  testWidgets('renders sale type rows with sale counts instead of amounts', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SalesTypeBreakdownPanel(
            items: [
              SalesTypeBreakdownItem(
                saleType: SalesType.dineIn,
                transactionCount: 56,
                totalUsd: 301,
                totalKhr: 1234100,
                totalItemsSold: 137,
              ),
              SalesTypeBreakdownItem(
                saleType: SalesType.takeaway,
                transactionCount: 63,
                totalUsd: 359.5,
                totalKhr: 1475950,
                totalItemsSold: 154,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Sale type'), findsOneWidget);
    expect(find.text('Dine in'), findsOneWidget);
    expect(find.text('56 sales'), findsOneWidget);
    expect(find.text('Items 137'), findsOneWidget);
    expect(find.text('Takeaway'), findsOneWidget);
    expect(find.text('63 sales'), findsOneWidget);
    expect(find.text('Items 154'), findsOneWidget);
    expect(find.text(r'$301.00'), findsNothing);
    expect(find.text('KHR 1,234,100'), findsNothing);
  });

  testWidgets('renders empty state when sale type data is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SalesTypeBreakdownPanel(items: [])),
      ),
    );

    expect(find.text('Sale type'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);
  });
}
