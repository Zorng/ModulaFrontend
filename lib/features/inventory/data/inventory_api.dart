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
    if (data['data'] is List) return List<dynamic>.from(data['data'] as List);
    if (data['items'] is List) return List<dynamic>.from(data['items'] as List);
    if (data['data'] is Map<String, dynamic>) {
      final inner = data['data'] as Map<String, dynamic>;
      if (inner['items'] is List) return List<dynamic>.from(inner['items'] as List);
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
        await _dio.put<Map<String, dynamic>>('$_prefix/stock-items/$id', data: payload);
    return response.data ?? const {};
  }

  Future<void> deactivateStockItem(String id) async {
    await _dio.put<Map<String, dynamic>>('$_prefix/stock-items/$id', data: {'isActive': false});
  }
}
