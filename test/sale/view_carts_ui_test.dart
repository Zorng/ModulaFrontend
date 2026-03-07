import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/sale_summary.dart';
import 'package:modular_pos/features/sale/ui/view/view_cart_detail/view_cart_detail_page.dart';
import 'package:modular_pos/features/sale/ui/view/view_carts/widgets/sale_summary_card.dart';

void main() {
  final pendingSummary = SaleSummary(
    id: 'sale-1',
    state: 'PENDING',
    fulfillmentStatus: 'READY',
    paymentMethod: 'CASH',
    tenderCurrency: 'USD',
    createdAt: DateTime(2026, 3, 7, 10, 30),
    updatedAt: DateTime(2026, 3, 7, 10, 35),
    totalUsdExact: 12.5,
    totalKhrExact: 50000,
    cashReceivedUsd: 20,
    cashReceivedKhr: null,
    changeGivenUsd: 7.5,
    changeGivenKhr: null,
    lines: [
      SaleLine(name: 'Latte', quantity: 2, modifiers: ['Oat Milk']),
    ],
  );

  final voidPendingSummary = SaleSummary(
    id: 'sale-2',
    state: 'VOID_PENDING',
    fulfillmentStatus: 'PENDING',
    paymentMethod: 'KHQR',
    tenderCurrency: 'KHR',
    createdAt: DateTime(2026, 3, 7, 11, 0),
    updatedAt: DateTime(2026, 3, 7, 11, 5),
    totalUsdExact: 3.5,
    totalKhrExact: 14000,
    cashReceivedUsd: null,
    cashReceivedKhr: null,
    changeGivenUsd: null,
    changeGivenKhr: null,
    lines: [SaleLine(name: 'Tea', quantity: 1, modifiers: [])],
  );

  testWidgets(
    'Sale summary card shows live sale metadata and explicit void action',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaleSummaryCard(summary: pendingSummary, onVoid: _noop),
          ),
        ),
      );

      expect(find.text('Cash • USD • Ready'), findsOneWidget);
      expect(find.text('Total: \$12.50 / ៛50000'), findsOneWidget);
      expect(find.text('Sale #sale-1'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Void Sale'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    },
  );

  testWidgets('View cart detail page shows contract-backed sale details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ViewCartDetailPage(summary: pendingSummary, onVoid: _voidTrue),
      ),
    );

    expect(find.text('Sale #sale-1'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Tender currency'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('Total (USD)'), findsOneWidget);
    expect(find.text('\$12.50'), findsOneWidget);
    expect(find.text('Cash received (USD)'), findsOneWidget);
    expect(find.text('Change given (USD)'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Void Sale'), findsOneWidget);
  });

  testWidgets('View cart detail page shows void lifecycle notice', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ViewCartDetailPage(summary: voidPendingSummary)),
    );

    expect(
      find.text('This sale is waiting for the void workflow to complete.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Void Sale'), findsNothing);
  });
}

Future<bool> _voidTrue() async => true;

void _noop() {}
