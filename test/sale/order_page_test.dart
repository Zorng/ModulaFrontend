import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';
import 'package:modular_pos/features/sale/ui/view/order/order_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

class _MockSaleRepository extends Mock implements SaleCheckoutRepository {}

class _StaticOrdersNotifier extends OrdersNotifier {
  _StaticOrdersNotifier(this._orders);

  final List<Order> _orders;
  String? updatedIdentityKey;
  String? updatedStatus;
  String? lastRequestedStatus;
  String? lastRequestedView;
  int loadCallCount = 0;

  @override
  List<Order> build() => _orders;

  @override
  Future<void> load({DateTime? date, String? status, String? view}) async {
    loadCallCount += 1;
    lastRequestedStatus = status;
    lastRequestedView = view;
  }

  @override
  Future<void> updateStatus(String orderIdentityKey, String status) async {
    updatedIdentityKey = orderIdentityKey;
    updatedStatus = status;
  }
}

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession? _session;

  @override
  LoginState build() => LoginState(session: _session);
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const SaleRequestVoidCommand(
        saleId: 'sale-1',
        reason: 'Reason',
        clientOpId: 'client-op',
      ),
    );
    registerFallbackValue(const SaleVoidRequestQueueQueryDto());
  });

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

    expect(find.text('Kitchen Board'), findsOneWidget);
    expect(find.text('Ticket ORDER-001'), findsOneWidget);
    expect(find.text('Ticket TICKET-001'), findsNothing);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('External Claims'), findsNothing);
    expect(find.text('Void Requests'), findsNothing);
    expect(find.text('Preparing'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
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

      expect(find.text('Ticket LOCAL-CASH-001'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('External Claims'), findsNothing);
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

    expect(find.text('Ticket ORDER-001'), findsOneWidget);
    await tester.tap(find.byTooltip('Order actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update fulfillment status').last);
    await tester.pumpAndSettle();

    expect(find.text('Update Fulfillment Status'), findsOneWidget);

    await tester.tap(find.widgetWithText(RadioListTile<String>, 'Ready'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Update Status'));
    await tester.pumpAndSettle();

    expect(notifier.updatedIdentityKey, 'order:order-1');
    expect(notifier.updatedStatus, 'ready');
  });

  testWidgets('OrderPage lets cashier request void from kitchen rows', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    when(() => repo.requestSaleVoid(any())).thenAnswer(
      (_) async => SaleVoidRequestReadDto(
        requestId: 'void-1',
        saleId: 'sale-1',
        status: 'VOID_PENDING',
        reason: 'Wrong item prepared',
        requestedAt: DateTime.utc(2026, 3, 18, 10, 5),
      ),
    );
    final order = Order(
      id: 'order-1',
      saleId: 'sale-1',
      saleStatus: 'FINALIZED',
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersProvider.overrideWith(() => _StaticOrdersNotifier([order])),
          saleRepositoryProvider.overrideWithValue(repo),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('cashier')),
          ),
        ],
        child: const MaterialApp(home: OrderPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Order actions').first);
    await tester.pumpAndSettle();
    expect(find.text('Open detail'), findsNothing);
    await tester.tap(find.text('Request void').last);
    await tester.pumpAndSettle();

    expect(find.text('Request void'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'Wrong item prepared');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit request'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.requestSaleVoid(captureAny())).captured.single
            as SaleRequestVoidCommand;
    expect(captured.saleId, 'sale-1');
    expect(captured.reason, 'Wrong item prepared');
    expect(find.text('Void request submitted'), findsOneWidget);
  });

  testWidgets('OrderPage lets admin request void from kitchen rows', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    when(() => repo.requestSaleVoid(any())).thenAnswer(
      (_) async => SaleVoidRequestReadDto(
        requestId: 'void-1',
        saleId: 'sale-1',
        status: 'VOID_PENDING',
        reason: 'Operator mistake',
        requestedAt: DateTime.utc(2026, 3, 18, 10, 5),
      ),
    );
    final order = Order(
      id: 'order-1',
      saleId: 'sale-1',
      saleStatus: 'FINALIZED',
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersProvider.overrideWith(() => _StaticOrdersNotifier([order])),
          saleRepositoryProvider.overrideWithValue(repo),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('admin')),
          ),
        ],
        child: const MaterialApp(home: OrderPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Order actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request void').last);
    await tester.pumpAndSettle();

    expect(find.text('Request void'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'Operator mistake');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit request'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.requestSaleVoid(captureAny())).captured.single
            as SaleRequestVoidCommand;
    expect(captured.saleId, 'sale-1');
    expect(captured.reason, 'Operator mistake');
  });

  testWidgets('OrderPage hides request void when sale is not void-eligible', (
    tester,
  ) async {
    final order = Order(
      id: 'order-1',
      saleId: 'sale-1',
      saleStatus: 'SETTLING',
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersProvider.overrideWith(() => _StaticOrdersNotifier([order])),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('cashier')),
          ),
        ],
        child: const MaterialApp(home: OrderPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Order actions').first);
    await tester.pumpAndSettle();

    expect(find.text('Request void'), findsNothing);
    expect(find.text('Open detail'), findsNothing);
    expect(find.text('Update fulfillment status'), findsOneWidget);
  });

  testWidgets('OrderPage shows reviewer-only void requests tab and queue', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    when(
      () => repo.getSaleVoidRequests(any()),
    ).thenAnswer((_) async => _voidQueuePage());
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
    final notifier = _StaticOrdersNotifier([kitchenOrder]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersProvider.overrideWith(() => notifier),
          saleRepositoryProvider.overrideWithValue(repo),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('admin')),
          ),
        ],
        child: const MaterialApp(home: OrderPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Void Requests'), findsOneWidget);
    expect(find.text('External Claims'), findsOneWidget);
    expect(notifier.loadCallCount, 1);

    await tester.tap(find.text('Void Requests'));
    await tester.pumpAndSettle();

    expect(
      find.text('Review pending and historical sale void requests.'),
      findsOneWidget,
    );
    expect(find.text('Requested by Reviewer One'), findsOneWidget);
    expect(notifier.loadCallCount, 1);
    verify(() => repo.getSaleVoidRequests(any())).called(1);
  });

  testWidgets('OrderPage hides void requests tab for cashier', (tester) async {
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersProvider.overrideWith(
            () => _StaticOrdersNotifier([kitchenOrder]),
          ),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('cashier')),
          ),
        ],
        child: const MaterialApp(home: OrderPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('External Claims'), findsOneWidget);
    expect(find.text('Void Requests'), findsNothing);
  });

  testWidgets(
    'OrderPage loads External Claims through manual-claim review view',
    (tester) async {
      final claimOrder = Order(
        id: 'claim-order-1',
        saleId: '',
        number: 'LOCAL-CLAIM-001',
        status: 'pending',
        ticketStatus: 'UNPAID',
        placedAt: DateTime(2026, 3, 18, 10),
        orderType: 'take_away',
        paymentMethod: 'qr',
        totalUsd: 3.5,
        totalKhr: 14350,
        tenderCurrency: 'usd',
        tenderAmount: 3.5,
        changeAmount: 0,
        lines: const [OrderLine(name: 'Latte', modifiers: [], quantity: 1)],
        sourceMode: 'MANUAL_EXTERNAL_PAYMENT_CLAIM',
        remoteManualPaymentClaimId: 'claim-1',
        remoteManualPaymentClaimStatus: 'PENDING',
      );
      final notifier = _StaticOrdersNotifier([claimOrder]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersProvider.overrideWith(() => notifier),
            loginControllerProvider.overrideWith(
              () => _StaticLoginController(_sessionForRole('cashier')),
            ),
          ],
          child: const MaterialApp(home: OrderPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('External Claims'), findsOneWidget);

      await tester.tap(find.text('External Claims'));
      await tester.pumpAndSettle();

      expect(notifier.loadCallCount, 2);
      expect(notifier.lastRequestedView, orderManualClaimReviewView);
      expect(find.text('Ticket LOCAL-CLAIM-001'), findsOneWidget);
      expect(find.text('Claim Pending'), findsOneWidget);
      expect(find.text('Void Requests'), findsNothing);
    },
  );

  testWidgets('OrderPage uses a grid board on wide kitchen layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final orders = [
      for (var i = 0; i < 3; i++)
        Order(
          id: 'order-$i',
          saleId: 'sale-$i',
          number: 'ORDER-00$i',
          status: 'pending',
          ticketStatus: 'PAID',
          placedAt: DateTime(2026, 3, 18, 10, i),
          orderType: 'take_away',
          paymentMethod: 'cash',
          totalUsd: 3.5 + i,
          totalKhr: 14350 + i.toDouble(),
          tenderCurrency: 'usd',
          tenderAmount: 5,
          changeAmount: 1.5,
          lines: const [OrderLine(name: 'Latte', modifiers: [], quantity: 1)],
        ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersProvider.overrideWith(() => _StaticOrdersNotifier(orders)),
        ],
        child: const MaterialApp(home: OrderPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Ticket ORDER-000'), findsOneWidget);
  });

  testWidgets('OrderPage uses placeholder ticket text for long order numbers', (
    tester,
  ) async {
    final order = Order(
      id: 'order-uuid',
      saleId: 'sale-uuid',
      number: '550e8400-e29b-41d4-a716-446655440000',
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersProvider.overrideWith(() => _StaticOrdersNotifier([order])),
        ],
        child: const MaterialApp(home: OrderPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ticket Pending'), findsOneWidget);
    expect(
      find.text('Ticket 550e8400-e29b-41d4-a716-446655440000'),
      findsNothing,
    );
  });
}

AuthSession _sessionForRole(String role) {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Test User',
      role: role,
      tenantId: 'tenant-1',
    ),
    memberships: [
      TenantMembership(
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: role,
        branches: const [],
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'token',
    refreshToken: 'refresh',
    accessTokenExpiresAt: DateTime.utc(2026, 4, 1),
    refreshTokenExpiresAt: DateTime.utc(2026, 5, 1),
  );
}

SaleVoidRequestQueuePageDto _voidQueuePage() {
  return SaleVoidRequestQueuePageDto(
    items: [
      SaleVoidRequestQueueItemDto(
        voidRequestId: 'void-request-1',
        saleId: 'sale-1',
        orderId: 'order-1',
        receiptNumber: 'RCP-20260318-0001',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        branchName: 'Main Branch',
        saleStatus: 'FINALIZED',
        voidRequestStatus: 'PENDING',
        requestedAt: DateTime(2026, 3, 18, 10, 15),
        requestedByAccountId: 'reviewer-1',
        requestedByDisplayName: 'Reviewer One',
        reason: 'Customer received the wrong item',
        paymentMethod: 'CASH',
        grandTotalUsd: 8,
        grandTotalKhr: 32800,
        fulfillmentStatus: 'READY',
        saleCreatedAt: DateTime(2026, 3, 18, 10),
      ),
    ],
    limit: 50,
    offset: 0,
    total: 1,
    hasMore: false,
  );
}
