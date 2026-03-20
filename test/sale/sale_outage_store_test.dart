import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/sale/data/sale_outage_store.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';

void main() {
  late AppDatabase database;
  late SaleOutageStore store;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftSaleOutageStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('writes and reads scoped outage sale orders', () async {
    final scope = const SaleOutageScope(
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      accountId: 'user-1',
    );
    final record = SaleOutageOrderRecord(
      localIntentId: 'local-1',
      orderNumber: 'LOCAL-ABC',
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      accountId: scope.accountId,
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
      state: SaleOutageOrderStates.manualExternalPaymentClaimRecorded,
      sourceMode: SaleOutageSourceModes.manualExternalPaymentClaim,
      claimedPaymentMethod: 'KHQR',
      claimedTenderAmount: 3.5,
      proofImageUrl: 'https://example.com/proof.jpg',
      customerReference: 'ABA-REF-001',
      note: 'Customer showed transfer screenshot',
      claimRecordedAt: DateTime.utc(2026, 3, 17, 9, 5),
      createdAt: DateTime.utc(2026, 3, 17, 9),
      updatedAt: DateTime.utc(2026, 3, 17, 9),
    );

    await store.write(record);

    final loaded = await store.list(scope);

    expect(loaded, hasLength(1));
    expect(loaded.first.localIntentId, 'local-1');
    expect(loaded.first.orderNumber, 'LOCAL-ABC');
    expect(loaded.first.lines.single.name, 'Iced Latte');
    expect(loaded.first.totalUsd, 3.5);
    expect(
      loaded.first.sourceMode,
      SaleOutageSourceModes.manualExternalPaymentClaim,
    );
    expect(
      loaded.first.state,
      SaleOutageOrderStates.manualExternalPaymentClaimRecorded,
    );
    expect(loaded.first.claimedPaymentMethod, 'KHQR');
    expect(loaded.first.proofImageUrl, 'https://example.com/proof.jpg');
  });

  test('deletes a scoped outage sale order by local intent id', () async {
    const scope = SaleOutageScope(
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      accountId: 'user-1',
    );

    await store.write(
      SaleOutageOrderRecord(
        localIntentId: 'local-1',
        orderNumber: 'LOCAL-ABC',
        tenantId: scope.tenantId,
        branchId: scope.branchId,
        accountId: scope.accountId,
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

    await store.deleteByLocalIntentId(scope: scope, localIntentId: 'local-1');

    final loaded = await store.list(scope);
    expect(loaded, isEmpty);
  });

  test(
    'manual-claim outage orders are visible across staff accounts on the same branch',
    () async {
      const creatorScope = SaleOutageScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'staff-1',
      );
      const otherStaffScope = SaleOutageScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'staff-2',
      );

      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-claim-1',
          orderNumber: 'LOCAL-CLM',
          tenantId: creatorScope.tenantId,
          branchId: creatorScope.branchId,
          accountId: creatorScope.accountId,
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
          proofImageUrl: 'https://example.com/proof.jpg',
          claimedPaymentMethod: 'KHQR',
          claimedTenderAmount: 3.5,
          createdAt: DateTime.utc(2026, 3, 17, 9),
          updatedAt: DateTime.utc(2026, 3, 17, 9),
        ),
      );

      final loaded = await store.list(otherStaffScope);
      final read = await store.readByLocalIntentId(
        scope: otherStaffScope,
        localIntentId: 'local-claim-1',
      );

      expect(loaded, hasLength(1));
      expect(loaded.single.accountId, creatorScope.accountId);
      expect(read?.localIntentId, 'local-claim-1');
    },
  );

  test(
    'standard outage orders stay account-scoped for other staff on the same branch',
    () async {
      const creatorScope = SaleOutageScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'staff-1',
      );
      const otherStaffScope = SaleOutageScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'staff-2',
      );

      await store.write(
        SaleOutageOrderRecord(
          localIntentId: 'local-cash-1',
          orderNumber: 'LOCAL-CASH',
          tenantId: creatorScope.tenantId,
          branchId: creatorScope.branchId,
          accountId: creatorScope.accountId,
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
          state: SaleOutageOrderStates.awaitingSettlement,
          sourceMode: SaleOutageSourceModes.standardOpenOrder,
          createdAt: DateTime.utc(2026, 3, 17, 9),
          updatedAt: DateTime.utc(2026, 3, 17, 9),
        ),
      );

      final loaded = await store.list(otherStaffScope);
      final read = await store.readByLocalIntentId(
        scope: otherStaffScope,
        localIntentId: 'local-cash-1',
      );

      expect(loaded, isEmpty);
      expect(read, isNull);
    },
  );
}
