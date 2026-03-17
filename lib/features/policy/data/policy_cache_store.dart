import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

abstract class PolicyCacheStore {
  Future<BranchPolicy?> read({
    required String tenantId,
    required String branchId,
  });

  Future<void> write(BranchPolicy policy);

  Future<void> clear({required String tenantId, required String branchId});
}

class DriftPolicyCacheStore implements PolicyCacheStore {
  DriftPolicyCacheStore(this._db);

  final AppDatabase _db;

  @override
  Future<BranchPolicy?> read({
    required String tenantId,
    required String branchId,
  }) async {
    final row =
        await (_db.select(_db.policyCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(tenantId.trim()))
              ..where((tbl) => tbl.branchId.equals(branchId.trim())))
            .getSingleOrNull();

    if (row == null) return null;
    return BranchPolicy(
      tenantId: row.tenantId,
      branchId: row.branchId,
      saleVatEnabled: row.saleVatEnabled,
      saleVatRatePercent: row.saleVatRatePercent,
      saleFxRateKhrPerUsd: row.saleFxRateKhrPerUsd,
      saleKhrRoundingEnabled: row.saleKhrRoundingEnabled,
      saleKhrRoundingMode: row.saleKhrRoundingMode,
      saleKhrRoundingGranularity: row.saleKhrRoundingGranularity,
      saleAllowPayLater: row.saleAllowPayLater,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> write(BranchPolicy policy) {
    return _db
        .into(_db.policyCacheEntries)
        .insertOnConflictUpdate(
          PolicyCacheEntriesCompanion.insert(
            tenantId: policy.tenantId.trim(),
            branchId: policy.branchId.trim(),
            saleVatEnabled: policy.saleVatEnabled,
            saleVatRatePercent: policy.saleVatRatePercent,
            saleFxRateKhrPerUsd: policy.saleFxRateKhrPerUsd,
            saleKhrRoundingEnabled: policy.saleKhrRoundingEnabled,
            saleKhrRoundingMode: policy.saleKhrRoundingMode,
            saleKhrRoundingGranularity: policy.saleKhrRoundingGranularity,
            saleAllowPayLater: policy.saleAllowPayLater,
            createdAt: policy.createdAt,
            updatedAt: policy.updatedAt,
            cachedAt: DateTime.now(),
            syncCursorApplied: const Value.absent(),
            lastPullAt: const Value.absent(),
          ),
        );
  }

  @override
  Future<void> clear({required String tenantId, required String branchId}) {
    return (_db.delete(_db.policyCacheEntries)
          ..where((tbl) => tbl.tenantId.equals(tenantId.trim()))
          ..where((tbl) => tbl.branchId.equals(branchId.trim())))
        .go();
  }
}

final policyCacheStoreProvider = Provider<PolicyCacheStore>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftPolicyCacheStore(db);
});
