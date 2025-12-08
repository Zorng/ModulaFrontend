import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';

final inventoryJournalRepositoryProvider = Provider<InventoryJournalRepository>((ref) {
  final api = ref.watch(inventoryApiProvider);
  return InventoryJournalRepository(api);
});

class InventoryJournalRepository {
  const InventoryJournalRepository(this._api);

  final InventoryApi _api;

  Future<InventoryJournalEntry?> receive({
    required String branchId,
    required String stockItemId,
    required num qty,
    String? note,
  }) async {
    final json = await _api.receiveStock(
      branchId: branchId,
      stockItemId: stockItemId,
      qty: qty,
      note: note,
    );
    return _maybeEntry(json, fallbackReason: InventoryJournalReason.restock);
  }

  Future<InventoryJournalEntry?> waste({
    required String branchId,
    required String stockItemId,
    required num qty,
    required String note,
  }) async {
    final json = await _api.wasteStock(
      branchId: branchId,
      stockItemId: stockItemId,
      qty: qty,
      note: note,
    );
    return _maybeEntry(json, fallbackReason: InventoryJournalReason.remove);
  }

  Future<InventoryJournalEntry?> correct({
    required String branchId,
    required String stockItemId,
    required num delta,
    required String note,
  }) async {
    final json = await _api.correctStock(
      branchId: branchId,
      stockItemId: stockItemId,
      delta: delta,
      note: note,
    );
    return _maybeEntry(json, fallbackReason: InventoryJournalReason.add);
  }

  Future<List<InventoryJournalEntry>> fetch({
    String? stockItemId,
    InventoryJournalReason? reason,
    String? fromDate,
    String? toDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    final items = await _api.fetchJournal(
      stockItemId: stockItemId,
      reason: reason != null ? _reasonToApi(reason) : null,
      fromDate: fromDate,
      toDate: toDate,
      page: page,
      pageSize: pageSize,
    );
    return items
        .whereType<Map<String, dynamic>>()
        .map(InventoryJournalEntry.fromJson)
        .toList();
  }

  Future<List<InventoryJournalEntry>> lowStockAlerts() async {
    final items = await _api.fetchLowStockAlerts();
    return items
        .whereType<Map<String, dynamic>>()
        .map(InventoryJournalEntry.fromJson)
        .toList();
  }

  InventoryJournalEntry? _maybeEntry(
    Map<String, dynamic> json, {
    InventoryJournalReason? fallbackReason,
  }) {
    if (json['data'] is Map<String, dynamic>) {
      return InventoryJournalEntry.fromJson(
        json['data'] as Map<String, dynamic>,
        fallbackReason: fallbackReason,
      );
    }
    if (json.isNotEmpty) {
      return InventoryJournalEntry.fromJson(
        json,
        fallbackReason: fallbackReason,
      );
    }
    return null;
  }

  String _reasonToApi(InventoryJournalReason reason) => switch (reason) {
        InventoryJournalReason.restock => 'receive',
        InventoryJournalReason.add => 'receive',
        InventoryJournalReason.remove => 'waste',
        InventoryJournalReason.sale => 'sale',
        InventoryJournalReason.voided => 'void',
        InventoryJournalReason.reopen => 'reopen',
        InventoryJournalReason.unknown => '',
      };
}
