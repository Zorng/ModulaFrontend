import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/view/sale_detail/sale_detail_page.dart';

class _MockSaleRepository extends Mock implements SaleCheckoutRepository {}

void main() {
  testWidgets('SaleDetailPage shows loading while detail is in flight', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    final completer = Completer<SaleDetailReadDto>();
    when(
      () => repo.getSaleDetail(saleId: 'sale-1'),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [saleRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: SaleDetailPage(saleId: 'sale-1')),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SaleDetailPage shows empty-state copy for missing sale id', (
    tester,
  ) async {
    final repo = _MockSaleRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [saleRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: SaleDetailPage(saleId: '   ')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale ID is required.'), findsOneWidget);
    verifyNever(() => repo.getSaleDetail(saleId: any(named: 'saleId')));
  });

  testWidgets('SaleDetailPage shows retry state on load failure', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    when(() => repo.getSaleDetail(saleId: 'sale-1')).thenThrow(
      const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.unknownError,
        message: 'Backend broke.',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [saleRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: SaleDetailPage(saleId: 'sale-1')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to load sale.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
  });

  testWidgets('SaleDetailPage renders sale overview and void request', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    when(() => repo.getSaleDetail(saleId: 'sale-1')).thenAnswer(
      (_) async => _saleDetail(),
    );
    when(
      () => repo.getSaleVoidRequest(saleId: 'sale-1'),
    ).thenAnswer((_) async => _voidRequest());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [saleRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: SaleDetailPage(saleId: 'sale-1')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale Detail'), findsOneWidget);
    expect(find.text('Sale Record'), findsOneWidget);
    expect(find.text('sale-1'), findsWidgets);
    expect(find.text('Void Pending'), findsNWidgets(2));
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Order ID'), findsOneWidget);
    expect(find.text('order-1'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Void Request'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Void Request'), findsOneWidget);
    expect(find.text('Wrong item prepared'), findsOneWidget);
    expect(find.text('1 × Iced Latte'), findsOneWidget);
    expect(find.text('Less ice, Oat milk'), findsOneWidget);
  });
}

SaleDetailReadDto _saleDetail() {
  return SaleDetailReadDto(
    saleId: 'sale-1',
    orderId: 'order-1',
    status: 'VOID_PENDING',
    saleType: 'TAKEAWAY',
    paymentMethod: 'KHQR',
    tenderCurrency: 'USD',
    fulfillmentStatus: 'READY',
    subtotalUsdExact: 8,
    subtotalKhrExact: 32800,
    discountUsdExact: 0,
    discountKhrExact: 0,
    taxUsdExact: 0,
    taxKhrExact: 0,
    totalUsdExact: 8,
    totalKhrExact: 32800,
    cashReceivedUsd: null,
    cashReceivedKhr: null,
    changeGivenUsd: 0,
    changeGivenKhr: null,
    createdAt: DateTime(2026, 3, 25, 10),
    updatedAt: DateTime(2026, 3, 25, 10, 5),
    finalizedAt: DateTime(2026, 3, 25, 10, 3),
    voidedAt: null,
    voidReason: null,
    lines: const [
      SaleDetailLineDto(
        lineId: 'line-1',
        menuItemId: 'item-1',
        menuItemName: 'Iced Latte',
        quantity: 1,
        modifierLabels: ['Less ice', 'Oat milk'],
      ),
    ],
  );
}

SaleVoidRequestReadDto _voidRequest() {
  return SaleVoidRequestReadDto(
    requestId: 'vr-1',
    saleId: 'sale-1',
    status: 'PENDING',
    reason: 'Wrong item prepared',
    requestedAt: DateTime(2026, 3, 25, 10, 6),
    reviewNote: null,
    reviewedAt: null,
    requestedByAccountId: 'staff-1',
    reviewedByAccountId: null,
  );
}
