import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/widgets/sales_category_breakdown_panel.dart';

void main() {
  testWidgets('renders categories normally when there are four or fewer', (
    tester,
  ) async {
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
    expect(find.text('Top categories by quantity'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Qty 40'), findsOneWidget);
    expect(find.text('Other'), findsNothing);
  });

  testWidgets('groups categories beyond top four into Other', (tester) async {
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
              SalesCategoryBreakdownItem(
                categoryNameSnapshot: 'Tea',
                quantity: 32,
                revenueUsd: 90,
                revenueKhr: 369000,
              ),
              SalesCategoryBreakdownItem(
                categoryNameSnapshot: 'Bakery',
                quantity: 25,
                revenueUsd: 75,
                revenueKhr: 307500,
              ),
              SalesCategoryBreakdownItem(
                categoryNameSnapshot: 'Dessert',
                quantity: 18,
                revenueUsd: 60,
                revenueKhr: 246000,
              ),
              SalesCategoryBreakdownItem(
                categoryNameSnapshot: 'Sandwich',
                quantity: 11,
                revenueUsd: 42,
                revenueKhr: 172200,
              ),
              SalesCategoryBreakdownItem(
                categoryNameSnapshot: 'Smoothie',
                quantity: 9,
                revenueUsd: 30,
                revenueKhr: 123000,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);
    expect(find.text('Bakery'), findsOneWidget);
    expect(find.text('Dessert'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Qty 20'), findsOneWidget);
    expect(find.text('Sandwich'), findsNothing);
    expect(find.text('Smoothie'), findsNothing);
  });
}
