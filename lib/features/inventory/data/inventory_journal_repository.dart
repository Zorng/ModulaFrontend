import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/mock_inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/data/remote_inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart'
    show useMockInventoryRepositoryProvider;
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';

final inventoryJournalRepositoryProvider = Provider<InventoryJournalRepository>(
  (ref) {
    final useMock = ref.watch(useMockInventoryRepositoryProvider);
    if (useMock) {
      return ref.watch(mockInventoryJournalRepositoryProvider);
    }
    return ref.watch(remoteInventoryJournalRepositoryProvider);
  },
);

abstract class InventoryJournalRepository {
  const InventoryJournalRepository();

  Future<InventoryJournalEntry?> createRestockBatch({
    required String branchId,
    required String stockItemId,
    required num qty,
    String? note,
    String? receivedAt,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
  });

  @Deprecated('Use createRestockBatch')
  Future<InventoryJournalEntry?> receive({
    required String branchId,
    required String stockItemId,
    required num qty,
    String? note,
    String? receivedAt,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
  }) {
    return createRestockBatch(
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

  Future<InventoryJournalEntry?> waste({
    required String branchId,
    required String stockItemId,
    required num qty,
    required String note,
    String? occurredAt,
  });

  Future<InventoryJournalEntry?> correct({
    required String branchId,
    required String stockItemId,
    required num delta,
    required String note,
    String? occurredAt,
  });

  Future<int?> applyAdjustment({
    required String branchId,
    required String stockItemId,
    required String style,
    int? deltaInBaseUnit,
    int? countedOnHandInBaseUnit,
    required String reasonCode,
    String? note,
  });

  Future<List<InventoryJournalEntry>> fetch({
    String? branchId,
    bool tenantWide = false,
    String? stockItemId,
    InventoryJournalReason? reason,
    DateTime? date,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  });

  Future<List<InventoryJournalEntry>> lowStockAlerts({String? branchId});

  Future<List<StockBatch>> fetchRestockBatches({
    String? branchId,
    String status = 'all',
    String? stockItemId,
    int? limit,
    int? offset,
  });

  Future<StockBatch> updateRestockBatchMetadata({
    required String batchId,
    required String branchId,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
    String? note,
  });

  Future<void> archiveRestockBatch({
    required String batchId,
    required String branchId,
  });
}
