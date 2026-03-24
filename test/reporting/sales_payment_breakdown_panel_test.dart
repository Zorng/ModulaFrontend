import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/widgets/sales_payment_breakdown_panel.dart';

void main() {
  testWidgets('renders payment and cash tender breakdown in one card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SalesPaymentBreakdownPanel(
              items: [
                SalesPaymentBreakdownItem(
                  paymentMethod: SalesPaymentMethod.cash,
                  transactionCount: 72,
                  totalUsd: 341,
                  totalKhr: 1398100,
                ),
                SalesPaymentBreakdownItem(
                  paymentMethod: SalesPaymentMethod.khqr,
                  transactionCount: 52,
                  totalUsd: 341.5,
                  totalKhr: 1403900,
                ),
              ],
              cashTenderItems: [
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
      ),
    );

    expect(find.text('Payment breakdown'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('KHQR'), findsOneWidget);
    expect(find.text(r'$341.00'), findsOneWidget);
    expect(find.text('KHR 1,398,100'), findsOneWidget);
    expect(find.text('Cash tender'), findsOneWidget);
    expect(find.text('USD tender'), findsOneWidget);
    expect(find.text('61 cash sales'), findsOneWidget);
    expect(find.text(r'$310.00'), findsOneWidget);
    expect(find.text('KHR tender'), findsOneWidget);
    expect(find.text('11 cash sales'), findsOneWidget);
    expect(find.text('KHR 1,270,000'), findsOneWidget);
  });

  testWidgets('renders payment panel empty state without tender rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SalesPaymentBreakdownPanel(items: [])),
      ),
    );

    expect(find.text('Payment breakdown'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);
    expect(find.text('Cash tender'), findsNothing);
  });
}
