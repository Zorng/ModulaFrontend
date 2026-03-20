import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/features/sale/data/sale_offline_cash_queue.dart';
import 'package:modular_pos/features/sale/data/sale_outage_store.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';

void main() {
  late AppDatabase database;
  late DriftOfflineCommandQueueStore queueStore;
  late DriftSaleOutageStore outageStore;
  late SaleOfflineCashQueue queue;

  const scope = SaleOutageScope(
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    accountId: 'user-1',
  );

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    queueStore = DriftOfflineCommandQueueStore(database);
    outageStore = DriftSaleOutageStore(database);
    queue = SaleOfflineCashQueue(
      queueStore: queueStore,
      outageStore: outageStore,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'repairQueuedCashReplayPayloads patches canonical line snapshots and requeues validation failures',
    () async {
      final timestamp = DateTime.utc(2026, 3, 19, 9);
      await outageStore.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-1',
          orderNumber: 'LOCAL-1',
          tenantId: scope.tenantId,
          branchId: scope.branchId,
          accountId: scope.accountId,
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
              selectedOptionIds: {
                'group-1': ['option-1'],
              },
              modifierLabels: ['Less ice'],
              unitPriceUsd: 3.5,
              lineTotalUsdExact: 3.5,
            ),
          ],
          state: SaleOutageOrderStates.awaitingSettlement,
          sourceMode: SaleOutageSourceModes.standardOpenOrder,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );

      await queueStore.write(
        OfflineCommandRecord(
          clientOpId: '33333333-3333-4333-8333-333333333333',
          operationType: OfflineOperationType.checkoutCashFinalize,
          tenantId: scope.tenantId,
          branchId: scope.branchId,
          accountId: scope.accountId,
          occurredAt: timestamp,
          payloadJson:
              '{"localIntentId":"local-1","orderId":"order-1","saleId":"sale-1","items":[{"menuItemId":"menu-1","quantity":1}]}',
          status: OfflineCommandQueueStatus.failed,
          retryCount: 1,
          createdAt: timestamp,
          updatedAt: timestamp,
          lastErrorCode: 'SALE_ORDER_VALIDATION_FAILED',
          lastErrorMessage: 'items[0].unitPrice must be a finite number >= 0',
        ),
      );

      final repairedCount = await queue.repairQueuedCashReplayPayloads(
        scope: scope,
      );
      final repaired = await queueStore.read(
        '33333333-3333-4333-8333-333333333333',
      );

      expect(repairedCount, 1);
      expect(repaired, isNotNull);
      expect(repaired!.status, OfflineCommandQueueStatus.pending);
      expect(repaired.lastErrorCode, isNull);
      expect(repaired.lastErrorMessage, isNull);
      final payload = repaired.decodePayload();
      final items = payload['items'] as List<dynamic>;
      expect(items.single, containsPair('menuItemNameSnapshot', 'Iced Latte'));
      expect(items.single, containsPair('unitPrice', 3.5));
      expect(items.single, containsPair('lineSubtotal', 3.5));
      expect(
        items.single,
        containsPair('modifierSnapshot', [
          {'label': 'Less ice', 'priceAdjustmentUsd': 0},
        ]),
      );
      expect(
        items.single,
        containsPair('modifierSelections', [
          {
            'groupId': 'group-1',
            'optionIds': ['option-1'],
          },
        ]),
      );
    },
  );

  test(
    'backfillManualClaimCaptureOperations enqueues branch-visible claim capture replay for local outage claims',
    () async {
      final timestamp = DateTime.utc(2026, 3, 20, 9);
      await outageStore.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-claim-1',
          orderNumber: 'LOCAL-CLAIM-1',
          tenantId: scope.tenantId,
          branchId: scope.branchId,
          accountId: 'staff-1',
          saleType: 'take_away',
          paymentMethodRequested: 'qr',
          tenderCurrency: 'USD',
          cashReceivedUsd: 0,
          cashReceivedKhr: 0,
          totalUsd: 4.25,
          totalKhr: 17425,
          lines: const [
            SaleOutageLineSnapshot(
              menuItemId: 'menu-2',
              name: 'Mocha',
              quantity: 1,
              selectedOptionIds: {
                'group-1': ['option-1'],
              },
              modifierLabels: ['Extra shot'],
              unitPriceUsd: 4.25,
              lineTotalUsdExact: 4.25,
            ),
          ],
          state: SaleOutageOrderStates.localOpenOrderCaptured,
          sourceMode: SaleOutageSourceModes.manualExternalPaymentClaim,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );

      final count = await queue.backfillManualClaimCaptureOperations(
        scope: scope,
      );
      final queued = await queueStore.listForContext(
        tenantId: scope.tenantId,
        branchId: scope.branchId,
        accountId: scope.accountId,
      );

      expect(count, 1);
      expect(queued, hasLength(1));
      expect(
        queued.single.operationType,
        OfflineOperationType.orderManualExternalPaymentClaimCapture,
      );
      final payload = queued.single.decodePayload();
      expect(payload['localIntentId'], 'local-claim-1');
      expect(payload['orderId'], isNotEmpty);
      final items = payload['items'] as List<dynamic>;
      expect(items.single, containsPair('menuItemNameSnapshot', 'Mocha'));
      expect(items.single, containsPair('unitPrice', 4.25));
      expect(items.single, containsPair('lineSubtotal', 4.25));
      expect(
        items.single,
        containsPair('modifierSelections', [
          {
            'groupId': 'group-1',
            'optionIds': ['option-1'],
          },
        ]),
      );
    },
  );
}
