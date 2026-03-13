import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/session_sales_section.dart';

List<CashSessionSale> _buildSales(int count) {
  return List.generate(
    count,
    (index) => CashSessionSale(
      saleId: 'sale-$index',
      status: CashSessionSaleStatuses.finalized,
      paymentMethod: 'CASH',
      saleType: 'TAKEAWAY',
      finalizedAt: DateTime.utc(2026, 3, 10, 9, index),
      totalItems: 2,
      grandTotalUsd: 7.5,
      grandTotalKhr: 30750,
      cashierAccountId: 'cashier-1',
      cashierName: 'John Smith',
      voidedAt: null,
    ),
  );
}

void main() {
  testWidgets('wide session sales shows entry badge and pager', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SessionSalesSection(
            sessionStatus: SessionStatus.open,
            sales: _buildSales(10),
            hasMoreSales: true,
            isLoadingMoreSales: false,
            onLoadMore: () async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('10 loaded'), findsOneWidget);
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('mobile session sales shows load more action', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var loadMoreCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SessionSalesSection(
              sessionStatus: SessionStatus.open,
              sales: _buildSales(5),
              hasMoreSales: true,
              isLoadingMoreSales: false,
              onLoadMore: () async {
                loadMoreCalls += 1;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('5 loaded'), findsOneWidget);
    expect(find.text('Load more sales'), findsOneWidget);

    await tester.ensureVisible(find.text('Load more sales'));
    await tester.tap(find.text('Load more sales'));
    await tester.pumpAndSettle();

    expect(loadMoreCalls, 1);
  });
}
