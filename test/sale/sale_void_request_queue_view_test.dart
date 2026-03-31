import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/void_request_queue_view.dart';

class _MockSaleRepository extends Mock implements SaleCheckoutRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const SaleVoidRequestQueueQueryDto());
  });

  testWidgets('VoidRequestQueueView renders queue rows and opens sale detail', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    String? openedSaleId;
    when(
      () => repo.getSaleVoidRequests(any()),
    ).thenAnswer((_) async => _queuePage());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [saleRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: VoidRequestQueueView(
              onOpenSaleDetail: (saleId) => openedSaleId = saleId,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Void Requests'), findsOneWidget);
    expect(find.text('Receipt RCP-20260325-0001'), findsOneWidget);
    expect(find.text('Wrong item prepared'), findsOneWidget);
    expect(find.text('Requested by Staff One'), findsOneWidget);
    expect(find.text('Main Branch'), findsOneWidget);
    expect(find.textContaining('\$8.00'), findsOneWidget);

    await tester.tap(find.text('Wrong item prepared'));
    await tester.pumpAndSettle();

    expect(openedSaleId, 'sale-1');
  });

  testWidgets('VoidRequestQueueView reloads when the status filter changes', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    final seenQueries = <SaleVoidRequestQueueQueryDto>[];
    when(() => repo.getSaleVoidRequests(any())).thenAnswer((invocation) async {
      final query =
          invocation.positionalArguments.single as SaleVoidRequestQueueQueryDto;
      seenQueries.add(query);
      if ((query.status ?? '').trim().toUpperCase() == 'APPROVED') {
        return const SaleVoidRequestQueuePageDto(
          items: <SaleVoidRequestQueueItemDto>[],
          limit: 50,
          offset: 0,
          total: 0,
          hasMore: false,
        );
      }
      return _queuePage();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [saleRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Scaffold(body: VoidRequestQueueView())),
      ),
    );

    await tester.pumpAndSettle();

    expect(seenQueries.first.status, 'PENDING');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Approved'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(seenQueries.last.status, 'APPROVED');
    expect(find.text('No approved void requests'), findsOneWidget);
  });

  testWidgets('VoidRequestQueueView shows retry state on load failure', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    var callCount = 0;
    when(() => repo.getSaleVoidRequests(any())).thenAnswer((_) {
      callCount += 1;
      return Future<SaleVoidRequestQueuePageDto>.microtask(
        () => throw const SaleCheckoutRepositoryException(
          reasonCode: SaleCheckoutReasonCodes.unknownError,
          message: 'Queue unavailable.',
        ),
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [saleRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Scaffold(body: VoidRequestQueueView())),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.textContaining('Failed to load void requests.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(callCount, 2);
  });
}

SaleVoidRequestQueuePageDto _queuePage() {
  return SaleVoidRequestQueuePageDto(
    items: [
      SaleVoidRequestQueueItemDto(
        voidRequestId: 'vr-1',
        saleId: 'sale-1',
        orderId: 'order-1',
        receiptNumber: 'RCP-20260325-0001',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        branchName: 'Main Branch',
        saleStatus: 'FINALIZED',
        voidRequestStatus: 'PENDING',
        requestedAt: DateTime(2026, 3, 25, 10),
        requestedByAccountId: 'staff-1',
        requestedByDisplayName: 'Staff One',
        reason: 'Wrong item prepared',
        paymentMethod: 'CASH',
        grandTotalUsd: 8,
        grandTotalKhr: 32800,
        fulfillmentStatus: 'READY',
        saleCreatedAt: DateTime(2026, 3, 25, 9, 55),
      ),
    ],
    limit: 50,
    offset: 0,
    total: 1,
    hasMore: false,
  );
}
