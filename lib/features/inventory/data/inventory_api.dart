import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';

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
  Future<List<dynamic>> fetchCategories({bool? isActive}) async {
    final query = <String, dynamic>{
      if (isActive != null) 'isActive': isActive,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/categories',
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response.data;
    if (data == null) return const [];
    if (data['data'] is List) return List<dynamic>.from(data['data'] as List);
    if (data['items'] is List) return List<dynamic>.from(data['items'] as List);
    return const [];
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> body) async {
    final response =
        await _dio.post<Map<String, dynamic>>('$_prefix/categories', data: body);
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateCategory(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _dio.patch<Map<String, dynamic>>('$_prefix/categories/$id', data: body);
    return response.data ?? const {};
  }

  Future<void> deleteCategory(String id, {bool? safeMode}) async {
    await _dio.delete(
      '$_prefix/categories/$id',
      queryParameters: safeMode == null ? null : {'safeMode': safeMode},
    );
  }

  // Stock items (master)
  Future<List<dynamic>> fetchStockItems({
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
    final data = response.data;
    if (data == null) return const [];
    if (data['data'] is List) {
      return List<dynamic>.from(data['data'] as List);
    }
    if (data['items'] is List) {
      return List<dynamic>.from(data['items'] as List);
    }
    if (data['data'] is Map<String, dynamic>) {
      final inner = data['data'] as Map<String, dynamic>;
      if (inner['items'] is List) {
        return List<dynamic>.from(inner['items'] as List);
      }
      if (inner['entries'] is List) {
        return List<dynamic>.from(inner['entries'] as List);
      }
      if (inner['data'] is List) {
        return List<dynamic>.from(inner['data'] as List);
      }
    }
    return const [];
  }

  Future<Map<String, dynamic>> createStockItem(
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
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateStockItem(
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
    return response.data ?? const {};
  }

  Future<void> deactivateStockItem(String id) async {
    await _dio.put<Map<String, dynamic>>('$_prefix/stock-items/$id', data: {'isActive': false});
  }

  Future<List<dynamic>> fetchBranchStockItems({String? branchId}) async {
    final response =
        await _dio.get<Map<String, dynamic>>(
      '$_prefix/branch/stock-items',
      queryParameters: branchId == null || branchId.isEmpty
          ? null
          : <String, dynamic>{'branchId': branchId},
    );
    final data = response.data;
    if (data == null) return const [];
    if (data['data'] is List) return List<dynamic>.from(data['data'] as List);
    if (data['items'] is List) return List<dynamic>.from(data['items'] as List);
    if (data['data'] is Map<String, dynamic>) {
      final inner = data['data'] as Map<String, dynamic>;
      if (inner['items'] is List) return List<dynamic>.from(inner['items'] as List);
    }
    return const [];
  }

  Future<Map<String, dynamic>> assignStockItemToBranch({
    required String stockItemId,
    required String branchId,
    required int minThreshold,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/branch/stock-items',
      data: {
        'stockItemId': stockItemId,
        'branchId': branchId,
        'minThreshold': minThreshold,
      },
    );
    return response.data ?? const {};
  }

  Future<List<dynamic>> fetchOnHand({String? branchId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/branch/on-hand',
      queryParameters: branchId == null || branchId.isEmpty
          ? null
          : <String, dynamic>{'branchId': branchId},
    );
    final data = response.data;
    if (data == null) return const [];
    if (data['data'] is List) return List<dynamic>.from(data['data'] as List);
    if (data['items'] is List) return List<dynamic>.from(data['items'] as List);
    if (data['data'] is Map<String, dynamic>) {
      final inner = data['data'] as Map<String, dynamic>;
      if (inner['items'] is List) return List<dynamic>.from(inner['items'] as List);
    }
    return const [];
  }

  // Inventory journal / stock movements
  Future<Map<String, dynamic>> receiveStock({
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
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> wasteStock({
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
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> correctStock({
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
    return response.data ?? const {};
  }

  Future<List<dynamic>> fetchJournal({
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
    final data = response.data;
    return _extractList(data);
  }

  Future<List<dynamic>> fetchLowStockAlerts({String? branchId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/branch/alerts/low-stock',
      queryParameters: branchId == null || branchId.isEmpty
          ? null
          : <String, dynamic>{'branchId': branchId},
    );
    return _extractList(response.data);
  }
}

List<dynamic> _extractList(dynamic data) {
  if (data == null) return const [];
  if (data is List) return List<dynamic>.from(data);
  if (data is Map<String, dynamic>) {
    for (final key in ['data', 'items', 'entries']) {
      final value = data[key];
      if (value is List) return List<dynamic>.from(value);
      if (value is Map<String, dynamic>) {
        final nested = _extractList(value);
        if (nested.isNotEmpty) return nested;
      }
    }
  }
  return const [];
}
