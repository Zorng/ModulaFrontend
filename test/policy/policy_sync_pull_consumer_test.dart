import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/features/policy/data/policy_cache_store.dart';
import 'package:modular_pos/features/policy/data/policy_sync_pull_consumer.dart';

void main() {
  late AppDatabase database;
  late DriftPolicyCacheStore cacheStore;
  late PolicySyncPullConsumer consumer;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    cacheStore = DriftPolicyCacheStore(database);
    consumer = PolicySyncPullConsumer(cacheStore);
  });

  tearDown(() async {
    await database.close();
  });

  test('apply writes synced policy payload and cursor metadata', () async {
    await consumer.apply(
      context: const SyncPullContext(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      ),
      payload: const {
        'tenantId': 'tenant-1',
        'branchId': 'branch-1',
        'saleVatEnabled': true,
        'saleVatRatePercent': 10.0,
        'saleFxRateKhrPerUsd': 4050.0,
        'saleKhrRoundingEnabled': true,
        'saleKhrRoundingMode': 'UP',
        'saleKhrRoundingGranularity': '1000',
        'saleAllowPayLater': true,
        'saleAllowManualExternalPaymentClaim': true,
        'createdAt': '2026-03-17T10:00:00Z',
        'updatedAt': '2026-03-17T10:00:00Z',
      },
      cursor: 'cursor-1',
      pulledAt: DateTime.utc(2026, 3, 17, 10, 30),
    );

    final cached = await cacheStore.read(
      tenantId: 'tenant-1',
      branchId: 'branch-1',
    );
    final row =
        await (database.select(database.policyCacheEntries)
              ..where((tbl) => tbl.tenantId.equals('tenant-1'))
              ..where((tbl) => tbl.branchId.equals('branch-1')))
            .getSingleOrNull();

    expect(cached, isNotNull);
    expect(cached!.saleAllowPayLater, isTrue);
    expect(cached.saleAllowManualExternalPaymentClaim, isTrue);
    expect(cached.saleKhrRoundingMode, 'UP');
    expect(row, isNotNull);
    expect(row!.syncCursorApplied, 'cursor-1');
    expect(row.lastPullAt!.toUtc(), DateTime.utc(2026, 3, 17, 10, 30));
  });

  test(
    'apply supports nested payload and falls back to sync context ids',
    () async {
      await consumer.apply(
        context: const SyncPullContext(
          deviceId: 'device-1',
          tenantId: 'tenant-ctx',
          branchId: 'branch-ctx',
        ),
        payload: const {
          'policy': {
            'saleVatEnabled': false,
            'saleVatRatePercent': 0.0,
            'saleFxRateKhrPerUsd': 4100.0,
            'saleKhrRoundingEnabled': false,
            'saleKhrRoundingMode': 'NEAREST',
            'saleKhrRoundingGranularity': '100',
            'saleAllowPayLater': false,
            'saleAllowManualExternalPaymentClaim': false,
            'createdAt': '2026-03-17T00:00:00Z',
            'updatedAt': '2026-03-17T00:00:00Z',
          },
        },
        cursor: 'cursor-2',
        pulledAt: DateTime.utc(2026, 3, 17, 11),
      );

      final cached = await cacheStore.read(
        tenantId: 'tenant-ctx',
        branchId: 'branch-ctx',
      );

      expect(cached, isNotNull);
      expect(cached!.tenantId, 'tenant-ctx');
      expect(cached.branchId, 'branch-ctx');
    },
  );
}
