import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/data/inventory_paginated_result.dart';
import 'package:modular_pos/features/inventory/data/mock_inventory_store.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';

final mockInventoryJournalRepositoryProvider =
    Provider<InventoryJournalRepository>((ref) {
      final store = ref.watch(mockInventoryStoreProvider);
      return MockInventoryJournalRepository(store);
    });

class MockInventoryJournalRepository extends InventoryJournalRepository {
  MockInventoryJournalRepository(this._store);

  final MockInventoryStore _store;

  @override
  Future<InventoryJournalEntry?> createRestockBatch({
    required String branchId,
    required String stockItemId,
    required num qty,
    String? note,
    String? receivedAt,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
  }) async {
    return _store.createRestockBatch(
      branchId: branchId,
      stockItemId: stockItemId,
      qty: qty,
      note: note,
      receivedAt: receivedAt,
      expiryDate: expiryDate,
      supplierName: supplierName,
      purchaseCostUsd: purchaseCostUsd,
    );
  }

  @override
  Future<InventoryJournalEntry?> waste({
    required String branchId,
    required String stockItemId,
    required num qty,
    required String note,
    String? occurredAt,
  }) async {
    throw UnsupportedError(
      'Use applyAdjustment for inventory deductions under the current inventory contract.',
    );
  }

  @override
  Future<InventoryJournalEntry?> correct({
    required String branchId,
    required String stockItemId,
    required num delta,
    required String note,
    String? occurredAt,
  }) async {
    throw UnsupportedError(
      'Use applyAdjustment for inventory corrections under the current inventory contract.',
    );
  }

  @override
  Future<int?> applyAdjustment({
    required String branchId,
    required String stockItemId,
    required String style,
    int? deltaInBaseUnit,
    int? countedOnHandInBaseUnit,
    required String reasonCode,
    String? note,
  }) async {
    return _store.applyAdjustment(
      branchId: branchId,
      stockItemId: stockItemId,
      style: style,
      deltaInBaseUnit: deltaInBaseUnit,
      countedOnHandInBaseUnit: countedOnHandInBaseUnit,
      reasonCode: reasonCode,
      note: note,
    );
  }

  @override
  Future<InventoryPaginatedResult<InventoryJournalEntry>> fetch({
    String? branchId,
    bool tenantWide = false,
    String? stockItemId,
    InventoryJournalReason? reason,
    DateTime? date,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    return _store.fetchJournal(
      branchId: branchId,
      tenantWide: tenantWide,
      stockItemId: stockItemId,
      reason: reason,
      date: date,
      from: date == null ? from : null,
      to: date == null ? to : null,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<List<InventoryJournalEntry>> lowStockAlerts({String? branchId}) async {
    return _store.lowStockAlerts(branchId: branchId);
  }

  @override
  Future<InventoryPaginatedResult<StockBatch>> fetchRestockBatches({
    String? branchId,
    String status = 'all',
    String? stockItemId,
    int? limit,
    int? offset,
  }) async {
    return _store.fetchRestockBatches(
      branchId: branchId,
      status: status,
      stockItemId: stockItemId,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<StockBatch> updateRestockBatchMetadata({
    required String batchId,
    required String branchId,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
    String? note,
  }) async {
    return _store.updateRestockBatchMetadata(
      batchId: batchId,
      branchId: branchId,
      expiryDate: expiryDate,
      supplierName: supplierName,
      purchaseCostUsd: purchaseCostUsd,
      note: note,
    );
  }

  @override
  Future<void> archiveRestockBatch({
    required String batchId,
    required String branchId,
  }) async {
    _store.archiveRestockBatch(batchId: batchId, branchId: branchId);
  }
}
