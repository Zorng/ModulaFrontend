import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final stockItemRepositoryProvider = Provider<StockItemRepository>((ref) {
  final api = ref.watch(inventoryApiProvider);
  return StockItemRepository(api);
});

class StockItemRepository {
  const StockItemRepository(this._api);

  final InventoryApi _api;

  Future<List<dynamic>> fetchOnHand({String? branchId}) {
    return _api.fetchOnHand(branchId: branchId);
  }

  Future<List<StockItem>> fetchStockItems({String? branchId}) async {
    // Always fetch master items so we can hydrate unit/piece info.
    final masterRaw = await _api.fetchStockItems(pageSize: 200);
    final master = masterRaw.whereType<Map<String, dynamic>>().toList();
    final masterById = {for (final m in master) _primaryId(m): m};

    final branchData = await _api.fetchBranchStockItems(branchId: branchId);

    // If a branch is explicitly requested, only show items returned for that branch.
    final data = (branchId != null && branchId.isNotEmpty)
        ? branchData
        : (branchData.isNotEmpty ? branchData : master);

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => _normalizeBranchStock(json, branchIdHint: branchId))
        .map((json) {
          final id = _primaryId(json);
          final base = masterById[id];
          if (base == null) return json;
          // Merge base unit/piece/category info from master if missing.
          final merged = Map<String, dynamic>.from(base)..addAll(json);
          // Ensure we keep the real stock item id (from master) instead of branch assignment id.
          merged['id'] = _primaryId(base);
          return merged;
        })
        .map(StockItem.fromJson)
        .toList();
  }

  /// Fetch only the master stock items (no branch assignment overlay).
  Future<List<StockItem>> fetchMasterStockItems({int pageSize = 200}) async {
    final masterRaw = await _api.fetchStockItems(pageSize: pageSize);
    return masterRaw
        .whereType<Map<String, dynamic>>()
        .map(StockItem.fromJson)
        .toList();
  }

  Future<StockItem> createStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final body = {
      'name': item.name,
      'unitText': item.baseUnit,
      'pieceSize': item.pieceSize,
      if (item.categoryId != null && item.categoryId!.isNotEmpty)
        'categoryId': item.categoryId,
      if (item.barcode != null && item.barcode!.isNotEmpty) 'barcode': item.barcode,
      'isActive': item.isActive,
    };
    final json = await _api.createStockItem(
      body,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    return StockItem.fromJson(_unwrap(json, fallback: item));
  }

  Future<StockItem> updateStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final body = {
      'name': item.name,
      'unitText': item.baseUnit,
      'pieceSize': item.pieceSize,
      'isActive': item.isActive,
      if (item.categoryId != null && item.categoryId!.isNotEmpty)
        'categoryId': item.categoryId,
      if (item.barcode != null && item.barcode!.isNotEmpty) 'barcode': item.barcode,
    };
    final json = await _api.updateStockItem(
      item.id,
      body,
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    return StockItem.fromJson(_unwrap(json, fallback: item));
  }

  Future<void> deleteStockItem(String id) => _api.deactivateStockItem(id);

  Future<void> assignToBranch({
    required String stockItemId,
    required String branchId,
    required int minThreshold,
  }) async {
    await _api.assignStockItemToBranch(
      stockItemId: stockItemId,
      branchId: branchId,
      minThreshold: minThreshold,
    );
    // Response is informational; local state is updated by the caller.
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> json, {StockItem? fallback}) {
    if (json['data'] is Map<String, dynamic>) return json['data'] as Map<String, dynamic>;
    if (json.isNotEmpty) return json;
    return fallback?.toJson() ?? {};
  }

  Map<String, dynamic> _normalizeBranchStock(
    Map<String, dynamic> json, {
    String? branchIdHint,
  }) {
    // Branch stock endpoint may wrap stock item details under a key.
    if (json.containsKey('stockItem') && json['stockItem'] is Map<String, dynamic>) {
      final item = Map<String, dynamic>.from(json['stockItem'] as Map<String, dynamic>);
      final onHand = json['onHand'] ?? json['qty'] ?? json['quantity'];
      String? branchId = json['branchId'] ?? json['branch_id'];
      String? branchName = json['branchName'] ?? json['branch_name'];
      final minThreshold = json['minThreshold'] ?? json['threshold'];
      if (onHand != null) item['onHand'] = onHand;
      final hasBranchId =
          branchId != null && branchId.toString().isNotEmpty;
      if (hasBranchId) {
        item['branchId'] = branchId;
      } else if (branchIdHint != null && branchIdHint.isNotEmpty) {
        item['branchId'] = branchIdHint;
        branchId = branchIdHint;
      }
      if (branchName != null && branchName.toString().isNotEmpty) {
        item['branchName'] = branchName;
      } else if (branchIdHint != null && branchIdHint.isNotEmpty) {
        item['branchName'] = '';
      }
      if (minThreshold != null) item['minThreshold'] = minThreshold;
      return item;
    }
    final branchIdValue = json['branchId'] ?? json['branch_id'];
    if ((branchIdValue == null || branchIdValue.toString().isEmpty) &&
        branchIdHint != null &&
        branchIdHint.isNotEmpty) {
      json = Map<String, dynamic>.from(json);
      json['branchId'] = branchIdHint;
    }
    return json;
  }

  String _primaryId(Map<String, dynamic> json) {
    return (json['stockItemId'] ??
            json['stock_item_id'] ??
            json['id'] ??
            '')
        .toString();
  }
}
