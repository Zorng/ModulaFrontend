import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/inventory/data/dto/branch_stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/inventory_category_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/inventory_journal_entry_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/on_hand_record_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';

final inventoryApiProvider = Provider<InventoryApi>((ref) {
  final dio = ref.watch(dioProvider);
  return InventoryApi(dio);
});

class InventoryApi {
  InventoryApi(this._dio)
      : _prefix = dotenv.env['INVENTORY_API_PREFIX'] ?? '/v1/inventory';

  final Dio _dio;
  final String _prefix;

  // Categories
  Future<List<InventoryCategoryDto>> fetchCategories({bool? isActive}) async {
    final query = <String, dynamic>{
      if (isActive != null) 'isActive': isActive,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/categories',
      queryParameters: query.isEmpty ? null : query,
    );
    final root = _asMap(response.data);
    final list = _pickList(root);
    return list.map(InventoryCategoryDto.fromJson).toList(growable: false);
  }

  Future<InventoryCategoryDto> createCategory(Map<String, dynamic> body) async {
    final response =
        await _dio.post<Map<String, dynamic>>('$_prefix/categories', data: body);
    final json = _unwrap(_asMap(response.data));
    return InventoryCategoryDto.fromJson(json);
  }

  Future<InventoryCategoryDto> updateCategory(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _dio.patch<Map<String, dynamic>>('$_prefix/categories/$id', data: body);
    final json = _unwrap(_asMap(response.data));
    return InventoryCategoryDto.fromJson(json);
  }

  Future<void> deleteCategory(String id, {bool? safeMode}) async {
    await _dio.delete(
      '$_prefix/categories/$id',
      queryParameters: safeMode == null ? null : {'safeMode': safeMode},
    );
  }

  // Stock items (master)
  Future<List<StockItemDto>> fetchStockItems({
    String? search,
    bool? isActive,
    String? categoryId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (isActive != null) 'isActive': isActive,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
    };
    final response =
        await _dio.get<Map<String, dynamic>>('$_prefix/stock-items', queryParameters: query);
    final root = _asMap(response.data);
    final list = _pickList(root);
    return list.map(StockItemDto.fromJson).toList(growable: false);
  }

  Future<StockItemDto> createStockItem(
    Map<String, dynamic> body, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    MultipartFile? imageFile;
    if (imageBytes != null) {
      imageFile = MultipartFile.fromBytes(imageBytes, filename: 'stock-item.jpg');
    } else if (imagePath != null && imagePath.isNotEmpty) {
      imageFile = await MultipartFile.fromFile(imagePath);
    }
    final payload = imageFile != null
        ? FormData.fromMap({
            ...body,
            'image': imageFile,
          })
        : FormData.fromMap(body);
    final response =
        await _dio.post<Map<String, dynamic>>('$_prefix/stock-items', data: payload);
    final json = _unwrap(_asMap(response.data));
    return StockItemDto.fromJson(json);
  }

  Future<StockItemDto> updateStockItem(
    String id,
    Map<String, dynamic> body, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    MultipartFile? imageFile;
    if (imageBytes != null) {
      imageFile = MultipartFile.fromBytes(imageBytes, filename: 'stock-item.jpg');
    } else if (imagePath != null && imagePath.isNotEmpty) {
      imageFile = await MultipartFile.fromFile(imagePath);
    }
    final payload = imageFile != null
        ? FormData.fromMap({
            ...body,
            'image': imageFile,
          })
        : FormData.fromMap(body);
    final response =
        await _dio.patch<Map<String, dynamic>>('$_prefix/stock-items/$id', data: payload);
    final json = _unwrap(_asMap(response.data));
    return StockItemDto.fromJson(json);
  }

  Future<void> deactivateStockItem(String id) async {
    await _dio.put<Map<String, dynamic>>('$_prefix/stock-items/$id', data: {'isActive': false});
  }

  Future<List<BranchStockItemDto>> fetchBranchStockItems({String? branchId}) async {
    final response =
        await _dio.get<Map<String, dynamic>>(
      '$_prefix/branch/stock-items',
      queryParameters: branchId == null || branchId.isEmpty
          ? null
          : <String, dynamic>{'branchId': branchId},
    );
    final root = _asMap(response.data);
    final list = _pickList(root);
    return list
        .map((json) => BranchStockItemDto.fromJson(json, branchIdHint: branchId))
        .toList(growable: false);
  }

  Future<void> assignStockItemToBranch({
    required String stockItemId,
    required String branchId,
    required int minThreshold,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '$_prefix/branch/stock-items',
      data: {
        'stockItemId': stockItemId,
        'branchId': branchId,
        'minThreshold': minThreshold,
      },
    );
  }

  Future<List<OnHandRecordDto>> fetchOnHand({String? branchId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/branch/on-hand',
      queryParameters: branchId == null || branchId.isEmpty
          ? null
          : <String, dynamic>{'branchId': branchId},
    );
    final root = _asMap(response.data);
    final list = _pickList(root);
    return list
        .map((json) => OnHandRecordDto.fromJson(json, branchIdHint: branchId))
        .toList(growable: false);
  }

  // Inventory journal / stock movements
  Future<InventoryJournalEntryDto?> receiveStock({
    required String branchId,
    required String stockItemId,
    required num qty,
    String? note,
    String? occurredAt,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/journal/receive',
      data: {
        'branchId': branchId,
        'stockItemId': stockItemId,
        'qty': qty,
        if (note != null && note.isNotEmpty) 'note': note,
        if (occurredAt != null && occurredAt.isNotEmpty) 'occurredAt': occurredAt,
      },
    );
    return _maybeJournalEntry(response.data);
  }

  Future<InventoryJournalEntryDto?> wasteStock({
    required String branchId,
    required String stockItemId,
    required num qty,
    required String note,
    String? occurredAt,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/journal/waste',
      data: {
        'branchId': branchId,
        'stockItemId': stockItemId,
        'qty': qty,
        'note': note,
        if (occurredAt != null && occurredAt.isNotEmpty) 'occurredAt': occurredAt,
      },
    );
    return _maybeJournalEntry(response.data);
  }

  Future<InventoryJournalEntryDto?> correctStock({
    required String branchId,
    required String stockItemId,
    required num delta,
    required String note,
    String? occurredAt,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/journal/correct',
      data: {
        'branchId': branchId,
        'stockItemId': stockItemId,
        'delta': delta,
        'note': note,
        if (occurredAt != null && occurredAt.isNotEmpty) 'occurredAt': occurredAt,
      },
    );
    return _maybeJournalEntry(response.data);
  }

  Future<List<InventoryJournalEntryDto>> fetchJournal({
    String? branchId,
    String? stockItemId,
    String? reason,
    String? fromDate,
    String? toDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (stockItemId != null && stockItemId.isNotEmpty) 'stockItemId': stockItemId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/branch/journal',
      queryParameters: query,
    );
    final root = _asMap(response.data);
    final list = _pickList(root);
    return list.map(InventoryJournalEntryDto.fromJson).toList(growable: false);
  }

  Future<List<InventoryJournalEntryDto>> fetchLowStockAlerts({String? branchId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/branch/alerts/low-stock',
      queryParameters: branchId == null || branchId.isEmpty
          ? null
          : <String, dynamic>{'branchId': branchId},
    );
    final root = _asMap(response.data);
    final list = _pickList(root);
    return list.map(InventoryJournalEntryDto.fromJson).toList(growable: false);
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

Map<String, dynamic> _unwrap(Map<String, dynamic> root) {
  final inner = root['data'];
  if (root['success'] == true && inner is Map) {
    return _asMap(inner);
  }
  if (inner is Map<String, dynamic>) return inner;
  return root;
}

List<Map<String, dynamic>> _pickList(Map<String, dynamic> root) {
  final value = _extractListValue(root);
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => _asMap(e))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

dynamic _extractListValue(Map<String, dynamic> root) {
  if (root['data'] is List) return root['data'];
  if (root['items'] is List) return root['items'];
  if (root['entries'] is List) return root['entries'];
  if (root['data'] is Map) {
    final inner = _asMap(root['data']);
    final nested = _extractListValue(inner);
    if (nested != null) return nested;
  }
  return null;
}

InventoryJournalEntryDto? _maybeJournalEntry(Map<String, dynamic>? payload) {
  final map = _asMap(payload);
  final json = _unwrap(map);
  if (json.isEmpty) return null;
  return InventoryJournalEntryDto.fromJson(json);
}
