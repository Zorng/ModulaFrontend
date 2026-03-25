import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/widgets/sales_category_breakdown_panel.dart';

void main() {
  testWidgets('renders an empty category breakdown card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SalesCategoryBreakdownPanel(
            categories: [
              SalesCategoryBreakdownItem(
                categoryNameSnapshot: 'Coffee',
                quantity: 40,
                revenueUsd: 120,
                revenueKhr: 492000,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Category breakdown'), findsOneWidget);
    expect(find.text('Coffee'), findsNothing);
    expect(find.textContaining('Qty '), findsNothing);
  });
}
