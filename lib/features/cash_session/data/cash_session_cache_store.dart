import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';

class CashSessionCacheSnapshot {
  const CashSessionCacheSnapshot({
    required this.session,
    required this.movements,
    required this.sales,
  });

  final CashSession? session;
  final List<CashMovement> movements;
  final List<CashSessionSale> sales;
}

abstract class CashSessionCacheStore {
  Future<CashSessionCacheSnapshot> read({
    required String tenantId,
    required String branchId,
  });

  Future<void> write({
    required String tenantId,
    required String branchId,
    required CashSession session,
    required List<CashMovement> movements,
    required List<CashSessionSale> sales,
  });

  Future<void> clear({required String tenantId, required String branchId});
}

class DriftCashSessionCacheStore implements CashSessionCacheStore {
  DriftCashSessionCacheStore(this._db);

  final AppDatabase _db;

  @override
  Future<CashSessionCacheSnapshot> read({
    required String tenantId,
    required String branchId,
  }) async {
    final normalizedTenantId = tenantId.trim();
    final normalizedBranchId = branchId.trim();

    final snapshotRow =
        await (_db.select(_db.cashSessionSnapshotEntries)
              ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
              ..where((tbl) => tbl.branchId.equals(normalizedBranchId)))
            .getSingleOrNull();

    if (snapshotRow == null) {
      return const CashSessionCacheSnapshot(
        session: null,
        movements: <CashMovement>[],
        sales: <CashSessionSale>[],
      );
    }

    final session = CashSession(
      id: snapshotRow.sessionId,
      tenantId: snapshotRow.tenantId,
      branchId: snapshotRow.branchId,
      openedByAccountId: snapshotRow.openedByAccountId,
      openedByName: snapshotRow.openedByName,
      openedAt: snapshotRow.openedAt,
      status: snapshotRow.status,
      openingFloatUsd: snapshotRow.openingFloatUsd,
      openingFloatKhr: snapshotRow.openingFloatKhr,
      closedAt: snapshotRow.closedAt,
      closedByAccountId: snapshotRow.closedByAccountId,
      closedByName: snapshotRow.closedByName,
      closeNote: snapshotRow.closeNote,
      totalPaidInUsd: snapshotRow.totalPaidInUsd,
      totalPaidOutUsd: snapshotRow.totalPaidOutUsd,
    );

    final movementRows =
        await (_db.select(_db.cashSessionMovementCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
              ..where((tbl) => tbl.branchId.equals(normalizedBranchId))
              ..where((tbl) => tbl.sessionId.equals(session.id))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
            .get();
    final saleRows =
        await (_db.select(_db.cashSessionSaleCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
              ..where((tbl) => tbl.branchId.equals(normalizedBranchId))
              ..where((tbl) => tbl.sessionId.equals(session.id))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
            .get();

    return CashSessionCacheSnapshot(
      session: session,
      movements: movementRows
          .map(
            (row) => CashMovement(
              id: row.movementId,
              sessionId: row.sessionId,
              tenantId: row.tenantId,
              branchId: row.branchId,
              movementType: row.movementType,
              amountUsd: row.amountUsd,
              amountKhr: row.amountKhr,
              reason: row.reason,
              sourceRefType: row.sourceRefType,
              sourceRefId: row.sourceRefId,
              recordedByAccountId: row.recordedByAccountId,
              occurredAt: row.occurredAt,
            ),
          )
          .toList(growable: false),
      sales: saleRows
          .map(
            (row) => CashSessionSale(
              saleId: row.saleId,
              status: row.status,
              paymentMethod: row.paymentMethod,
              saleType: row.saleType,
              finalizedAt: row.finalizedAt,
              totalItems: row.totalItems,
              grandTotalUsd: row.grandTotalUsd,
              grandTotalKhr: row.grandTotalKhr,
              cashierAccountId: row.cashierAccountId,
              cashierName: row.cashierName,
              voidedAt: row.voidedAt,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> write({
    required String tenantId,
    required String branchId,
    required CashSession session,
    required List<CashMovement> movements,
    required List<CashSessionSale> sales,
  }) async {
    final normalizedTenantId = tenantId.trim();
    final normalizedBranchId = branchId.trim();

    await _db.transaction(() async {
      await _db
          .into(_db.cashSessionSnapshotEntries)
          .insertOnConflictUpdate(
            CashSessionSnapshotEntriesCompanion.insert(
              tenantId: normalizedTenantId,
              branchId: normalizedBranchId,
              sessionId: session.id,
              openedByAccountId: session.openedByAccountId,
              openedByName: session.openedByName,
              openedAt: Value(session.openedAt),
              status: session.status,
              openingFloatUsd: session.openingFloatUsd,
              openingFloatKhr: session.openingFloatKhr,
              closedAt: Value(session.closedAt),
              closedByAccountId: Value(session.closedByAccountId),
              closedByName: Value(session.closedByName),
              closeNote: Value(session.closeNote),
              totalPaidInUsd: session.totalPaidInUsd,
              totalPaidOutUsd: session.totalPaidOutUsd,
              cachedAt: DateTime.now(),
            ),
          );

      await (_db.delete(_db.cashSessionMovementCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
            ..where((tbl) => tbl.branchId.equals(normalizedBranchId)))
          .go();
      await (_db.delete(_db.cashSessionSaleCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
            ..where((tbl) => tbl.branchId.equals(normalizedBranchId)))
          .go();

      for (var index = 0; index < movements.length; index++) {
        final movement = movements[index];
        await _db
            .into(_db.cashSessionMovementCacheEntries)
            .insert(
              CashSessionMovementCacheEntriesCompanion.insert(
                tenantId: normalizedTenantId,
                branchId: normalizedBranchId,
                sessionId: session.id,
                movementId: movement.id,
                movementType: movement.movementType,
                amountUsd: movement.amountUsd,
                amountKhr: movement.amountKhr,
                reason: Value(movement.reason),
                sourceRefType: movement.sourceRefType,
                sourceRefId: Value(movement.sourceRefId),
                recordedByAccountId: movement.recordedByAccountId,
                occurredAt: Value(movement.occurredAt),
                sortOrder: index,
              ),
            );
      }

      for (var index = 0; index < sales.length; index++) {
        final sale = sales[index];
        await _db
            .into(_db.cashSessionSaleCacheEntries)
            .insert(
              CashSessionSaleCacheEntriesCompanion.insert(
                tenantId: normalizedTenantId,
                branchId: normalizedBranchId,
                sessionId: session.id,
                saleId: sale.saleId,
                status: sale.status,
                paymentMethod: sale.paymentMethod,
                saleType: sale.saleType,
                finalizedAt: Value(sale.finalizedAt),
                totalItems: sale.totalItems,
                grandTotalUsd: sale.grandTotalUsd,
                grandTotalKhr: sale.grandTotalKhr,
                cashierAccountId: sale.cashierAccountId,
                cashierName: sale.cashierName,
                voidedAt: Value(sale.voidedAt),
                sortOrder: index,
              ),
            );
      }
    });
  }

  @override
  Future<void> clear({
    required String tenantId,
    required String branchId,
  }) async {
    final normalizedTenantId = tenantId.trim();
    final normalizedBranchId = branchId.trim();
    await _db.transaction(() async {
      await (_db.delete(_db.cashSessionSnapshotEntries)
            ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
            ..where((tbl) => tbl.branchId.equals(normalizedBranchId)))
          .go();
      await (_db.delete(_db.cashSessionMovementCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
            ..where((tbl) => tbl.branchId.equals(normalizedBranchId)))
          .go();
      await (_db.delete(_db.cashSessionSaleCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
            ..where((tbl) => tbl.branchId.equals(normalizedBranchId)))
          .go();
    });
  }
}

final cashSessionCacheStoreProvider = Provider<CashSessionCacheStore>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftCashSessionCacheStore(db);
});
