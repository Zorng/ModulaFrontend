import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/on_hand_record.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final mockInventoryStoreProvider = Provider<MockInventoryStore>((ref) {
  return MockInventoryStore.seeded();
});

class MockInventoryStore {
  MockInventoryStore.seeded()
    : _branchNames = <String, String>{'mock-branch-1': 'Mock Branch 1'} {
    _seed();
  }

  final Map<String, String> _branchNames;
  final Map<String, InventoryCategory> _categories =
      <String, InventoryCategory>{};
  final Map<String, StockItem> _items = <String, StockItem>{};
  final Map<String, _StockPosition> _positions = <String, _StockPosition>{};
  final Map<String, _StoredBatch> _batches = <String, _StoredBatch>{};
  final List<InventoryJournalEntry> _journal = <InventoryJournalEntry>[];

  int _nextCategoryId = 1;
  int _nextStockItemId = 1;
  int _nextBatchId = 1;
  int _nextJournalId = 1;

  List<InventoryCategory> fetchCategories({String status = 'all'}) {
    final normalizedStatus = _normalizeStatus(status);
    return _categories.values
        .where(
          (category) => _matchesStatus(category.isActive, normalizedStatus),
        )
        .toList(growable: false);
  }

  InventoryCategory createCategory(InventoryCategory category) {
    final normalizedName = category.name.trim();
    if (normalizedName.isEmpty) {
      throw const ApiClientException(
        message: 'Category name is required.',
        code: 'INVENTORY_QUANTITY_INVALID',
        statusCode: 422,
      );
    }
    if (_hasCategoryNameConflict(normalizedName)) {
      throw const ApiClientException(
        message: 'Category name already exists.',
        code: 'INVENTORY_STOCK_CATEGORY_DUPLICATE_NAME',
        statusCode: 409,
      );
    }
    final created = category.copyWith(
      id: category.id.isNotEmpty
          ? category.id
          : _nextId('mock-category', _nextCategoryId++),
      name: normalizedName,
      isActive: category.isActive,
    );
    _categories[created.id] = created;
    return created;
  }

  InventoryCategory updateCategory(InventoryCategory category) {
    final current = _categories[category.id];
    if (current == null) {
      throw const ApiClientException(
        message: 'Category no longer exists.',
        code: 'INVENTORY_STOCK_CATEGORY_NOT_FOUND',
        statusCode: 404,
      );
    }
    final normalizedName = category.name.trim();
    if (normalizedName.isEmpty) {
      throw const ApiClientException(
        message: 'Category name is required.',
        code: 'INVENTORY_QUANTITY_INVALID',
        statusCode: 422,
      );
    }
    if (_hasCategoryNameConflict(normalizedName, excludeId: category.id)) {
      throw const ApiClientException(
        message: 'Category name already exists.',
        code: 'INVENTORY_STOCK_CATEGORY_DUPLICATE_NAME',
        statusCode: 409,
      );
    }
    final updated = current.copyWith(
      name: normalizedName,
      isActive: category.isActive,
      description: category.description,
    );
    _categories[category.id] = updated;
    return updated;
  }

  void archiveCategory(String id) {
    final current = _categories[id];
    if (current == null) {
      throw const ApiClientException(
        message: 'Category no longer exists.',
        code: 'INVENTORY_STOCK_CATEGORY_NOT_FOUND',
        statusCode: 404,
      );
    }
    _categories[id] = current.copyWith(isActive: false);
    for (final entry in _items.entries) {
      final item = entry.value;
      if (item.categoryId == id) {
        _items[entry.key] = item.copyWith(categoryId: null);
      }
    }
  }

  List<StockItem> fetchMasterStockItems({int pageSize = 200}) {
    return _items.values.take(pageSize).toList(growable: false);
  }

  StockItem fetchStockItemById(String id) {
    final item = _items[id];
    if (item == null) {
      throw const ApiClientException(
        message: 'Stock item no longer exists.',
        code: 'INVENTORY_STOCK_ITEM_NOT_FOUND',
        statusCode: 404,
      );
    }
    return item;
  }

  StockItem createStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) {
    final normalizedName = item.name.trim();
    if (normalizedName.isEmpty) {
      throw const ApiClientException(
        message: 'Stock item name is required.',
        code: 'INVENTORY_QUANTITY_INVALID',
        statusCode: 422,
      );
    }
    if (_hasStockItemNameConflict(normalizedName)) {
      throw const ApiClientException(
        message: 'Stock item name already exists.',
        code: 'INVENTORY_STOCK_ITEM_DUPLICATE_NAME',
        statusCode: 409,
      );
    }
    final categoryId = _sanitizeCategoryId(item.categoryId);
    final id = item.id.isNotEmpty
        ? item.id
        : _nextId('mock-stock-item', _nextStockItemId++);
    final created = StockItem(
      id: id,
      name: normalizedName,
      categoryId: categoryId,
      baseUnit: item.baseUnit,
      pieceSize: item.pieceSize <= 0 ? 1 : item.pieceSize,
      branchId: '',
      branchName: '',
      onHand: 0,
      minThreshold: item.minThreshold < 0 ? 0 : item.minThreshold,
      isActive: item.isActive,
      imageUrl: _resolveImageUrl(
        id: id,
        current: item.imageUrl,
        imagePath: imagePath,
        imageBytes: imageBytes,
      ),
    );
    _items[id] = created;
    return created;
  }

  StockItem updateStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) {
    final current = _items[item.id];
    if (current == null) {
      throw const ApiClientException(
        message: 'Stock item no longer exists.',
        code: 'INVENTORY_STOCK_ITEM_NOT_FOUND',
        statusCode: 404,
      );
    }
    final normalizedName = item.name.trim();
    if (normalizedName.isEmpty) {
      throw const ApiClientException(
        message: 'Stock item name is required.',
        code: 'INVENTORY_QUANTITY_INVALID',
        statusCode: 422,
      );
    }
    if (_hasStockItemNameConflict(normalizedName, excludeId: item.id)) {
      throw const ApiClientException(
        message: 'Stock item name already exists.',
        code: 'INVENTORY_STOCK_ITEM_DUPLICATE_NAME',
        statusCode: 409,
      );
    }
    final updatedMaster = current.copyWith(
      name: normalizedName,
      categoryId: _sanitizeCategoryId(item.categoryId),
      baseUnit: item.baseUnit,
      pieceSize: item.pieceSize <= 0 ? 1 : item.pieceSize,
      minThreshold: item.minThreshold < 0 ? 0 : item.minThreshold,
      isActive: item.isActive,
      imageUrl: _resolveImageUrl(
        id: item.id,
        current: item.imageUrl ?? current.imageUrl,
        imagePath: imagePath,
        imageBytes: imageBytes,
      ),
    );
    _items[item.id] = updatedMaster;
    return updatedMaster.copyWith(
      branchId: item.branchId,
      branchName: item.branchName,
      onHand: item.onHand,
    );
  }

  void archiveStockItem(String id) {
    final current = _items[id];
    if (current == null) {
      throw const ApiClientException(
        message: 'Stock item no longer exists.',
        code: 'INVENTORY_STOCK_ITEM_NOT_FOUND',
        statusCode: 404,
      );
    }
    _items[id] = current.copyWith(isActive: false);
  }

  void restoreStockItem(String id) {
    final current = _items[id];
    if (current == null) {
      throw const ApiClientException(
        message: 'Stock item no longer exists.',
        code: 'INVENTORY_STOCK_ITEM_NOT_FOUND',
        statusCode: 404,
      );
    }
    _items[id] = current.copyWith(isActive: true);
  }

  List<StockItem> fetchInventoryStockItems({
    String? branchId,
    String status = 'all',
  }) {
    final normalizedStatus = _normalizeStatus(status);
    final targetBranch = _normalizeBranch(branchId);
    if (targetBranch != null) {
      _ensureValidBranch(targetBranch);
      return _positions.values
          .where((position) => position.branchId == targetBranch)
          .map((position) => _toInventoryItem(position, targetBranch))
          .where((item) => _matchesStatus(item.isActive, normalizedStatus))
          .toList(growable: false);
    }

    final totals = <String, int>{};
    for (final position in _positions.values) {
      totals[position.stockItemId] =
          (totals[position.stockItemId] ?? 0) + position.onHand;
    }
    return totals.entries
        .map((entry) {
          final item = _items[entry.key];
          if (item == null) return null;
          return item.copyWith(
            branchId: '',
            branchName: '',
            onHand: entry.value,
            minThreshold: item.minThreshold,
          );
        })
        .whereType<StockItem>()
        .where((item) => _matchesStatus(item.isActive, normalizedStatus))
        .toList(growable: false);
  }

  List<OnHandRecord> fetchOnHand({
    required String branchId,
    String status = 'all',
  }) {
    _ensureValidBranch(branchId);
    final normalizedStatus = _normalizeStatus(status);
    return _positions.values
        .where((position) => position.branchId == branchId)
        .where((position) {
          final item = _items[position.stockItemId];
          if (item == null) return false;
          return _matchesStatus(item.isActive, normalizedStatus);
        })
        .map(
          (position) => OnHandRecord(
            stockItemId: position.stockItemId,
            branchId: branchId,
            onHand: position.onHand,
            minThreshold: _items[position.stockItemId]?.minThreshold ?? 0,
          ),
        )
        .toList(growable: false);
  }

  InventoryJournalEntry? createRestockBatch({
    required String branchId,
    required String stockItemId,
    required num qty,
    String? note,
    String? receivedAt,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
  }) {
    _ensureValidBranch(branchId);
    final item = _requireActiveItem(stockItemId);
    final quantity = qty.toInt();
    if (quantity <= 0) {
      throw const ApiClientException(
        message: 'Restock quantity must be greater than zero.',
        code: 'INVENTORY_QUANTITY_INVALID',
        statusCode: 422,
      );
    }

    final batchId = _nextId('mock-batch', _nextBatchId++);
    final receivedDate = _toDateOnly(receivedAt);
    _batches[batchId] = _StoredBatch(
      id: batchId,
      stockItemId: stockItemId,
      branchId: branchId,
      onHand: quantity,
      receivedDate: receivedDate,
      expiryDate: _normalizeOptionalDate(expiryDate),
      supplierName: _normalizeOptionalText(supplierName),
      purchaseCostUsd: purchaseCostUsd,
      note: _normalizeOptionalText(note),
      isArchived: false,
    );

    final key = _positionKey(stockItemId, branchId);
    final current = _positions[key];
    _positions[key] = _StockPosition(
      stockItemId: stockItemId,
      branchId: branchId,
      onHand: (current?.onHand ?? 0) + quantity,
    );

    final entry = _appendJournal(
      stockItemId: stockItemId,
      branchId: branchId,
      delta: quantity,
      reason: InventoryJournalReason.restock,
      note: note,
      occurredAt: receivedAt,
      itemName: item.name,
    );
    return entry;
  }

  int? applyAdjustment({
    required String branchId,
    required String stockItemId,
    required String style,
    int? deltaInBaseUnit,
    int? countedOnHandInBaseUnit,
    required String reasonCode,
    String? note,
  }) {
    _ensureValidBranch(branchId);
    final item = _requireActiveItem(stockItemId);
    final key = _positionKey(stockItemId, branchId);
    final current = _positions[key]?.onHand ?? 0;
    final normalizedStyle = style.trim().toUpperCase();
    final normalizedReasonCode = reasonCode.trim().toUpperCase();

    late final int resultingOnHand;
    late final int delta;

    if (normalizedStyle == 'SET_TO_COUNT') {
      final counted = countedOnHandInBaseUnit;
      if (counted == null || counted < 0) {
        throw const ApiClientException(
          message: 'Counted on-hand quantity is invalid.',
          code: 'INVENTORY_QUANTITY_INVALID',
          statusCode: 422,
        );
      }
      resultingOnHand = counted;
      delta = counted - current;
    } else {
      final adjustment = deltaInBaseUnit;
      if (adjustment == null || adjustment == 0) {
        throw const ApiClientException(
          message: 'Adjustment quantity must be non-zero.',
          code: 'INVENTORY_ADJUSTMENT_INVALID',
          statusCode: 422,
        );
      }
      resultingOnHand = current + adjustment;
      delta = adjustment;
    }

    if (resultingOnHand < 0) {
      throw const ApiClientException(
        message: 'Adjustment exceeds available quantity.',
        code: 'INVENTORY_QUANTITY_INVALID',
        statusCode: 422,
      );
    }

    if (_positions.containsKey(key) || resultingOnHand > 0) {
      _positions[key] = _StockPosition(
        stockItemId: stockItemId,
        branchId: branchId,
        onHand: resultingOnHand,
      );
    }

    if (delta != 0) {
      _appendJournal(
        stockItemId: stockItemId,
        branchId: branchId,
        delta: delta,
        reason: _reasonFromAdjustment(
          reasonCode: normalizedReasonCode,
          delta: delta,
        ),
        note: note,
        occurredAt: null,
        itemName: item.name,
      );
    }

    return resultingOnHand;
  }

  List<InventoryJournalEntry> fetchJournal({
    String? branchId,
    bool tenantWide = false,
    String? stockItemId,
    InventoryJournalReason? reason,
    DateTime? date,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) {
    final normalizedBranch = _normalizeBranch(branchId);
    if (normalizedBranch != null) {
      _ensureValidBranch(normalizedBranch);
    }
    final filtered =
        _journal
            .where((entry) {
              final occurredDate = DateTime(
                entry.occurredAt.year,
                entry.occurredAt.month,
                entry.occurredAt.day,
              );
              if (normalizedBranch != null &&
                  entry.branchId != normalizedBranch) {
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
              if (date != null) {
                final targetDate = DateTime(date.year, date.month, date.day);
                if (occurredDate != targetDate) return false;
              } else {
                if (from != null) {
                  final startDate = DateTime(from.year, from.month, from.day);
                  if (occurredDate.isBefore(startDate)) return false;
                }
                if (to != null) {
                  final endDate = DateTime(to.year, to.month, to.day);
                  if (occurredDate.isAfter(endDate)) return false;
                }
              }
              return true;
            })
            .toList(growable: false)
          ..sort((left, right) => right.occurredAt.compareTo(left.occurredAt));

    return _page(filtered, limit: limit, offset: offset);
  }

  List<InventoryJournalEntry> lowStockAlerts({String? branchId}) {
    final targetBranch = _normalizeBranch(branchId);
    if (targetBranch != null) {
      _ensureValidBranch(targetBranch);
    }
    final now = DateTime.now();
    return fetchInventoryStockItems(branchId: targetBranch, status: 'active')
        .where((item) => item.isLowStock)
        .map(
          (item) => InventoryJournalEntry(
            id: 'mock-low-stock-${item.id}-${item.branchId}',
            itemId: item.id,
            itemName: item.name,
            branchId: item.branchId,
            branchName: item.branchName,
            reason: InventoryJournalReason.unknown,
            delta: 0,
            note: 'Low stock alert',
            actor: 'Mock System',
            createdAt: now,
            occurredAt: now,
          ),
        )
        .toList(growable: false);
  }

  List<StockBatch> fetchRestockBatches({
    String? branchId,
    String status = 'all',
    String? stockItemId,
    int? limit,
    int? offset,
  }) {
    final normalizedBranch = _normalizeBranch(branchId);
    if (normalizedBranch != null) {
      _ensureValidBranch(normalizedBranch);
    }
    final normalizedStatus = _normalizeStatus(status);
    final filtered =
        _batches.values
            .where((batch) {
              if (normalizedBranch != null &&
                  batch.branchId != normalizedBranch) {
                return false;
              }
              if (stockItemId != null &&
                  stockItemId.isNotEmpty &&
                  batch.stockItemId != stockItemId) {
                return false;
              }
              if (normalizedStatus == 'active' && batch.isArchived) {
                return false;
              }
              if (normalizedStatus == 'archived' && !batch.isArchived) {
                return false;
              }
              return true;
            })
            .toList(growable: false)
          ..sort(
            (left, right) => right.receivedDate.compareTo(left.receivedDate),
          );

    final paged = _page(filtered, limit: limit ?? 50, offset: offset ?? 0);
    return paged.map((batch) => batch.toDomain()).toList(growable: false);
  }

  StockBatch updateRestockBatchMetadata({
    required String batchId,
    required String branchId,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
    String? note,
  }) {
    _ensureValidBranch(branchId);
    final current = _batches[batchId];
    if (current == null || current.branchId != branchId) {
      throw const ApiClientException(
        message: 'Restock batch no longer exists.',
        code: 'INVENTORY_RESTOCK_BATCH_NOT_FOUND',
        statusCode: 404,
      );
    }
    if (current.isArchived) {
      throw const ApiClientException(
        message: 'This restock batch is archived and cannot be modified.',
        code: 'INVENTORY_RESTOCK_BATCH_ARCHIVED',
        statusCode: 409,
      );
    }
    final updated = current.copyWith(
      expiryDate: expiryDate == null
          ? current.expiryDate
          : _normalizeOptionalDate(expiryDate),
      supplierName: supplierName == null
          ? current.supplierName
          : _normalizeOptionalText(supplierName),
      purchaseCostUsd: purchaseCostUsd ?? current.purchaseCostUsd,
      note: note == null ? current.note : _normalizeOptionalText(note),
    );
    _batches[batchId] = updated;
    return updated.toDomain();
  }

  void archiveRestockBatch({
    required String batchId,
    required String branchId,
  }) {
    _ensureValidBranch(branchId);
    final current = _batches[batchId];
    if (current == null || current.branchId != branchId) {
      throw const ApiClientException(
        message: 'Restock batch no longer exists.',
        code: 'INVENTORY_RESTOCK_BATCH_NOT_FOUND',
        statusCode: 404,
      );
    }
    if (current.isArchived) {
      throw const ApiClientException(
        message: 'This restock batch is archived and cannot be modified.',
        code: 'INVENTORY_RESTOCK_BATCH_ARCHIVED',
        statusCode: 409,
      );
    }
    _batches[batchId] = current.copyWith(isArchived: true);
  }

  void _seed() {
    _categories['mock-category-dairy'] = const InventoryCategory(
      id: 'mock-category-dairy',
      name: 'Dairy',
      isActive: true,
    );
    _categories['mock-category-coffee'] = const InventoryCategory(
      id: 'mock-category-coffee',
      name: 'Coffee',
      isActive: true,
    );
    _categories['mock-category-sweetener'] = const InventoryCategory(
      id: 'mock-category-sweetener',
      name: 'Sweetener',
      isActive: true,
    );
    _categories['mock-category-packaging'] = const InventoryCategory(
      id: 'mock-category-packaging',
      name: 'Packaging',
      isActive: true,
    );
    _nextCategoryId = 5;

    _items['mock-stock-milk'] = const StockItem(
      id: 'mock-stock-milk',
      name: 'Whole Milk',
      categoryId: 'mock-category-dairy',
      baseUnit: 'ml',
      pieceSize: 1000,
      branchId: '',
      branchName: '',
      onHand: 0,
      minThreshold: 1500,
      isActive: true,
    );
    _items['mock-stock-beans'] = const StockItem(
      id: 'mock-stock-beans',
      name: 'Arabica Beans',
      categoryId: 'mock-category-coffee',
      baseUnit: 'g',
      pieceSize: 1000,
      branchId: '',
      branchName: '',
      onHand: 0,
      minThreshold: 500,
      isActive: true,
    );
    _items['mock-stock-syrup'] = const StockItem(
      id: 'mock-stock-syrup',
      name: 'Vanilla Syrup',
      categoryId: 'mock-category-sweetener',
      baseUnit: 'ml',
      pieceSize: 1000,
      branchId: '',
      branchName: '',
      onHand: 0,
      minThreshold: 750,
      isActive: true,
    );
    _items['mock-stock-cups'] = const StockItem(
      id: 'mock-stock-cups',
      name: 'Paper Cups',
      categoryId: 'mock-category-packaging',
      baseUnit: 'pcs',
      pieceSize: 1,
      branchId: '',
      branchName: '',
      onHand: 0,
      minThreshold: 200,
      isActive: true,
    );
    _nextStockItemId = 5;

    final beansBatchId = _seedRestockBatch(
      stockItemId: 'mock-stock-beans',
      branchId: 'mock-branch-1',
      qty: 1000,
      receivedAt: '2026-03-02',
      expiryDate: null,
      note: 'Opening stock',
    );
    _seedRestockBatch(
      stockItemId: 'mock-stock-milk',
      branchId: 'mock-branch-1',
      qty: 2400,
      receivedAt: '2026-03-08',
      expiryDate: '2026-03-18',
      note: 'Fresh delivery',
    );
    _seedRestockBatch(
      stockItemId: 'mock-stock-syrup',
      branchId: 'mock-branch-1',
      qty: 900,
      receivedAt: '2026-03-09',
      expiryDate: '2026-06-01',
      note: 'Weekly restock',
    );
    _seedAdjustment(
      stockItemId: 'mock-stock-beans',
      branchId: 'mock-branch-1',
      delta: -1000,
      reason: InventoryJournalReason.remove,
      note: 'Initial depletion',
      occurredAt: '2026-03-10',
      batchId: beansBatchId,
    );
  }

  String _seedRestockBatch({
    required String stockItemId,
    required String branchId,
    required int qty,
    required String receivedAt,
    required String? expiryDate,
    required String note,
  }) {
    final batchId = _nextId('mock-batch', _nextBatchId++);
    _batches[batchId] = _StoredBatch(
      id: batchId,
      stockItemId: stockItemId,
      branchId: branchId,
      onHand: qty,
      receivedDate: receivedAt,
      expiryDate: expiryDate,
      supplierName: 'Mock Supplier',
      purchaseCostUsd: null,
      note: note,
      isArchived: false,
    );
    final key = _positionKey(stockItemId, branchId);
    final current = _positions[key];
    _positions[key] = _StockPosition(
      stockItemId: stockItemId,
      branchId: branchId,
      onHand: (current?.onHand ?? 0) + qty,
    );
    _appendJournal(
      stockItemId: stockItemId,
      branchId: branchId,
      delta: qty,
      reason: InventoryJournalReason.restock,
      note: note,
      occurredAt: receivedAt,
      itemName: _items[stockItemId]?.name ?? stockItemId,
    );
    return batchId;
  }

  void _seedAdjustment({
    required String stockItemId,
    required String branchId,
    required int delta,
    required InventoryJournalReason reason,
    required String note,
    required String occurredAt,
    String? batchId,
  }) {
    final key = _positionKey(stockItemId, branchId);
    final current = _positions[key]?.onHand ?? 0;
    final next = current + delta;
    _positions[key] = _StockPosition(
      stockItemId: stockItemId,
      branchId: branchId,
      onHand: next < 0 ? 0 : next,
    );
    if (batchId != null && _batches.containsKey(batchId)) {
      _batches[batchId] = _batches[batchId]!.copyWith(
        onHand: next < 0 ? 0 : next,
      );
    }
    _appendJournal(
      stockItemId: stockItemId,
      branchId: branchId,
      delta: delta,
      reason: reason,
      note: note,
      occurredAt: occurredAt,
      itemName: _items[stockItemId]?.name ?? stockItemId,
    );
  }

  void _ensureValidBranch(String branchId) {
    if (!_branchNames.containsKey(branchId)) {
      throw const ApiClientException(
        message:
            'Selected branch no longer exists. Refresh branches and try again.',
        code: 'BRANCH_NOT_FOUND',
        statusCode: 404,
      );
    }
  }

  StockItem _requireActiveItem(String stockItemId) {
    final item = _items[stockItemId];
    if (item == null) {
      throw const ApiClientException(
        message: 'Stock item no longer exists.',
        code: 'INVENTORY_STOCK_ITEM_NOT_FOUND',
        statusCode: 404,
      );
    }
    if (!item.isActive) {
      throw const ApiClientException(
        message: 'This stock item is archived. Restore it before continuing.',
        code: 'INVENTORY_STOCK_ITEM_INACTIVE',
        statusCode: 409,
      );
    }
    return item;
  }

  StockItem _toInventoryItem(_StockPosition position, String branchId) {
    final item = _items[position.stockItemId]!;
    return item.copyWith(
      branchId: branchId,
      branchName: _branchNames[branchId] ?? '',
      onHand: position.onHand,
      minThreshold: item.minThreshold,
    );
  }

  InventoryJournalEntry _appendJournal({
    required String stockItemId,
    required String branchId,
    required int delta,
    required InventoryJournalReason reason,
    required String? note,
    required String? occurredAt,
    required String itemName,
  }) {
    final now = DateTime.now();
    final occurred = DateTime.tryParse(occurredAt ?? '') ?? now;
    final entry = InventoryJournalEntry(
      id: _nextId('mock-journal', _nextJournalId++),
      itemId: stockItemId,
      itemName: itemName,
      branchId: branchId,
      branchName: _branchNames[branchId] ?? '',
      reason: reason,
      delta: delta,
      note: note ?? '',
      actor: 'Mock User',
      createdAt: now,
      occurredAt: occurred,
    );
    _journal.insert(0, entry);
    return entry;
  }

  String? _sanitizeCategoryId(String? categoryId) {
    final normalized = _normalizeOptionalText(categoryId);
    if (normalized == null) return null;
    final category = _categories[normalized];
    if (category == null || !category.isActive) return null;
    return normalized;
  }

  bool _hasCategoryNameConflict(String name, {String? excludeId}) {
    final normalized = name.trim().toLowerCase();
    return _categories.values.any(
      (category) =>
          category.id != excludeId &&
          category.name.trim().toLowerCase() == normalized,
    );
  }

  bool _hasStockItemNameConflict(String name, {String? excludeId}) {
    final normalized = name.trim().toLowerCase();
    return _items.values.any(
      (item) =>
          item.id != excludeId && item.name.trim().toLowerCase() == normalized,
    );
  }

  String _normalizeStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
      case 'archived':
      case 'all':
        return status.trim().toLowerCase();
      default:
        return 'all';
    }
  }

  bool _matchesStatus(bool isActive, String status) {
    switch (status) {
      case 'active':
        return isActive;
      case 'archived':
        return !isActive;
      case 'all':
      default:
        return true;
    }
  }

  String? _normalizeBranch(String? branchId) {
    final normalized = (branchId ?? '').trim();
    if (normalized.isEmpty || normalized == 'all') return null;
    return normalized;
  }

  String? _normalizeOptionalText(String? value) {
    final normalized = (value ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? _normalizeOptionalDate(String? value) {
    final normalized = _normalizeOptionalText(value);
    if (normalized == null) return null;
    return _toDateOnly(normalized);
  }

  String _toDateOnly(String? raw) {
    final normalized = _normalizeOptionalText(raw);
    if (normalized == null) {
      return DateTime.now().toIso8601String().split('T').first;
    }
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) {
      return normalized.split('T').first;
    }
    return parsed.toUtc().toIso8601String().split('T').first;
  }

  String _resolveImageUrl({
    required String id,
    required String? current,
    String? imagePath,
    List<int>? imageBytes,
  }) {
    final normalizedPath = _normalizeOptionalText(imagePath);
    if (normalizedPath != null) return normalizedPath;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      return 'mock-image://$id';
    }
    return current ?? '';
  }

  List<T> _page<T>(List<T> items, {required int limit, required int offset}) {
    final safeLimit = limit <= 0 ? 50 : limit;
    final safeOffset = offset < 0 ? 0 : offset;
    if (safeOffset >= items.length) return <T>[];
    final end = (safeOffset + safeLimit).clamp(0, items.length);
    return items.sublist(safeOffset, end);
  }

  InventoryJournalReason _reasonFromAdjustment({
    required String reasonCode,
    required int delta,
  }) {
    switch (reasonCode) {
      case 'WASTE':
        return InventoryJournalReason.remove;
      case 'SALE_DEDUCTION':
        return InventoryJournalReason.sale;
      case 'VOID_REVERSAL':
        return InventoryJournalReason.voided;
      case 'COUNT_CORRECTION':
        return delta < 0
            ? InventoryJournalReason.remove
            : InventoryJournalReason.add;
      case 'RESTOCK':
        return InventoryJournalReason.restock;
      default:
        return delta < 0
            ? InventoryJournalReason.remove
            : InventoryJournalReason.add;
    }
  }

  String _positionKey(String stockItemId, String branchId) =>
      '$branchId::$stockItemId';

  String _nextId(String prefix, int value) => '$prefix-$value';
}

class _StockPosition {
  const _StockPosition({
    required this.stockItemId,
    required this.branchId,
    required this.onHand,
  });

  final String stockItemId;
  final String branchId;
  final int onHand;
}

class _StoredBatch {
  const _StoredBatch({
    required this.id,
    required this.stockItemId,
    required this.branchId,
    required this.onHand,
    required this.receivedDate,
    required this.expiryDate,
    required this.supplierName,
    required this.purchaseCostUsd,
    required this.note,
    required this.isArchived,
  });

  final String id;
  final String stockItemId;
  final String branchId;
  final int onHand;
  final String receivedDate;
  final String? expiryDate;
  final String? supplierName;
  final num? purchaseCostUsd;
  final String? note;
  final bool isArchived;

  _StoredBatch copyWith({
    int? onHand,
    String? receivedDate,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
    String? note,
    bool? isArchived,
  }) {
    return _StoredBatch(
      id: id,
      stockItemId: stockItemId,
      branchId: branchId,
      onHand: onHand ?? this.onHand,
      receivedDate: receivedDate ?? this.receivedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      supplierName: supplierName ?? this.supplierName,
      purchaseCostUsd: purchaseCostUsd ?? this.purchaseCostUsd,
      note: note ?? this.note,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  StockBatch toDomain() {
    return StockBatch(
      id: id,
      stockItemId: stockItemId,
      branchId: branchId,
      onHand: onHand,
      receivedDate: receivedDate,
      expiryDate: expiryDate,
    );
  }
}
