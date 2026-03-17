import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_cache_store.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';

void main() {
  late AppDatabase database;
  late CashSessionCacheStore store;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftCashSessionCacheStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'writes and reads cached active cash session snapshot with detail lists',
    () async {
      final session = CashSession(
        id: 'session-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        openedByAccountId: 'user-1',
        openedByName: 'John Smith',
        openedAt: DateTime.utc(2026, 3, 16, 9),
        status: CashSessionStatuses.open,
        openingFloatUsd: 25,
        openingFloatKhr: 100000,
        closedAt: null,
        closedByAccountId: null,
        closedByName: null,
        closeNote: null,
        totalPaidInUsd: 0,
        totalPaidOutUsd: 0,
      );
      final movements = [
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
          occurredAt: DateTime.utc(2026, 3, 16, 10),
        ),
      ];
      final sales = [
        CashSessionSale(
          saleId: 'sale-1',
          status: CashSessionSaleStatuses.finalized,
          paymentMethod: 'CASH',
          saleType: 'TAKEAWAY',
          finalizedAt: DateTime.utc(2026, 3, 16, 10, 30),
          totalItems: 1,
          grandTotalUsd: 7.5,
          grandTotalKhr: 30750,
          cashierAccountId: 'user-1',
          cashierName: 'John Smith',
          voidedAt: null,
        ),
      ];

      await store.write(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        session: session,
        movements: movements,
        sales: sales,
      );

      final cached = await store.read(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      );

      expect(cached.session?.id, 'session-1');
      expect(cached.movements, hasLength(1));
      expect(cached.movements.first.id, 'movement-1');
      expect(cached.sales, hasLength(1));
      expect(cached.sales.first.saleId, 'sale-1');
    },
  );

  test(
    'clear removes cached session snapshot and detail lists for branch',
    () async {
      await store.write(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        session: CashSession(
          id: 'session-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          openedByAccountId: 'user-1',
          openedByName: 'John Smith',
          openedAt: DateTime.utc(2026, 3, 16, 9),
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

      await store.clear(tenantId: 'tenant-1', branchId: 'branch-1');

      final cached = await store.read(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      );

      expect(cached.session, isNull);
      expect(cached.movements, isEmpty);
      expect(cached.sales, isEmpty);
    },
  );
}
