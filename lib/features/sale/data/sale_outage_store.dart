import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';

class SaleOutageScope {
  const SaleOutageScope({
    required this.tenantId,
    required this.branchId,
    required this.accountId,
  });

  final String tenantId;
  final String branchId;
  final String accountId;

  @override
  bool operator ==(Object other) {
    return other is SaleOutageScope &&
        other.tenantId == tenantId &&
        other.branchId == branchId &&
        other.accountId == accountId;
  }

  @override
  int get hashCode => Object.hash(tenantId, branchId, accountId);
}

abstract class SaleOutageStore {
  Future<List<SaleOutageOrderRecord>> list(SaleOutageScope scope);

  Future<SaleOutageOrderRecord?> readByLocalIntentId({
    required SaleOutageScope scope,
    required String localIntentId,
  });

  Future<void> write(SaleOutageOrderRecord record);

  Future<void> deleteByLocalIntentId({
    required SaleOutageScope scope,
    required String localIntentId,
  });

  Future<void> clearScope(SaleOutageScope scope);
}

class DriftSaleOutageStore implements SaleOutageStore {
  DriftSaleOutageStore(this._db);

  final AppDatabase _db;

  @override
  Future<List<SaleOutageOrderRecord>> list(SaleOutageScope scope) async {
    final rows =
        await (_db.select(_db.saleOutageOrderEntries)
              ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
              ..where((tbl) => tbl.branchId.equals(scope.branchId))
              ..where((tbl) => _visibleToScope(tbl, scope))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<SaleOutageOrderRecord?> readByLocalIntentId({
    required SaleOutageScope scope,
    required String localIntentId,
  }) async {
    final row =
        await (_db.select(_db.saleOutageOrderEntries)
              ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
              ..where((tbl) => tbl.branchId.equals(scope.branchId))
              ..where((tbl) => _visibleToScope(tbl, scope))
              ..where((tbl) => tbl.localIntentId.equals(localIntentId)))
            .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<void> write(SaleOutageOrderRecord record) {
    return _db
        .into(_db.saleOutageOrderEntries)
        .insertOnConflictUpdate(
          SaleOutageOrderEntriesCompanion.insert(
            localIntentId: record.localIntentId,
            orderNumber: record.orderNumber,
            tenantId: record.tenantId,
            branchId: record.branchId,
            accountId: record.accountId,
            saleType: record.saleType,
            paymentMethodRequested: record.paymentMethodRequested,
            tenderCurrency: record.tenderCurrency,
            cashReceivedUsd: Value(record.cashReceivedUsd),
            cashReceivedKhr: Value(record.cashReceivedKhr),
            totalUsd: record.totalUsd,
            totalKhr: record.totalKhr,
            linesJson: jsonEncode(
              record.lines.map((line) => line.toJson()).toList(growable: false),
            ),
            state: SaleOutageOrderStates.normalize(record.state),
            sourceMode: SaleOutageSourceModes.normalize(record.sourceMode),
            backendOrderId: Value(record.backendOrderId),
            materializedAt: Value(record.materializedAt),
            claimedPaymentMethod: Value(record.claimedPaymentMethod),
            claimedTenderAmount: Value(record.claimedTenderAmount),
            proofImageUrl: Value(record.proofImageUrl),
            customerReference: Value(record.customerReference),
            note: Value(record.note),
            claimRecordedAt: Value(record.claimRecordedAt),
            backendClaimId: Value(record.backendClaimId),
            claimSubmittedAt: Value(record.claimSubmittedAt),
            lastErrorCode: Value(record.lastErrorCode),
            lastErrorMessage: Value(record.lastErrorMessage),
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
          ),
        );
  }

  @override
  Future<void> deleteByLocalIntentId({
    required SaleOutageScope scope,
    required String localIntentId,
  }) async {
    await (_db.delete(_db.saleOutageOrderEntries)
          ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
          ..where((tbl) => tbl.branchId.equals(scope.branchId))
          ..where((tbl) => _visibleToScope(tbl, scope))
          ..where((tbl) => tbl.localIntentId.equals(localIntentId)))
        .go();
  }

  @override
  Future<void> clearScope(SaleOutageScope scope) async {
    await (_db.delete(_db.saleOutageOrderEntries)
          ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
          ..where((tbl) => tbl.branchId.equals(scope.branchId))
          ..where((tbl) => tbl.accountId.equals(scope.accountId)))
        .go();
  }

  Expression<bool> _visibleToScope(
    $SaleOutageOrderEntriesTable tbl,
    SaleOutageScope scope,
  ) {
    return tbl.accountId.equals(scope.accountId) |
        tbl.sourceMode.equals(
          SaleOutageSourceModes.manualExternalPaymentClaim,
        );
  }

  SaleOutageOrderRecord _mapRow(SaleOutageOrderEntry row) {
    final decodedLines = jsonDecode(row.linesJson) as List<dynamic>;
    return SaleOutageOrderRecord(
      localIntentId: row.localIntentId,
      orderNumber: row.orderNumber,
      tenantId: row.tenantId,
      branchId: row.branchId,
      accountId: row.accountId,
      saleType: row.saleType,
      paymentMethodRequested: row.paymentMethodRequested,
      tenderCurrency: row.tenderCurrency,
      cashReceivedUsd: row.cashReceivedUsd,
      cashReceivedKhr: row.cashReceivedKhr,
      totalUsd: row.totalUsd,
      totalKhr: row.totalKhr,
      lines: decodedLines
          .map(
            (value) =>
                SaleOutageLineSnapshot.fromJson(value as Map<String, dynamic>),
          )
          .toList(growable: false),
      state: SaleOutageOrderStates.normalize(row.state),
      sourceMode: SaleOutageSourceModes.normalize(row.sourceMode),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      backendOrderId: row.backendOrderId,
      materializedAt: row.materializedAt,
      claimedPaymentMethod: row.claimedPaymentMethod,
      claimedTenderAmount: row.claimedTenderAmount,
      proofImageUrl: row.proofImageUrl,
      customerReference: row.customerReference,
      note: row.note,
      claimRecordedAt: row.claimRecordedAt,
      backendClaimId: row.backendClaimId,
      claimSubmittedAt: row.claimSubmittedAt,
      lastErrorCode: row.lastErrorCode,
      lastErrorMessage: row.lastErrorMessage,
    );
  }
}

final saleOutageScopeProvider = Provider<SaleOutageScope?>((ref) {
  final tenantId =
      (ref.watch(authTenantIdProvider) ??
              ref.watch(loginControllerProvider).session?.activeTenantId ??
              ref.watch(loginControllerProvider).session?.user.tenantId ??
              '')
          .trim();
  final workspaceBranchId = (ref.watch(activeBranchContextIdProvider) ?? '')
      .trim();
  final branchId = workspaceBranchId.isNotEmpty
      ? workspaceBranchId
      : (ref.watch(authActiveBranchIdProvider) ?? '').trim();
  final accountId = (ref.watch(loginControllerProvider).session?.user.id ?? '')
      .trim();

  if (tenantId.isEmpty || branchId.isEmpty || accountId.isEmpty) return null;
  return SaleOutageScope(
    tenantId: tenantId,
    branchId: branchId,
    accountId: accountId,
  );
});

final saleOutageStoreProvider = Provider<SaleOutageStore>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return DriftSaleOutageStore(database);
});
