import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';

final mockInventoryJournalRepositoryProvider =
    Provider<InventoryJournalRepository>((ref) {
      return MockInventoryJournalRepository();
    });

class MockInventoryJournalRepository extends InventoryJournalRepository {
  MockInventoryJournalRepository();

  final List<InventoryJournalEntry> _entries = <InventoryJournalEntry>[];

  @override
  Future<InventoryJournalEntry?> receive({
    required String branchId,
    required String stockItemId,
    required num qty,
    String? note,
    String? occurredAt,
  }) async {
    final entry = _createEntry(
      branchId: branchId,
      stockItemId: stockItemId,
      qtyDelta: qty,
      reason: InventoryJournalReason.restock,
      note: note,
      occurredAt: occurredAt,
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
  Future<List<InventoryJournalEntry>> fetch({
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
    String? fromDate,
    String? toDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    var filtered =
        _entries
            .where((entry) {
              if (branchId != null &&
                  branchId.isNotEmpty &&
                  entry.branchId != branchId) {
                return false;
              }
              if (stockItemId != null &&
                  stockItemId.isNotEmpty &&
                  entry.itemId != stockItemId) {
                return false;
              }
              if (reason != null && entry.reason != reason) {
                return false;
              }
              if (fromDate != null && fromDate.isNotEmpty) {
                final from = DateTime.tryParse(fromDate);
                if (from != null && entry.occurredAt.isBefore(from)) {
                  return false;
                }
              }
              if (toDate != null && toDate.isNotEmpty) {
                final to = DateTime.tryParse(toDate);
                if (to != null && entry.occurredAt.isAfter(to)) {
                  return false;
                }
              }
              return true;
            })
            .toList(growable: false)
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final start =
        ((page <= 1 ? 1 : page) - 1) * (pageSize <= 0 ? 50 : pageSize);
    if (start >= filtered.length) {
      return const <InventoryJournalEntry>[];
    }
    final end = (start + (pageSize <= 0 ? 50 : pageSize)).clamp(
      0,
      filtered.length,
    );
    filtered = filtered.sublist(start, end);

    return filtered;
  }

  @override
  Future<List<InventoryJournalEntry>> lowStockAlerts({String? branchId}) async {
    return const <InventoryJournalEntry>[];
  }

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
