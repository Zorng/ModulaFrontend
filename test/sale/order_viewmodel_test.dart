import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
    'OrdersNotifier finalizes a local outage cash order online and clears it from local outage storage',
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
      when(() => repo.finalizeSale(any())).thenAnswer(
        (_) async => SaleFinalizeSaleResultDto(
          saleId: 'sale-1',
          status: 'finalized',
          totalUsdExact: 3.5,
          totalKhrExact: 14350,
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

      final captured =
          verify(() => repo.finalizeSale(captureAny())).captured.single
              as SaleFinalizeSaleCommand;
      expect(captured.paymentMethod, 'cash');
      expect(captured.tenderCurrency, 'USD');
      expect(captured.cashReceived?.usd, 5);
      expect(captured.cartLines, hasLength(1));
      expect(captured.cartLines.single.menuItemId, 'menu-1');
    },
  );
}
