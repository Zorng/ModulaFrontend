import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/dto/inventory_journal_entry_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/restock_batch_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';

final remoteInventoryJournalRepositoryProvider =
    Provider<InventoryJournalRepository>((ref) {
      final api = ref.watch(inventoryApiProvider);
      return RemoteInventoryJournalRepository(api);
    });

class RemoteInventoryJournalRepository extends InventoryJournalRepository {
  const RemoteInventoryJournalRepository(this._api);

  final InventoryApi _api;

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
    final dto = await _api.createRestockBatch(
      branchId: branchId,
      stockItemId: stockItemId,
      quantityInBaseUnit: qty.toInt(),
      receivedAt: receivedAt,
      expiryDate: expiryDate,
      supplierName: supplierName,
      purchaseCostUsd: purchaseCostUsd,
      note: note,
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
  Future<int?> applyAdjustment({
    required String branchId,
    required String stockItemId,
    required String style,
    int? deltaInBaseUnit,
    int? countedOnHandInBaseUnit,
    required String reasonCode,
    String? note,
  }) {
    return _api.applyAdjustment(
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
  Future<List<InventoryJournalEntry>> fetch({
    String? branchId,
    bool tenantWide = false,
    String? stockItemId,
    InventoryJournalReason? reason,
    int limit = 50,
    int offset = 0,
  }) async {
    final normalizedBranchId =
        (branchId ?? '').trim().isEmpty ? null : branchId?.trim();
    final items = tenantWide || normalizedBranchId == null
        ? await _api.fetchTenantJournal(
            branchId: tenantWide ? normalizedBranchId : null,
            stockItemId: stockItemId,
            reasonCode: reason != null ? _reasonToApi(reason) : null,
            limit: limit,
            offset: offset,
          )
        : await _api.fetchJournal(
            branchId: normalizedBranchId,
            stockItemId: stockItemId,
            reasonCode: reason != null ? _reasonToApi(reason) : null,
            limit: limit,
            offset: offset,
          );
    return items.map((dto) => _toDomain(dto)).toList(growable: false);
  }

  @override
  Future<List<InventoryJournalEntry>> lowStockAlerts({String? branchId}) async {
    final items = await _api.fetchLowStockAlerts(branchId: branchId);
    return items.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<StockBatch>> fetchRestockBatches({
    String? branchId,
    String status = 'all',
    String? stockItemId,
    int? limit,
    int? offset,
  }) async {
    final rows = await _api.fetchRestockBatches(
      branchId: branchId,
      status: status,
      stockItemId: stockItemId,
      limit: limit,
      offset: offset,
    );
    return rows.map(_toBatch).toList(growable: false);
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
    final dto = await _api.updateRestockBatchMetadata(
      batchId: batchId,
      branchId: branchId,
      expiryDate: expiryDate,
      supplierName: supplierName,
      purchaseCostUsd: purchaseCostUsd,
      note: note,
    );
    return _toBatch(dto);
  }

  @override
  Future<void> archiveRestockBatch({
    required String batchId,
    required String branchId,
  }) {
    return _api.archiveRestockBatch(batchId: batchId, branchId: branchId);
  }

  InventoryJournalEntry? _maybeEntry(
    InventoryJournalEntryDto? dto, {
    InventoryJournalReason? fallbackReason,
  }) {
    if (dto == null) return null;
    return _toDomain(dto, fallbackReason: fallbackReason);
  }

  String _reasonToApi(InventoryJournalReason reason) => switch (reason) {
    InventoryJournalReason.restock => 'RESTOCK',
    InventoryJournalReason.add => 'ADJUSTMENT',
    InventoryJournalReason.remove => 'ADJUSTMENT',
    InventoryJournalReason.sale => 'SALE_DEDUCTION',
    InventoryJournalReason.voided => 'VOID_REVERSAL',
    InventoryJournalReason.reopen => 'OTHER',
    InventoryJournalReason.unknown => 'OTHER',
  };
}

StockBatch _toBatch(RestockBatchDto dto) {
  return StockBatch(
    id: dto.id,
    stockItemId: dto.stockItemId,
    branchId: dto.branchId,
    onHand: dto.quantityInBaseUnit,
    receivedDate: _toDateOnly(dto.receivedAt),
    expiryDate: dto.expiryDate,
  );
}

InventoryJournalEntry _toDomain(
  InventoryJournalEntryDto dto, {
  InventoryJournalReason? fallbackReason,
}) {
  final reason = _reasonFromApi(
    dto.reason,
    delta: dto.delta,
    fallback: fallbackReason,
  );
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

String _toDateOnly(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) {
    final date = parsed.toUtc();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
  final normalized = raw.trim();
  if (normalized.contains('T')) {
    return normalized.split('T').first;
  }
  return normalized;
}

InventoryJournalReason _reasonFromApi(
  String reason, {
  required int delta,
  InventoryJournalReason? fallback,
}) {
  switch (reason.trim().toLowerCase()) {
    case 'restock':
    case 'receive':
      return InventoryJournalReason.restock;
    case 'adjustment':
      return delta < 0
          ? InventoryJournalReason.remove
          : InventoryJournalReason.add;
    case 'waste':
      return InventoryJournalReason.remove;
    case 'sale_deduction':
    case 'sale':
      return InventoryJournalReason.sale;
    case 'void_reversal':
    case 'void':
      return InventoryJournalReason.voided;
    case 'reopen':
      return InventoryJournalReason.reopen;
    case 'other':
      return InventoryJournalReason.unknown;
    default:
      return fallback ?? InventoryJournalReason.unknown;
  }
}
