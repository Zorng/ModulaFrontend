import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/sale/data/mock_sale_repository.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_outage_store.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

import '../test_utils/riverpod_test_utils.dart';

class _MockSaleCheckoutRepository extends Mock
    implements SaleCheckoutRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      SaleOrdersQueryDto(
        from: DateTime.utc(2026, 3, 17),
        to: DateTime.utc(2026, 3, 18),
        limit: 100,
      ),
    );
    registerFallbackValue(
      const SaleFinalizeSaleCommand(
        saleId: '',
        paymentMethod: 'cash',
        tenderCurrency: 'USD',
        clientOpId: 'fallback-op',
      ),
    );
    registerFallbackValue(
      const SaleCheckoutOpenTicketCommand(
        openTicketId: 'order-1',
        paymentMethod: 'cash',
        tenderCurrency: 'USD',
        clientOpId: 'fallback-checkout',
      ),
    );
    registerFallbackValue(
      const SalePlaceOrderCommand(
        saleId: 'fallback-sale',
        branchId: 'branch-1',
        saleType: 'take_away',
        clientOpId: 'fallback-place',
        cartLines: [],
      ),
    );
    registerFallbackValue(
      const SaleCreateManualPaymentClaimCommand(
        orderId: 'order-1',
        claimedPaymentMethod: 'KHQR',
        saleType: 'take_away',
        tenderCurrency: 'USD',
        claimedTenderAmount: 1,
        proofImageUrl: 'https://example.com/proof.jpg',
        clientOpId: 'fallback-claim',
      ),
    );
    registerFallbackValue(
      const SaleApproveManualPaymentClaimCommand(
        orderId: 'order-1',
        claimId: 'claim-1',
        clientOpId: 'fallback-approve',
      ),
    );
    registerFallbackValue(
      const SaleRejectManualPaymentClaimCommand(
        orderId: 'order-1',
        claimId: 'claim-1',
        clientOpId: 'fallback-reject',
      ),
    );
  });

  SaleCartLineInputDto buildLine({
    required String menuItemId,
    int quantity = 1,
    double unitPriceUsd = 2,
  }) {
    return SaleCartLineInputDto(
      menuItemId: menuItemId,
      quantity: quantity,
      modifiers: const [],
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: unitPriceUsd,
    );
  }

  test(
    'OrdersNotifier.load requests the merged fulfillment-active queue by default',
    () async {
      final repo = _MockSaleCheckoutRepository();
      when(() => repo.getOrders(any())).thenAnswer(
        (_) async =>
            const SaleOrdersPageDto(items: [], page: 1, limit: 100, total: 0),
      );

      final container = createTestContainer(
        overrides: [saleRepositoryProvider.overrideWithValue(repo)],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.utc(2026, 3, 17));

      final query =
          verify(() => repo.getOrders(captureAny())).captured.single
              as SaleOrdersQueryDto;
      expect(query.view, OrdersNotifier.fulfillmentActiveView);
    },
  );

  test(
    'OrdersNotifier keeps unpaid open tickets visible and settleable when pay-later is disabled',
    () async {
      final repo = MockSaleRepository();
      final placed = await repo.placeOrder(
        SalePlaceOrderCommand(
          saleId: 'sale-open-ticket-1',
          branchId: 'mock-branch-001',
          saleType: 'dine_in',
          clientOpId: 'place-open-ticket-1',
          cartLines: [buildLine(menuItemId: 'item-1', unitPriceUsd: 3)],
        ),
      );
      repo.configureContext(payLaterEnabled: false);

      final container = createTestContainer(
        overrides: [saleRepositoryProvider.overrideWithValue(repo)],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.now());

      final pendingOrder = container
          .read(ordersProvider)
          .firstWhere((order) => order.openTicketId == placed.openTicketId);
      expect(pendingOrder.status, 'pending');
      expect(pendingOrder.ticketStatus, 'UNPAID');
      expect(pendingOrder.isSettleableOpenTicket, isTrue);

      await notifier.settleOpenTicket(pendingOrder, tenderCurrency: 'USD');

      final settledOrder = container
          .read(ordersProvider)
          .firstWhere((order) => order.saleId == placed.saleId);
      expect(settledOrder.ticketStatus, 'PAID');
      expect(settledOrder.status, 'in_prep');
      expect(settledOrder.isSettleableOpenTicket, isFalse);
    },
  );

  test(
    'OrdersNotifier keeps local outage orders visible when remote load fails',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftSaleOutageStore(database);
      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-1',
          orderNumber: 'LOCAL-ABC',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
          saleType: 'take_away',
          paymentMethodRequested: 'cash',
          tenderCurrency: 'USD',
          cashReceivedUsd: 0,
          cashReceivedKhr: 0,
          totalUsd: 3.5,
          totalKhr: 14350,
          lines: const [
            SaleOutageLineSnapshot(
              menuItemId: 'menu-1',
              name: 'Iced Latte',
              quantity: 1,
              selectedOptionIds: {},
              modifierLabels: [],
              unitPriceUsd: 3.5,
              lineTotalUsdExact: 3.5,
            ),
          ],
          state: SaleOutageOrderStates.localOpenOrderCaptured,
          sourceMode: SaleOutageSourceModes.standardOpenOrder,
          createdAt: DateTime.utc(2026, 3, 17, 9),
          updatedAt: DateTime.utc(2026, 3, 17, 9),
        ),
      );

      final repo = _MockSaleCheckoutRepository();
      when(() => repo.getOrders(any())).thenThrow(Exception('offline'));

      final container = createTestContainer(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          saleOutageStoreProvider.overrideWithValue(store),
          saleOutageScopeProvider.overrideWithValue(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          ),
        ],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.utc(2026, 3, 17));

      final orders = container.read(ordersProvider);
      expect(orders, hasLength(1));
      expect(orders.first.number, 'LOCAL-ABC');
      expect(orders.first.isLocalOutageOrder, isTrue);
      expect(orders.first.isAwaitingOutageSettlement, isTrue);
    },
  );

  test(
    'OrdersNotifier maps queued offline cash replay orders into paid kitchen rows',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftSaleOutageStore(database);
      final queueStore = DriftOfflineCommandQueueStore(database);
      final createdAt = DateTime.utc(2026, 3, 17, 9);
      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-cash-1',
          orderNumber: 'LOCAL-CASH-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
          saleType: 'take_away',
          paymentMethodRequested: 'cash',
          tenderCurrency: 'USD',
          cashReceivedUsd: 3.5,
          cashReceivedKhr: 0,
          totalUsd: 3.5,
          totalKhr: 14350,
          lines: const [
            SaleOutageLineSnapshot(
              menuItemId: 'menu-1',
              name: 'Iced Latte',
              quantity: 1,
              selectedOptionIds: {},
              modifierLabels: [],
              unitPriceUsd: 3.5,
              lineTotalUsdExact: 3.5,
            ),
          ],
          state: SaleOutageOrderStates.awaitingSettlement,
          sourceMode: SaleOutageSourceModes.standardOpenOrder,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      await queueStore.write(
        OfflineCommandRecord(
          clientOpId: '11111111-1111-4111-8111-111111111111',
          operationType: OfflineOperationType.checkoutCashFinalize,
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
          occurredAt: createdAt,
          payloadJson:
              '{"localIntentId":"local-cash-1","orderId":"client-order-1","saleId":"client-sale-1"}',
          status: OfflineCommandQueueStatus.pending,
          retryCount: 0,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

      final repo = _MockSaleCheckoutRepository();
      when(() => repo.getOrders(any())).thenThrow(Exception('offline'));

      final container = createTestContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          saleRepositoryProvider.overrideWithValue(repo),
          saleOutageStoreProvider.overrideWithValue(store),
          saleOutageScopeProvider.overrideWithValue(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          ),
        ],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.utc(2026, 3, 17));

      final order = container.read(ordersProvider).single;
      expect(order.isQueueBackedOfflineCashOrder, isTrue);
      expect(order.ticketStatus, 'PAID');
      expect(order.status, 'pending');
      expect(order.sourceMode, 'DIRECT_CHECKOUT');
      expect(order.isSettleableOpenTicket, isFalse);
    },
  );

  test(
    'OrdersNotifier clears queued offline cash outage rows after replay success',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftSaleOutageStore(database);
      final queueStore = DriftOfflineCommandQueueStore(database);
      final createdAt = DateTime.utc(2026, 3, 17, 9);
      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-cash-2',
          orderNumber: 'LOCAL-CASH-2',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
          saleType: 'take_away',
          paymentMethodRequested: 'cash',
          tenderCurrency: 'USD',
          cashReceivedUsd: 3.5,
          cashReceivedKhr: 0,
          totalUsd: 3.5,
          totalKhr: 14350,
          lines: const [
            SaleOutageLineSnapshot(
              menuItemId: 'menu-1',
              name: 'Iced Latte',
              quantity: 1,
              selectedOptionIds: {},
              modifierLabels: [],
              unitPriceUsd: 3.5,
              lineTotalUsdExact: 3.5,
            ),
          ],
          state: SaleOutageOrderStates.awaitingSettlement,
          sourceMode: SaleOutageSourceModes.standardOpenOrder,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      await queueStore.write(
        OfflineCommandRecord(
          clientOpId: '22222222-2222-4222-8222-222222222222',
          operationType: OfflineOperationType.checkoutCashFinalize,
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
          occurredAt: createdAt,
          payloadJson:
              '{"localIntentId":"local-cash-2","orderId":"client-order-2","saleId":"client-sale-2"}',
          status: OfflineCommandQueueStatus.applied,
          retryCount: 1,
          createdAt: createdAt,
          updatedAt: createdAt,
          lastSyncedAt: createdAt.add(const Duration(minutes: 5)),
        ),
      );

      final repo = _MockSaleCheckoutRepository();
      when(() => repo.getOrders(any())).thenThrow(Exception('offline'));

      final container = createTestContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          saleRepositoryProvider.overrideWithValue(repo),
          saleOutageStoreProvider.overrideWithValue(store),
          saleOutageScopeProvider.overrideWithValue(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          ),
        ],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.utc(2026, 3, 17));

      expect(container.read(ordersProvider), isEmpty);
      final remaining = await store.list(
        const SaleOutageScope(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
        ),
      );
      expect(remaining, isEmpty);
    },
  );

  test(
    'OrdersNotifier keeps the local outage projection when a remote order shares the same backend order id',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftSaleOutageStore(database);
      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-merge',
          orderNumber: 'LOCAL-MERGE',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
          saleType: 'take_away',
          paymentMethodRequested: 'qr',
          tenderCurrency: 'USD',
          cashReceivedUsd: 0,
          cashReceivedKhr: 0,
          totalUsd: 3.5,
          totalKhr: 14350,
          lines: const [
            SaleOutageLineSnapshot(
              menuItemId: 'menu-1',
              name: 'Iced Latte',
              quantity: 1,
              selectedOptionIds: {},
              modifierLabels: [],
              unitPriceUsd: 3.5,
              lineTotalUsdExact: 3.5,
            ),
          ],
          state: SaleOutageOrderStates.manualExternalPaymentClaimRecorded,
          sourceMode: SaleOutageSourceModes.manualExternalPaymentClaim,
          claimedPaymentMethod: 'KHQR',
          claimedTenderAmount: 3.5,
          proofImageUrl: 'https://example.com/proof.jpg',
          backendOrderId: 'order-1',
          claimRecordedAt: DateTime.utc(2026, 3, 17, 9, 5),
          createdAt: DateTime.utc(2026, 3, 17, 9),
          updatedAt: DateTime.utc(2026, 3, 17, 9, 5),
        ),
      );

      final repo = _MockSaleCheckoutRepository();
      when(() => repo.getOrders(any())).thenAnswer(
        (_) async => SaleOrdersPageDto(
          items: [
            SaleOrderSummaryDto(
              saleId: '',
              orderId: 'order-1',
              sourceMode: 'MANUAL_EXTERNAL_PAYMENT_CLAIM',
              ticketStatus: 'UNPAID',
              fulfillmentStatus: 'pending',
              totalUsdExact: 3.5,
              totalKhrExact: 14350,
              placedAt: DateTime.utc(2026, 3, 17, 9),
            ),
          ],
          page: 1,
          limit: 100,
          total: 1,
        ),
      );

      final container = createTestContainer(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          saleOutageStoreProvider.overrideWithValue(store),
          saleOutageScopeProvider.overrideWithValue(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          ),
        ],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.utc(2026, 3, 17));

      final orders = container.read(ordersProvider);
      expect(orders, hasLength(1));
      expect(orders.single.isLocalOutageOrder, isTrue);
      expect(orders.single.localOutageMaterializedOrderId, 'order-1');
      expect(orders.single.hasManualExternalPaymentClaimRecorded, isTrue);
    },
  );

  test(
    'OrdersNotifier updateStatus uses orderId for fulfillment updates',
    () async {
      final repo = _MockSaleCheckoutRepository();
      when(() => repo.getOrders(any())).thenAnswer(
        (_) async => SaleOrdersPageDto(
          items: [
            SaleOrderSummaryDto(
              saleId: '',
              orderId: 'order-1',
              sourceMode: 'DIRECT_CHECKOUT',
              ticketStatus: 'PAID',
              fulfillmentStatus: 'in_prep',
              totalUsdExact: 5,
              totalKhrExact: 20500,
              placedAt: DateTime.utc(2026, 3, 17, 9),
            ),
          ],
          page: 1,
          limit: 100,
          total: 1,
        ),
      );
      when(
        () => repo.updateFulfillmentStatus(
          orderId: any(named: 'orderId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async {});

      final container = createTestContainer(
        overrides: [saleRepositoryProvider.overrideWithValue(repo)],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.utc(2026, 3, 17));
      await notifier.updateStatus('order:order-1', 'ready');

      verify(
        () => repo.updateFulfillmentStatus(orderId: 'order-1', status: 'ready'),
      ).called(1);
      expect(container.read(ordersProvider).single.status, 'ready');
    },
  );

  test(
    'OrdersNotifier records manual claim details on a local outage order',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftSaleOutageStore(database);
      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-1',
          orderNumber: 'LOCAL-ABC',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
          saleType: 'take_away',
          paymentMethodRequested: 'qr',
          tenderCurrency: 'USD',
          cashReceivedUsd: 0,
          cashReceivedKhr: 0,
          totalUsd: 3.5,
          totalKhr: 14350,
          lines: const [
            SaleOutageLineSnapshot(
              menuItemId: 'menu-1',
              name: 'Iced Latte',
              quantity: 1,
              selectedOptionIds: {},
              modifierLabels: [],
              unitPriceUsd: 3.5,
              lineTotalUsdExact: 3.5,
            ),
          ],
          state: SaleOutageOrderStates.localOpenOrderCaptured,
          sourceMode: SaleOutageSourceModes.manualExternalPaymentClaim,
          createdAt: DateTime.utc(2026, 3, 17, 9),
          updatedAt: DateTime.utc(2026, 3, 17, 9),
        ),
      );

      final repo = _MockSaleCheckoutRepository();
      when(() => repo.getOrders(any())).thenThrow(Exception('offline'));

      final container = createTestContainer(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          saleOutageStoreProvider.overrideWithValue(store),
          saleOutageScopeProvider.overrideWithValue(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          ),
        ],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.utc(2026, 3, 17));

      final order = container.read(ordersProvider).single;
      await notifier.recordLocalManualExternalPaymentClaim(
        order,
        claimedTenderAmount: 3.5,
        proofImageUrl: 'https://example.com/proof.jpg',
        customerReference: 'ABA-REF-001',
        note: 'Customer showed screenshot',
      );

      final updated = container.read(ordersProvider).single;
      expect(updated.hasManualExternalPaymentClaimRecorded, isTrue);
      expect(updated.localOutageClaimedPaymentMethod, 'KHQR');
      expect(updated.localOutageProofImageUrl, 'https://example.com/proof.jpg');
      expect(updated.localOutageCustomerReference, 'ABA-REF-001');
      expect(updated.isSettleableOpenTicket, isFalse);
    },
  );

  test(
    'OrdersNotifier materializes and settles a local outage cash order online and clears it from local outage storage',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftSaleOutageStore(database);
      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-1',
          orderNumber: 'LOCAL-ABC',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
          saleType: 'take_away',
          paymentMethodRequested: 'cash',
          tenderCurrency: 'USD',
          cashReceivedUsd: 0,
          cashReceivedKhr: 0,
          totalUsd: 3.5,
          totalKhr: 14350,
          lines: const [
            SaleOutageLineSnapshot(
              menuItemId: 'menu-1',
              name: 'Iced Latte',
              quantity: 1,
              selectedOptionIds: {},
              modifierLabels: [],
              unitPriceUsd: 3.5,
              lineTotalUsdExact: 3.5,
            ),
          ],
          state: SaleOutageOrderStates.localOpenOrderCaptured,
          sourceMode: SaleOutageSourceModes.standardOpenOrder,
          createdAt: DateTime.utc(2026, 3, 17, 9),
          updatedAt: DateTime.utc(2026, 3, 17, 9),
        ),
      );

      final repo = _MockSaleCheckoutRepository();
      when(() => repo.getOrders(any())).thenAnswer(
        (_) async =>
            SaleOrdersPageDto(items: const [], page: 1, limit: 100, total: 0),
      );
      when(() => repo.placeOrder(any())).thenAnswer(
        (_) async => const SalePlaceOrderResultDto(
          openTicketId: 'order-1',
          saleId: 'sale-1',
          status: 'UNPAID',
          batchId: 'batch-1',
          idempotentReplay: false,
        ),
      );
      when(() => repo.checkoutOpenTicket(any())).thenAnswer(
        (_) async => const SaleCheckoutOpenTicketResultDto(
          openTicketId: 'order-1',
          saleId: 'sale-1',
          status: 'PAID',
          idempotentReplay: false,
        ),
      );

      final container = createTestContainer(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          saleOutageStoreProvider.overrideWithValue(store),
          saleOutageScopeProvider.overrideWithValue(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          ),
        ],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.utc(2026, 3, 17));

      final order = container.read(ordersProvider).single;
      await notifier.finalizeLocalOutageCashOrder(order, cashReceivedAmount: 5);

      final remaining = await store.list(
        const SaleOutageScope(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
        ),
      );
      expect(remaining, isEmpty);

      final placed =
          verify(() => repo.placeOrder(captureAny())).captured.single
              as SalePlaceOrderCommand;
      expect(placed.branchId, 'branch-1');
      expect(placed.saleType, 'take_away');
      expect(placed.cartLines, hasLength(1));
      expect(placed.cartLines.single.menuItemId, 'menu-1');

      final checkout =
          verify(() => repo.checkoutOpenTicket(captureAny())).captured.single
              as SaleCheckoutOpenTicketCommand;
      expect(checkout.openTicketId, 'order-1');
      expect(checkout.paymentMethod, 'cash');
      expect(checkout.tenderCurrency, 'USD');
      expect(checkout.cashReceived?.usd, 5);
    },
  );

  test(
    'OrdersNotifier materializes and submits a manual outage claim online',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftSaleOutageStore(database);
      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-1',
          orderNumber: 'LOCAL-ABC',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
          saleType: 'take_away',
          paymentMethodRequested: 'qr',
          tenderCurrency: 'USD',
          cashReceivedUsd: 0,
          cashReceivedKhr: 0,
          totalUsd: 3.5,
          totalKhr: 14350,
          lines: const [
            SaleOutageLineSnapshot(
              menuItemId: 'menu-1',
              name: 'Iced Latte',
              quantity: 1,
              selectedOptionIds: {},
              modifierLabels: [],
              unitPriceUsd: 3.5,
              lineTotalUsdExact: 3.5,
            ),
          ],
          state: SaleOutageOrderStates.manualExternalPaymentClaimRecorded,
          sourceMode: SaleOutageSourceModes.manualExternalPaymentClaim,
          claimedPaymentMethod: 'KHQR',
          claimedTenderAmount: 3.5,
          proofImageUrl: 'https://example.com/proof.jpg',
          customerReference: 'ABA-REF-001',
          note: 'Customer showed screenshot',
          claimRecordedAt: DateTime.utc(2026, 3, 17, 9, 5),
          createdAt: DateTime.utc(2026, 3, 17, 9),
          updatedAt: DateTime.utc(2026, 3, 17, 9, 5),
        ),
      );

      final repo = _MockSaleCheckoutRepository();
      when(() => repo.getOrders(any())).thenAnswer(
        (_) async =>
            SaleOrdersPageDto(items: const [], page: 1, limit: 100, total: 0),
      );
      when(() => repo.placeOrder(any())).thenAnswer(
        (_) async => const SalePlaceOrderResultDto(
          openTicketId: 'order-1',
          saleId: 'sale-1',
          status: 'UNPAID',
          batchId: 'batch-1',
          idempotentReplay: false,
        ),
      );
      when(() => repo.createManualPaymentClaim(any())).thenAnswer(
        (_) async => const SaleCreateManualPaymentClaimResultDto(
          claimId: 'claim-1',
          orderId: 'order-1',
          status: 'PENDING_REVIEW',
          idempotentReplay: false,
        ),
      );

      final container = createTestContainer(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          saleOutageStoreProvider.overrideWithValue(store),
          saleOutageScopeProvider.overrideWithValue(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          ),
        ],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.utc(2026, 3, 17));

      final order = container.read(ordersProvider).single;
      await notifier.submitManualExternalPaymentClaim(order);

      final updated = container.read(ordersProvider).single;
      expect(updated.localOutageMaterializedOrderId, 'order-1');
      expect(updated.localOutageBackendClaimId, 'claim-1');
      expect(updated.hasSubmittedManualExternalPaymentClaim, isTrue);

      final persisted = await store.readByLocalIntentId(
        scope: const SaleOutageScope(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
        ),
        localIntentId: 'local-1',
      );
      expect(persisted?.backendOrderId, 'order-1');
      expect(persisted?.backendClaimId, 'claim-1');
      expect(persisted?.claimSubmittedAt, isNotNull);

      final placedCommand =
          verify(() => repo.placeOrder(captureAny())).captured.single
              as SalePlaceOrderCommand;
      expect(
        placedCommand.sourceMode,
        SaleOutageSourceModes.manualExternalPaymentClaim,
      );

      final claimCommand =
          verify(
                () => repo.createManualPaymentClaim(captureAny()),
              ).captured.single
              as SaleCreateManualPaymentClaimCommand;
      expect(claimCommand.orderId, 'order-1');
      expect(claimCommand.proofImageUrl, 'https://example.com/proof.jpg');
      expect(claimCommand.customerReference, 'ABA-REF-001');
    },
  );

  test(
    'OrdersNotifier approves a submitted manual outage claim and clears local outage storage',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftSaleOutageStore(database);
      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-approve',
          orderNumber: 'LOCAL-APR',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
          saleType: 'take_away',
          paymentMethodRequested: 'qr',
          tenderCurrency: 'USD',
          cashReceivedUsd: 0,
          cashReceivedKhr: 0,
          totalUsd: 3.5,
          totalKhr: 14350,
          lines: const [
            SaleOutageLineSnapshot(
              menuItemId: 'menu-1',
              name: 'Iced Latte',
              quantity: 1,
              selectedOptionIds: {},
              modifierLabels: [],
              unitPriceUsd: 3.5,
              lineTotalUsdExact: 3.5,
            ),
          ],
          state: SaleOutageOrderStates.manualExternalPaymentClaimRecorded,
          sourceMode: SaleOutageSourceModes.manualExternalPaymentClaim,
          claimedPaymentMethod: 'KHQR',
          claimedTenderAmount: 3.5,
          proofImageUrl: 'https://example.com/proof.jpg',
          backendOrderId: 'order-1',
          backendClaimId: 'claim-1',
          claimSubmittedAt: DateTime.utc(2026, 3, 17, 9, 10),
          createdAt: DateTime.utc(2026, 3, 17, 9),
          updatedAt: DateTime.utc(2026, 3, 17, 9, 10),
        ),
      );

      final repo = _MockSaleCheckoutRepository();
      when(() => repo.getOrders(any())).thenAnswer(
        (_) async =>
            SaleOrdersPageDto(items: const [], page: 1, limit: 100, total: 0),
      );
      when(() => repo.approveManualPaymentClaim(any())).thenAnswer(
        (_) async => SaleApproveManualPaymentClaimResultDto(
          claimId: 'claim-1',
          orderId: 'order-1',
          status: 'APPROVED',
          idempotentReplay: false,
          saleId: 'sale-1',
          receiptId: 'receipt-1',
          receipt: SaleImmediateReceiptDto(
            receiptId: 'receipt-1',
            saleId: 'sale-1',
            statusDisplay: 'NORMAL',
            issuedAt: DateTime.utc(2026, 3, 17, 9, 15),
          ),
        ),
      );

      final container = createTestContainer(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          saleOutageStoreProvider.overrideWithValue(store),
          saleOutageScopeProvider.overrideWithValue(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          ),
        ],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.utc(2026, 3, 17));
      final order = container.read(ordersProvider).single;

      final result = await notifier.approveSubmittedManualPaymentClaim(
        order,
        note: 'Verified',
      );

      expect(result.saleId, 'sale-1');
      expect(result.receiptId, 'receipt-1');
      expect(container.read(ordersProvider), isEmpty);
      final persisted = await store.readByLocalIntentId(
        scope: const SaleOutageScope(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
        ),
        localIntentId: 'local-approve',
      );
      expect(persisted, isNull);

      final approveCommand =
          verify(
                () => repo.approveManualPaymentClaim(captureAny()),
              ).captured.single
              as SaleApproveManualPaymentClaimCommand;
      expect(approveCommand.orderId, 'order-1');
      expect(approveCommand.claimId, 'claim-1');
      expect(approveCommand.note, 'Verified');
    },
  );

  test(
    'OrdersNotifier rejects a submitted manual outage claim and reopens local claim submission',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftSaleOutageStore(database);
      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-reject',
          orderNumber: 'LOCAL-REJ',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
          saleType: 'take_away',
          paymentMethodRequested: 'qr',
          tenderCurrency: 'USD',
          cashReceivedUsd: 0,
          cashReceivedKhr: 0,
          totalUsd: 3.5,
          totalKhr: 14350,
          lines: const [
            SaleOutageLineSnapshot(
              menuItemId: 'menu-1',
              name: 'Iced Latte',
              quantity: 1,
              selectedOptionIds: {},
              modifierLabels: [],
              unitPriceUsd: 3.5,
              lineTotalUsdExact: 3.5,
            ),
          ],
          state: SaleOutageOrderStates.manualExternalPaymentClaimRecorded,
          sourceMode: SaleOutageSourceModes.manualExternalPaymentClaim,
          claimedPaymentMethod: 'KHQR',
          claimedTenderAmount: 3.5,
          proofImageUrl: 'https://example.com/proof.jpg',
          backendOrderId: 'order-1',
          backendClaimId: 'claim-1',
          claimSubmittedAt: DateTime.utc(2026, 3, 17, 9, 10),
          createdAt: DateTime.utc(2026, 3, 17, 9),
          updatedAt: DateTime.utc(2026, 3, 17, 9, 10),
        ),
      );

      final repo = _MockSaleCheckoutRepository();
      when(() => repo.getOrders(any())).thenAnswer(
        (_) async =>
            SaleOrdersPageDto(items: const [], page: 1, limit: 100, total: 0),
      );
      when(() => repo.rejectManualPaymentClaim(any())).thenAnswer(
        (_) async => const SaleRejectManualPaymentClaimResultDto(
          claimId: 'claim-1',
          orderId: 'order-1',
          status: 'REJECTED',
          idempotentReplay: false,
        ),
      );

      final container = createTestContainer(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          saleOutageStoreProvider.overrideWithValue(store),
          saleOutageScopeProvider.overrideWithValue(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          ),
        ],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.utc(2026, 3, 17));
      final order = container.read(ordersProvider).single;

      final result = await notifier.rejectSubmittedManualPaymentClaim(
        order,
        note: 'Proof mismatch',
      );

      expect(result.status, 'REJECTED');
      final updated = container.read(ordersProvider).single;
      expect(updated.hasSubmittedManualExternalPaymentClaim, isFalse);
      expect(updated.hasManualExternalPaymentClaimRecorded, isTrue);
      expect(updated.hasRejectedManualExternalPaymentClaim, isTrue);
      expect(updated.localOutageLastErrorMessage, 'Proof mismatch');

      final persisted = await store.readByLocalIntentId(
        scope: const SaleOutageScope(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
        ),
        localIntentId: 'local-reject',
      );
      expect(persisted?.backendClaimId, isNull);
      expect(persisted?.claimSubmittedAt, isNull);
      expect(
        persisted?.lastErrorCode,
        SaleOutageErrorCodes.manualExternalPaymentClaimRejected,
      );
    },
  );
}
