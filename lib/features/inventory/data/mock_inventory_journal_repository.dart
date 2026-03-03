import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';

final mockInventoryJournalRepositoryProvider =
    Provider<InventoryJournalRepository>((ref) {
      return MockInventoryJournalRepository();
    });

class MockInventoryJournalRepository extends InventoryJournalRepository {
  MockInventoryJournalRepository();

  final List<InventoryJournalEntry> _entries = <InventoryJournalEntry>[];

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
    final entry = _createEntry(
      branchId: branchId,
      stockItemId: stockItemId,
      qtyDelta: qty,
      reason: InventoryJournalReason.restock,
      note: note,
      occurredAt: receivedAt,
    );
    _entries.insert(0, entry);
    return entry;
  }

  @override
  Future<InventoryJournalEntry?> waste({
    required String branchId,
    required String stockItemId,
    required num qty,
    required String note,
    String? occurredAt,
  }) async {
    final entry = _createEntry(
      branchId: branchId,
      stockItemId: stockItemId,
      qtyDelta: -qty.abs(),
      reason: InventoryJournalReason.remove,
      note: note,
      occurredAt: occurredAt,
    );
    _entries.insert(0, entry);
    return entry;
  }

  @override
  Future<InventoryJournalEntry?> correct({
    required String branchId,
    required String stockItemId,
    required num delta,
    required String note,
    String? occurredAt,
  }) async {
    final entry = _createEntry(
      branchId: branchId,
      stockItemId: stockItemId,
      qtyDelta: delta,
      reason: InventoryJournalReason.add,
      note: note,
      occurredAt: occurredAt,
    );
    _entries.insert(0, entry);
    return entry;
  }

  @override
  Future<int?> applyAdjustment({
    required String stockItemId,
    required String style,
    int? deltaInBaseUnit,
    int? countedOnHandInBaseUnit,
    required String reasonCode,
    String? note,
  }) async {
    if (style.trim().toUpperCase() == 'SET_TO_COUNT') {
      return countedOnHandInBaseUnit;
    }
    return null;
  }

  @override
  Future<List<InventoryJournalEntry>> fetch({
    String? stockItemId,
    InventoryJournalReason? reason,
    int limit = 50,
    int offset = 0,
  }) async {
    var filtered =
        _entries
            .where((entry) {
              if (stockItemId != null &&
                  stockItemId.isNotEmpty &&
                  entry.itemId != stockItemId) {
                return false;
              }
              if (reason != null && entry.reason != reason) {
                return false;
              }
              return true;
            })
            .toList(growable: false)
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit <= 0 ? 50 : limit;
    final start = safeOffset;
    if (start >= filtered.length) {
      return const <InventoryJournalEntry>[];
    }
    final end = (start + safeLimit).clamp(0, filtered.length);
    filtered = filtered.sublist(start, end);

    return filtered;
  }

  @override
  Future<List<InventoryJournalEntry>> lowStockAlerts({String? branchId}) async {
    return const <InventoryJournalEntry>[];
  }

  @override
  Future<List<StockBatch>> fetchRestockBatches({
    String status = 'all',
    String? stockItemId,
    int? limit,
    int? offset,
  }) async {
    return const <StockBatch>[];
  }

  @override
  Future<StockBatch> updateRestockBatchMetadata({
    required String batchId,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
    String? note,
  }) async {
    return StockBatch(
      id: batchId,
      stockItemId: '',
      branchId: '',
      onHand: 0,
      receivedDate: DateTime.now().toIso8601String().split('T').first,
      expiryDate: expiryDate,
    );
  }

  @override
  Future<void> archiveRestockBatch({required String batchId}) async {}

  InventoryJournalEntry _createEntry({
    required String branchId,
    required String stockItemId,
    required num qtyDelta,
    required InventoryJournalReason reason,
    required String? note,
    required String? occurredAt,
  }) {
    final now = DateTime.now();
    final occurred = DateTime.tryParse(occurredAt ?? '') ?? now;
    final id = 'mock-journal-${_entries.length + 1}';
    return InventoryJournalEntry(
      id: id,
      itemId: stockItemId,
      itemName: stockItemId,
      branchId: branchId,
      branchName: '',
      reason: reason,
      delta: qtyDelta.toInt(),
      note: note ?? '',
      actor: 'Mock User',
      createdAt: now,
      occurredAt: occurred,
    );
  }
}
