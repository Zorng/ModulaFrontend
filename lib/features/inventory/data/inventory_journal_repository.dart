import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/mock_inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/data/remote_inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart'
    show useMockInventoryRepositoryProvider;
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';

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

  Future<InventoryJournalEntry?> receive({
    required String branchId,
    required String stockItemId,
    required num qty,
    String? note,
    String? occurredAt,
  });

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

  Future<List<InventoryJournalEntry>> fetch({
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
    String? fromDate,
    String? toDate,
    int page = 1,
    int pageSize = 50,
  });

  Future<List<InventoryJournalEntry>> lowStockAlerts({String? branchId});
}
