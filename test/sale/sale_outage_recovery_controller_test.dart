import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_outage_store.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_outage_recovery_controller.dart';

import '../test_utils/riverpod_test_utils.dart';

class _MockSaleCheckoutRepository extends Mock
    implements SaleCheckoutRepository {}

class _TestConnectivityStatusNotifier extends AppConnectivityStatusController {
  @override
  AppConnectivityStatus build() => AppConnectivityStatus.online;

  void setStatus(AppConnectivityStatus status) {
    state = status;
  }
}

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
  });

  test(
    'SaleOutageRecoveryController auto-submits recorded manual claims when back online',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftSaleOutageStore(database);
      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-1',
          orderNumber: 'LOCAL-001',
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
          appConnectivityStatusProvider.overrideWith(
            _TestConnectivityStatusNotifier.new,
          ),
        ],
      );

      final result = await container
          .read(saleOutageRecoveryControllerProvider)
          .recoverBranchWorkspace(trigger: SaleOutageRecoveryTrigger.reconnect);

      expect(result.outcome, SaleOutageRecoveryOutcome.success);
      expect(result.recoveredCount, 1);
      expect(result.failedCount, 0);

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
    },
  );

  test(
    'SaleOutageRecoveryController skips recorded cash outage orders for now',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftSaleOutageStore(database);
      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-cash',
          orderNumber: 'LOCAL-CASH',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
          saleType: 'take_away',
          paymentMethodRequested: 'cash',
          tenderCurrency: 'USD',
          cashReceivedUsd: 5,
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
          appConnectivityStatusProvider.overrideWith(
            _TestConnectivityStatusNotifier.new,
          ),
        ],
      );

      final result = await container
          .read(saleOutageRecoveryControllerProvider)
          .recoverBranchWorkspace(trigger: SaleOutageRecoveryTrigger.reconnect);

      expect(result.outcome, SaleOutageRecoveryOutcome.noPending);
      verifyNever(() => repo.placeOrder(any()));
      verifyNever(() => repo.createManualPaymentClaim(any()));
    },
  );

  test('SaleOutageRecoveryController skips recovery while offline', () async {
    final repo = _MockSaleCheckoutRepository();
    final container = createTestContainer(
      overrides: [
        saleRepositoryProvider.overrideWithValue(repo),
        saleOutageScopeProvider.overrideWithValue(
          const SaleOutageScope(
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            accountId: 'user-1',
          ),
        ),
        appConnectivityStatusProvider.overrideWith(
          _TestConnectivityStatusNotifier.new,
        ),
      ],
    );
    final connectivity =
        container.read(appConnectivityStatusProvider.notifier)
            as _TestConnectivityStatusNotifier;
    connectivity.setStatus(AppConnectivityStatus.offline);

    final result = await container
        .read(saleOutageRecoveryControllerProvider)
        .recoverBranchWorkspace(trigger: SaleOutageRecoveryTrigger.reconnect);

    expect(result.outcome, SaleOutageRecoveryOutcome.skippedOffline);
    verifyNever(() => repo.getOrders(any()));
  });
}
