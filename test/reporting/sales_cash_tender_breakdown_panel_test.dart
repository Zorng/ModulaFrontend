import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/widgets/sales_cash_tender_breakdown_panel.dart';

void main() {
  testWidgets('renders cash tender totals for each tender currency', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SalesCashTenderBreakdownPanel(
            items: [
              SalesCashTenderBreakdownItem(
                tenderCurrency: SalesTenderCurrency.usd,
                transactionCount: 61,
                totalTenderAmount: 310,
              ),
              SalesCashTenderBreakdownItem(
                tenderCurrency: SalesTenderCurrency.khr,
                transactionCount: 11,
                totalTenderAmount: 1270000,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Cash tender'), findsOneWidget);
    expect(find.text('72 cash sales'), findsOneWidget);
    expect(find.text('USD tender'), findsOneWidget);
    expect(find.text('61 cash sales'), findsOneWidget);
    expect(find.text(r'$310.00'), findsOneWidget);
    expect(find.text('KHR tender'), findsOneWidget);
    expect(find.text('11 cash sales'), findsOneWidget);
    expect(find.text('KHR 1,270,000'), findsOneWidget);
  });

  testWidgets('renders an empty state when no cash tender data is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SalesCashTenderBreakdownPanel(items: [])),
      ),
    );

    expect(find.text('Cash tender'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);
  });
}
