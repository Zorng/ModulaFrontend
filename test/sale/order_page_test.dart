import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';
import 'package:modular_pos/features/sale/ui/view/order/order_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

class _StaticOrdersNotifier extends OrdersNotifier {
  _StaticOrdersNotifier(this._orders);

  final List<Order> _orders;
  String? updatedIdentityKey;
  String? updatedStatus;
  String? lastRequestedStatus;
  String? lastRequestedView;

  @override
  List<Order> build() => _orders;

  @override
  Future<void> load({DateTime? date, String? status, String? view}) async {
    lastRequestedStatus = status;
    lastRequestedView = view;
  }

  @override
  Future<void> updateStatus(String orderIdentityKey, String status) async {
    updatedIdentityKey = orderIdentityKey;
    updatedStatus = status;
  }
}

void main() {
  testWidgets('OrderPage defaults to the kitchen queue', (tester) async {
    final pendingPaidOrder = Order(
      id: 'order-1',
      saleId: 'sale-1',
      number: 'ORDER-001',
      status: 'pending',
      ticketStatus: 'PAID',
      placedAt: DateTime(2026, 3, 18, 10),
      orderType: 'take_away',
      paymentMethod: 'cash',
      totalUsd: 3.5,
      totalKhr: 14350,
      tenderCurrency: 'usd',
      tenderAmount: 5,
      changeAmount: 1.5,
      lines: const [OrderLine(name: 'Latte', modifiers: [], quantity: 1)],
    );
    final pendingOrder = Order(
      id: 'ticket-1',
      saleId: 'ticket-1',
      number: 'TICKET-001',
      status: 'pending',
      ticketStatus: 'UNPAID',
      placedAt: DateTime(2026, 3, 18, 10),
      orderType: 'dine_in',
      paymentMethod: 'unpaid',
      totalUsd: 4,
      totalKhr: 16400,
      tenderCurrency: 'usd',
      tenderAmount: 0,
      changeAmount: 0,
      lines: const [OrderLine(name: 'Mocha', modifiers: [], quantity: 1)],
      openTicketId: 'ticket-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersProvider.overrideWith(
            () => _StaticOrdersNotifier([pendingPaidOrder, pendingOrder]),
          ),
        ],
        child: const MaterialApp(home: OrderPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Order No. ORDER-001'), findsOneWidget);
    expect(find.text('Order No. TICKET-001'), findsNothing);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('External Claims'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Pending'), findsOneWidget);
    expect(find.text('Pending Payment'), findsNothing);
    expect(find.text('No external payment claims'), findsNothing);
  });

  testWidgets(
    'OrderPage keeps queued offline cash orders in the kitchen queue',
    (tester) async {
      final queuedCashOrder = Order(
        id: 'local-cash-1',
        saleId: '',
        number: 'LOCAL-CASH-001',
        status: 'pending',
        ticketStatus: 'PAID',
        placedAt: DateTime(2026, 3, 18, 10),
        orderType: 'take_away',
        paymentMethod: 'cash',
        totalUsd: 3.5,
        totalKhr: 14350,
        tenderCurrency: 'usd',
        tenderAmount: 3.5,
        changeAmount: 0,
        lines: const [OrderLine(name: 'Latte', modifiers: [], quantity: 1)],
        sourceMode: 'DIRECT_CHECKOUT',
        isLocalOutageOrder: true,
        localOutageIntentId: 'local-cash-1',
        localOutageState: SaleOutageOrderStates.awaitingSettlement,
        localOutageSourceMode: SaleOutageSourceModes.standardOpenOrder,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersProvider.overrideWith(
              () => _StaticOrdersNotifier([queuedCashOrder]),
            ),
          ],
          child: const MaterialApp(home: OrderPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Order No. LOCAL-CASH-001'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('External Claims'), findsOneWidget);
    },
  );

  testWidgets('OrderPage lets paid fulfillment rows update status', (
    tester,
  ) async {
    final pendingPaidOrder = Order(
      id: 'order-1',
      saleId: '',
      number: 'ORDER-001',
      status: 'pending',
      ticketStatus: 'PAID',
      placedAt: DateTime(2026, 3, 18, 10),
      orderType: 'take_away',
      paymentMethod: 'cash',
      totalUsd: 4,
      totalKhr: 16400,
      tenderCurrency: 'usd',
      tenderAmount: 4,
      changeAmount: 0,
      lines: const [OrderLine(name: 'Mocha', modifiers: [], quantity: 1)],
      sourceMode: 'DIRECT_CHECKOUT',
    );
    final notifier = _StaticOrdersNotifier([pendingPaidOrder]);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const OrderPage()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ordersProvider.overrideWith(() => notifier)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Order No. ORDER-001'), findsOneWidget);
    await tester.tap(find.text('Pending').last);
    await tester.pumpAndSettle();

    expect(find.text('Update Fulfillment Status'), findsOneWidget);

    await tester.tap(find.widgetWithText(RadioListTile<String>, 'Ready'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Update Status'));
    await tester.pumpAndSettle();

    expect(notifier.updatedIdentityKey, 'order:order-1');
    expect(notifier.updatedStatus, 'ready');
  });

  testWidgets('OrderPage switches to the external claims queue', (
    tester,
  ) async {
    final kitchenOrder = Order(
      id: 'order-1',
      saleId: 'sale-1',
      number: 'ORDER-001',
      status: 'pending',
      ticketStatus: 'PAID',
      placedAt: DateTime(2026, 3, 18, 10),
      orderType: 'take_away',
      paymentMethod: 'cash',
      totalUsd: 3.5,
      totalKhr: 14350,
      tenderCurrency: 'usd',
      tenderAmount: 5,
      changeAmount: 1.5,
      lines: const [OrderLine(name: 'Latte', modifiers: [], quantity: 1)],
      sourceMode: 'DIRECT_CHECKOUT',
    );
    final claimOrder = Order(
      id: 'local-claim-1',
      saleId: '',
      number: 'CLAIM-001',
      status: 'pending',
      ticketStatus: 'UNPAID',
      placedAt: DateTime(2026, 3, 18, 11),
      orderType: 'take_away',
      paymentMethod: 'qr',
      totalUsd: 4,
      totalKhr: 16400,
      tenderCurrency: 'usd',
      tenderAmount: 0,
      changeAmount: 0,
      lines: const [OrderLine(name: 'Mocha', modifiers: [], quantity: 1)],
      sourceMode: 'MANUAL_EXTERNAL_PAYMENT_CLAIM',
      isLocalOutageOrder: true,
      localOutageIntentId: 'local-claim-1',
      localOutageState:
          SaleOutageOrderStates.manualExternalPaymentClaimRecorded,
      localOutageSourceMode: SaleOutageSourceModes.manualExternalPaymentClaim,
    );
    final notifier = _StaticOrdersNotifier([kitchenOrder, claimOrder]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ordersProvider.overrideWith(() => notifier)],
        child: const MaterialApp(home: OrderPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('External Claims'));
    await tester.pumpAndSettle();

    expect(notifier.lastRequestedStatus, isNull);
    expect(notifier.lastRequestedView, orderManualClaimReviewView);
    expect(find.text('Order No. CLAIM-001'), findsOneWidget);
    expect(find.text('Order No. ORDER-001'), findsNothing);
    expect(find.text('Claim Recorded'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Pending'), findsNothing);
  });
}
