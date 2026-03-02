import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/dto/inventory_journal_entry_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';

final remoteInventoryJournalRepositoryProvider =
    Provider<InventoryJournalRepository>((ref) {
      final api = ref.watch(inventoryApiProvider);
      return RemoteInventoryJournalRepository(api);
    });

class RemoteInventoryJournalRepository extends InventoryJournalRepository {
  const RemoteInventoryJournalRepository(this._api);

  final InventoryApi _api;

  @override
  Future<InventoryJournalEntry?> receive({
    required String branchId,
    required String stockItemId,
    required num qty,
    String? note,
    String? occurredAt,
  }) async {
    final dto = await _api.receiveStock(
      branchId: branchId,
      stockItemId: stockItemId,
      qty: qty,
      note: note,
      occurredAt: occurredAt,
    );
    return _maybeEntry(dto, fallbackReason: InventoryJournalReason.restock);
  }

  @override
  Future<InventoryJournalEntry?> waste({
    required String branchId,
    required String stockItemId,
    required num qty,
    required String note,
    String? occurredAt,
  }) async {
    final dto = await _api.wasteStock(
      branchId: branchId,
      stockItemId: stockItemId,
      qty: qty,
      note: note,
      occurredAt: occurredAt,
    );
    return _maybeEntry(dto, fallbackReason: InventoryJournalReason.remove);
  }

  @override
  Future<InventoryJournalEntry?> correct({
    required String branchId,
    required String stockItemId,
    required num delta,
    required String note,
    String? occurredAt,
  }) async {
    final dto = await _api.correctStock(
      branchId: branchId,
      stockItemId: stockItemId,
      delta: delta,
      note: note,
      occurredAt: occurredAt,
    );
    return _maybeEntry(dto, fallbackReason: InventoryJournalReason.add);
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
    final items = await _api.fetchJournal(
      branchId: branchId,
      stockItemId: stockItemId,
      reason: reason != null ? _reasonToApi(reason) : null,
      fromDate: fromDate,
      toDate: toDate,
      page: page,
      pageSize: pageSize,
    );
    return items.map((dto) => _toDomain(dto)).toList(growable: false);
  }

  @override
  Future<List<InventoryJournalEntry>> lowStockAlerts({String? branchId}) async {
    final items = await _api.fetchLowStockAlerts(branchId: branchId);
    return items.map(_toDomain).toList(growable: false);
  }

  InventoryJournalEntry? _maybeEntry(
    InventoryJournalEntryDto? dto, {
    InventoryJournalReason? fallbackReason,
  }) {
    if (dto == null) return null;
    return _toDomain(dto, fallbackReason: fallbackReason);
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

InventoryJournalEntry _toDomain(
  InventoryJournalEntryDto dto, {
  InventoryJournalReason? fallbackReason,
}) {
  final reason = _reasonFromApi(dto.reason, fallback: fallbackReason);
  final actor = dto.actorName.isNotEmpty ? dto.actorName : dto.actorId;
  return InventoryJournalEntry(
    id: dto.id,
    itemId: dto.stockItemId,
    itemName: dto.stockItemName,
    branchId: dto.branchId,
    branchName: dto.branchName,
    reason: reason,
    delta: dto.delta,
    note: dto.note,
    actor: actor,
    createdAt: dto.createdAt,
    occurredAt: dto.occurredAt,
  );
}

InventoryJournalReason _reasonFromApi(
  String reason, {
  InventoryJournalReason? fallback,
}) {
  switch (reason.trim().toLowerCase()) {
    case 'receive':
    case 'restock':
      return InventoryJournalReason.restock;
    case 'waste':
      return InventoryJournalReason.remove;
    case 'sale':
      return InventoryJournalReason.sale;
    case 'void':
      return InventoryJournalReason.voided;
    case 'reopen':
      return InventoryJournalReason.reopen;
    default:
      return fallback ?? InventoryJournalReason.unknown;
  }
}
