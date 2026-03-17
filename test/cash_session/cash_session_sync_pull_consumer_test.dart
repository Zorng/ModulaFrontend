import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_cache_store.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_sync_pull_consumer.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';

void main() {
  late AppDatabase database;
  late DriftCashSessionCacheStore cacheStore;
  late CashSessionSyncPullConsumer consumer;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    cacheStore = DriftCashSessionCacheStore(database);
    consumer = CashSessionSyncPullConsumer(cacheStore);
  });

  tearDown(() async {
    await database.close();
  });

  test('apply writes active session bundle with movements and sales', () async {
    await consumer.apply(
      context: const SyncPullContext(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      ),
      payload: const {
        'session': {
          'id': 'session-1',
          'tenantId': 'tenant-1',
          'branchId': 'branch-1',
          'openedByAccountId': 'user-1',
          'openedByName': 'John Smith',
          'openedAt': '2026-03-17T09:00:00Z',
          'status': 'OPEN',
          'openingFloatUsd': 25.0,
          'openingFloatKhr': 100000.0,
        },
        'movements': [
          {
            'id': 'movement-1',
            'sessionId': 'session-1',
            'tenantId': 'tenant-1',
            'branchId': 'branch-1',
            'movementType': 'MANUAL_IN',
            'amountUsd': 5.0,
            'amountKhr': 0.0,
            'reason': 'Top up',
            'sourceRefType': 'MANUAL',
            'recordedByAccountId': 'user-1',
            'occurredAt': '2026-03-17T10:00:00Z',
          },
        ],
        'sales': [
          {
            'saleId': 'sale-1',
            'status': 'FINALIZED',
            'paymentMethod': 'CASH',
            'saleType': 'TAKEAWAY',
            'finalizedAt': '2026-03-17T10:30:00Z',
            'totalItems': 1,
            'grandTotalUsd': 7.5,
            'grandTotalKhr': 30750.0,
            'cashierAccountId': 'user-1',
            'cashierName': 'John Smith',
          },
        ],
      },
      cursor: 'cursor-1',
      pulledAt: DateTime.utc(2026, 3, 17, 11),
    );

    final cached = await cacheStore.read(
      tenantId: 'tenant-1',
      branchId: 'branch-1',
    );

    expect(cached.session?.id, 'session-1');
    expect(cached.movements, hasLength(1));
    expect(cached.movements.first.id, 'movement-1');
    expect(cached.sales, hasLength(1));
    expect(cached.sales.first.saleId, 'sale-1');
  });

  test(
    'apply preserves existing detail lists when payload only updates session snapshot',
    () async {
      await cacheStore.write(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        session: CashSession(
          id: 'session-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          openedByAccountId: 'user-1',
          openedByName: 'John Smith',
          openedAt: DateTime.utc(2026, 3, 17, 9),
          status: CashSessionStatuses.open,
          openingFloatUsd: 25,
          openingFloatKhr: 100000,
          closedAt: null,
          closedByAccountId: null,
          closedByName: null,
          closeNote: null,
          totalPaidInUsd: 0,
          totalPaidOutUsd: 0,
        ),
        movements: [
          CashMovement(
            id: 'movement-1',
            sessionId: 'session-1',
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            movementType: CashMovementTypes.manualIn,
            amountUsd: 5,
            amountKhr: 0,
            reason: 'Top up',
            sourceRefType: 'MANUAL',
            sourceRefId: null,
            recordedByAccountId: 'user-1',
            occurredAt: DateTime.utc(2026, 3, 17, 10),
          ),
        ],
        sales: [
          CashSessionSale(
            saleId: 'sale-1',
            status: CashSessionSaleStatuses.finalized,
            paymentMethod: 'CASH',
            saleType: 'TAKEAWAY',
            finalizedAt: DateTime.utc(2026, 3, 17, 10, 30),
            totalItems: 1,
            grandTotalUsd: 7.5,
            grandTotalKhr: 30750,
            cashierAccountId: 'user-1',
            cashierName: 'John Smith',
            voidedAt: null,
          ),
        ],
      );

      await consumer.apply(
        context: const SyncPullContext(
          deviceId: 'device-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
        ),
        payload: const {
          'session': {
            'id': 'session-1',
            'tenantId': 'tenant-1',
            'branchId': 'branch-1',
            'openedByAccountId': 'user-1',
            'openedByName': 'John Smith',
            'openedAt': '2026-03-17T09:00:00Z',
            'status': 'OPEN',
            'openingFloatUsd': 30.0,
            'openingFloatKhr': 120000.0,
          },
        },
        cursor: 'cursor-2',
        pulledAt: DateTime.utc(2026, 3, 17, 12),
      );

      final cached = await cacheStore.read(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      );

      expect(cached.session?.openingFloatUsd, 30.0);
      expect(cached.movements, hasLength(1));
      expect(cached.sales, hasLength(1));
    },
  );

  test(
    'apply clears cached snapshot when payload explicitly reports no active session',
    () async {
      await cacheStore.write(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        session: CashSession(
          id: 'session-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          openedByAccountId: 'user-1',
          openedByName: 'John Smith',
          openedAt: DateTime.utc(2026, 3, 17, 9),
          status: CashSessionStatuses.open,
          openingFloatUsd: 25,
          openingFloatKhr: 100000,
          closedAt: null,
          closedByAccountId: null,
          closedByName: null,
          closeNote: null,
          totalPaidInUsd: 0,
          totalPaidOutUsd: 0,
        ),
        movements: const [],
        sales: const [],
      );

      await consumer.apply(
        context: const SyncPullContext(
          deviceId: 'device-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
        ),
        payload: const {'session': null},
        cursor: 'cursor-3',
        pulledAt: DateTime.utc(2026, 3, 17, 13),
      );

      final cached = await cacheStore.read(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      );

      expect(cached.session, isNull);
      expect(cached.movements, isEmpty);
      expect(cached.sales, isEmpty);
    },
  );
}
