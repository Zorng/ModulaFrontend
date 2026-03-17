import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/policy/data/policy_cache_store.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

void main() {
  late AppDatabase database;
  late PolicyCacheStore store;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftPolicyCacheStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('writes and reads cached branch policy by tenant and branch', () async {
    const policy = BranchPolicy(
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      saleVatEnabled: true,
      saleVatRatePercent: 10,
      saleFxRateKhrPerUsd: 4050,
      saleKhrRoundingEnabled: true,
      saleKhrRoundingMode: BranchPolicyRoundingModes.up,
      saleKhrRoundingGranularity: BranchPolicyRoundingGranularities.thousand,
      saleAllowPayLater: true,
      createdAt: '2026-03-16T00:00:00Z',
      updatedAt: '2026-03-16T00:00:00Z',
    );

    await store.write(policy);

    final loaded = await store.read(tenantId: 'tenant-1', branchId: 'branch-1');

    expect(loaded, isNotNull);
    expect(loaded!.saleFxRateKhrPerUsd, 4050);
    expect(loaded.saleAllowPayLater, isTrue);
    expect(loaded.saleKhrRoundingMode, BranchPolicyRoundingModes.up);
  });

  test('clear removes the targeted cached branch policy only', () async {
    await store.write(
      const BranchPolicy(tenantId: 'tenant-1', branchId: 'branch-1'),
    );
    await store.write(
      const BranchPolicy(tenantId: 'tenant-1', branchId: 'branch-2'),
    );

    await store.clear(tenantId: 'tenant-1', branchId: 'branch-1');

    final cleared = await store.read(
      tenantId: 'tenant-1',
      branchId: 'branch-1',
    );
    final remaining = await store.read(
      tenantId: 'tenant-1',
      branchId: 'branch-2',
    );

    expect(cleared, isNull);
    expect(remaining, isNotNull);
  });
}
