import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/mock_sale_repository.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_outage_store.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/riverpod_test_utils.dart';

class _StaticPolicyNotifier extends PolicyNotifier {
  @override
  PolicyState build() {
    return const PolicyState(
      isLoading: false,
      branchPolicy: BranchPolicy(
        saleFxRateKhrPerUsd: 4100,
        saleAllowPayLater: true,
        saleAllowManualExternalPaymentClaim: true,
      ),
    );
  }
}

class _ManualClaimDisabledPolicyNotifier extends PolicyNotifier {
  @override
  PolicyState build() {
    return const PolicyState(
      isLoading: false,
      branchPolicy: BranchPolicy(
        saleFxRateKhrPerUsd: 4100,
        saleAllowPayLater: true,
        saleAllowManualExternalPaymentClaim: false,
      ),
    );
  }
}

class _StaticMenuViewModel extends MenuViewModel {
  @override
  MenuState build() => const MenuState(isLoading: false);

  @override
  Future<void> loadMenu({
    String? branchId,
    MenuReadLane readLane = MenuReadLane.management,
  }) async {}
}

class _OfflineConnectivityNotifier extends AppConnectivityStatusController {
  @override
  AppConnectivityStatus build() => AppConnectivityStatus.offline;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'captureOfflineCashOrder stores a durable outage order, enqueues cash replay, and clears cart',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      const item = MenuItem(
        id: 'menu-1',
        name: 'Latte',
        categoryId: 'cat-1',
        price: 2.5,
      );

      final container = createTestContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          saleOutageStoreProvider.overrideWith((ref) {
            return DriftSaleOutageStore(database);
          }),
          saleOutageScopeProvider.overrideWithValue(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          ),
          appConnectivityStatusProvider.overrideWith(
            _OfflineConnectivityNotifier.new,
          ),
          saleRepositoryProvider.overrideWithValue(MockSaleRepository()),
          policyNotifierProvider.overrideWith(
            _ManualClaimDisabledPolicyNotifier.new,
          ),
          menuViewModelProvider.overrideWith(_StaticMenuViewModel.new),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              contextLoading: false,
              branchActive: true,
              branchFrozen: false,
              cashSessionOpen: true,
              canMutateCart: true,
              canCheckout: true,
              canPlacePayLater: true,
            ),
          ),
        ],
      );

      final notifier = container.read(saleCartProvider.notifier);
      notifier.setLines(const [
        CartLine(item: item, quantity: 1, selectedOptionIds: {}),
      ]);

      final result = await notifier.captureOfflineCashOrder();
      final records = await container
          .read(saleOutageStoreProvider)
          .list(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          );
      final queuedRecords = await container
          .read(offlineCommandQueueStoreProvider)
          .listReplayReadyForContext(
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            accountId: 'user-1',
          );
      final queued = queuedRecords.single;

      expect(result.localIntentId, isNotEmpty);
      expect(result.orderNumber, startsWith('LOCAL-'));
      expect(container.read(saleCartProvider).lines, isEmpty);
      expect(records, hasLength(1));
      expect(records.first.orderNumber, result.orderNumber);
      expect(records.first.totalUsd, 2.5);
      expect(records.first.paymentMethodRequested, 'cash');
      expect(records.first.state, SaleOutageOrderStates.awaitingSettlement);
      expect(queued.operationType, OfflineOperationType.checkoutCashFinalize);
      final payload = queued.decodePayload();
      expect(payload['localIntentId'], result.localIntentId);
      expect(queued.clientOpId, isNot(result.localIntentId));
      expect(payload['orderId'], isNotEmpty);
      expect(payload['saleId'], isNotEmpty);
      expect(payload['cashReceivedTenderAmount'], 2.5);
      expect(payload['tenderCurrency'], 'USD');
      expect(payload['items'], isA<List<dynamic>>());
      final items = payload['items'] as List<dynamic>;
      expect(items, hasLength(1));
      expect(items.single, containsPair('menuItemNameSnapshot', 'Latte'));
      expect(items.single, containsPair('unitPrice', 2.5));
      expect(items.single, containsPair('lineSubtotal', 2.5));
      expect(items.single, containsPair('modifierSnapshot', <dynamic>[]));
    },
  );

  test(
    'captureOfflineManualClaimOrder stores a manual-claim outage order and clears cart when live checkout is blocked',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      const item = MenuItem(
        id: 'menu-1',
        name: 'Latte',
        categoryId: 'cat-1',
        price: 2.5,
      );

      final container = createTestContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          saleOutageStoreProvider.overrideWith((ref) {
            return DriftSaleOutageStore(database);
          }),
          saleOutageScopeProvider.overrideWithValue(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          ),
          appConnectivityStatusProvider.overrideWith(
            _OfflineConnectivityNotifier.new,
          ),
          saleRepositoryProvider.overrideWithValue(MockSaleRepository()),
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          menuViewModelProvider.overrideWith(_StaticMenuViewModel.new),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              contextLoading: false,
              branchActive: true,
              branchFrozen: false,
              cashSessionOpen: false,
              canMutateCart: false,
              canCheckout: false,
              canPlacePayLater: false,
              reasonCode: SaleCheckoutReasonCodes.cashSessionRequired,
            ),
          ),
        ],
      );

      final notifier = container.read(saleCartProvider.notifier);
      notifier.setLines(const [
        CartLine(item: item, quantity: 1, selectedOptionIds: {}),
      ]);
      await notifier.setPaymentMethod('qr');

      final result = await notifier.captureOfflineManualClaimOrder();
      final records = await container
          .read(saleOutageStoreProvider)
          .list(
            const SaleOutageScope(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
              accountId: 'user-1',
            ),
          );
      final queuedRecords = await container
          .read(offlineCommandQueueStoreProvider)
          .listReplayReadyForContext(
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            accountId: 'user-1',
          );

      expect(result.localIntentId, isNotEmpty);
      expect(result.orderNumber, startsWith('LOCAL-'));
      expect(container.read(saleCartProvider).lines, isEmpty);
      expect(records, hasLength(1));
      expect(records.first.orderNumber, result.orderNumber);
      expect(
        records.first.sourceMode,
        SaleOutageSourceModes.manualExternalPaymentClaim,
      );
      expect(records.first.paymentMethodRequested, 'qr');
      expect(records.first.state, SaleOutageOrderStates.localOpenOrderCaptured);
      expect(records.first.proofImageUrl, isNull);
      expect(records.first.claimRecordedAt, isNull);
      expect(queuedRecords, hasLength(1));
      expect(
        queuedRecords.single.operationType,
        OfflineOperationType.orderManualExternalPaymentClaimCapture,
      );
      final payload = queuedRecords.single.decodePayload();
      expect(payload['localIntentId'], result.localIntentId);
      expect(payload['orderId'], isNotEmpty);
      expect(payload['items'], isA<List<dynamic>>());
    },
  );
}
