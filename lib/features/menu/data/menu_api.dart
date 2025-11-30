import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/menu/data/menu_mock_data_source.dart';

final menuApiProvider = Provider<MenuApi>((ref) {
  const useMock =
      bool.fromEnvironment('MENU_USE_MOCK', defaultValue: false);
  if (useMock) {
    return MenuApi.mock(
      MenuMockDataSource(
        branchCount: int.fromEnvironment('MENU_BRANCH_COUNT', defaultValue: 1),
      ),
    );
  }
  final dio = ref.watch(dioProvider);
  return MenuApi.real(dio);
});

class MenuApi {
  MenuApi.real(Dio dio)
      : _dio = dio,
        _menuPrefix = dotenv.env['MENU_API_PREFIX'] ?? '/v1/menu',
        _mock = null;

  MenuApi.mock(MenuMockDataSource mock)
      : _dio = null,
        _menuPrefix = '',
        _mock = mock;

  final Dio? _dio;
  final String _menuPrefix;
  final MenuMockDataSource? _mock;

  Future<List<Map<String, dynamic>>> fetchBranches() async {
    final mock = _mock;
    if (mock != null) return mock.fetchBranches();
    // TODO: replace with real endpoint once available.
    return const [];
  }

  Future<List<Map<String, dynamic>>> fetchCategories({
    bool? isActive,
  }) async {
    final mock = _mock;
    if (mock != null) {
      return mock.fetchCategories(isActive: isActive);
    }
    final dio = _requireDio();
    try {
      final response = await dio.get<dynamic>(
        '$_menuPrefix/categories',
        queryParameters: isActive == null ? null : {'isActive': isActive},
      );
      final data = response.data;
      if (data == null) return const [];
      final categories =
          data is Map<String, dynamic> ? data['categories'] : data;
      return _mapList(categories);
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> fetchModifierGroups() async {
    final mock = _mock;
    if (mock != null) return mock.fetchModifierGroups();
    final dio = _requireDio();
    try {
      final response = await dio.get<dynamic>('$_menuPrefix/modifiers/groups');
      final data = response.data;
      if (data == null) return const [];
      final groups = data is Map<String, dynamic>
          ? data['modifierGroups'] ?? data['groups'] ?? data['data']
          : data;
      return _mapList(groups);
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> fetchMenuSnapshot(String branchId) async {
    final mock = _mock;
    if (mock != null) {
      return {
        'branchId': branchId,
        'items': await mock.fetchMenuItems(),
        'categories': await mock.fetchCategories(),
        'modifierGroups': await mock.fetchModifierGroups(),
      };
    }
    final dio = _requireDio();
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '$_menuPrefix/snapshot',
        queryParameters: {'branchId': branchId},
      );
      return response.data ?? const {};
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> fetchModifierOptions(
      String modifierGroupId) async {
    final mock = _mock;
    if (mock != null) return mock.fetchModifierOptions(modifierGroupId);
    final dio = _requireDio();
    try {
      final response = await dio.get<dynamic>(
        '$_menuPrefix/modifiers/groups/$modifierGroupId/options',
      );
      final data = response.data;
      if (data == null) return const [];
      final options = data is Map<String, dynamic>
          ? data['options'] ?? data['data'] ?? data
          : data;
      return _mapList(options);
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> fetchMenuItems({String? branchId}) async {
    final mock = _mock;
    if (mock != null) return mock.fetchMenuItems();
    final dio = _requireDio();
    final bool hasBranch = branchId != null && branchId.isNotEmpty;
    final String path = hasBranch
        ? '$_menuPrefix/items/by-branch'
        : '$_menuPrefix/items';
    final Map<String, dynamic>? query =
        hasBranch ? {'branchId': branchId} : null;
    try {
      final response = await dio.get<dynamic>(
        path,
        queryParameters: query,
      );
      final data = response.data;
      if (data == null) return const [];
      final items = data is Map<String, dynamic>
          ? data['items'] ?? data['data'] ?? data
          : data;
      return _mapList(items);
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> fetchMenuItemWithModifiers(
    String menuItemId,
  ) async {
    final mock = _mock;
    if (mock != null) {
      // Mock not implemented; return empty.
      return const {};
    }
    final dio = _requireDio();
    try {
      final response = await dio.get<dynamic>(
        '$_menuPrefix/items/$menuItemId/with-modifiers',
      );
      return (response.data as Map<String, dynamic>?) ?? const {};
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> createCategory(
      Map<String, dynamic> payload) async {
    final mock = _mock;
    if (mock != null) return mock.createCategory(payload);
    final dio = _requireDio();
    try {
      final body = Map<String, dynamic>.from(payload)
        ..removeWhere((key, value) => value == null);
      final response = await dio.post<Map<String, dynamic>>(
        '$_menuPrefix/categories',
        data: body,
      );
      return response.data ?? const {};
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> updateCategory(
      Map<String, dynamic> payload) async {
    final mock = _mock;
    if (mock != null) return mock.updateCategory(payload);
    final dio = _requireDio();
    final categoryId = payload['id']?.toString();
    if (categoryId == null) {
      throw const MenuApiException('Category id is required for update');
    }
    final updateMap = Map<String, dynamic>.from(payload)
      ..removeWhere(
        (key, value) => value == null || key == 'id',
      );
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '$_menuPrefix/categories/$categoryId',
        data: updateMap,
      );
      return response.data ?? const {};
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final mock = _mock;
    if (mock != null) return mock.deleteCategory(categoryId);
    final dio = _requireDio();
    try {
      await dio.delete<void>('$_menuPrefix/categories/$categoryId');
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> createModifierGroup(
      Map<String, dynamic> payload) async {
    final mock = _mock;
    if (mock != null) return mock.createModifierGroup(payload);
    final dio = _requireDio();
    try {
      final body = Map<String, dynamic>.from(payload)
        ..removeWhere((key, value) => value == null);
      final response = await dio.post<Map<String, dynamic>>(
        '$_menuPrefix/modifiers/groups',
        data: body,
      );
      return response.data ?? const {};
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> updateModifierGroup(
      Map<String, dynamic> payload) async {
    final mock = _mock;
    if (mock != null) return mock.updateModifierGroup(payload);
    final dio = _requireDio();
    final groupId = payload['id']?.toString();
    if (groupId == null) {
      throw const MenuApiException('Modifier group id is required for update');
    }
    final updateMap = Map<String, dynamic>.from(payload)
      ..removeWhere((key, value) => key == 'id' || value == null);
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '$_menuPrefix/modifiers/groups/$groupId',
        data: updateMap,
      );
      return response.data ?? const {};
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> updateModifierOption(
    String optionId,
    Map<String, dynamic> payload,
  ) async {
    final mock = _mock;
    if (mock != null) return payload..['id'] = optionId;
    final dio = _requireDio();
    try {
      final body = Map<String, dynamic>.from(payload)
        ..removeWhere((key, value) => value == null || key == 'id');
      final response = await dio.patch<Map<String, dynamic>>(
        '$_menuPrefix/modifiers/options/$optionId',
        data: body,
      );
      return response.data ?? const {};
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> deleteModifierOption(String optionId) async {
    final mock = _mock;
    if (mock != null) return;
    final dio = _requireDio();
    try {
      await dio.delete<void>('$_menuPrefix/modifiers/options/$optionId');
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> detachModifierFromItem({
    required String menuItemId,
    required String modifierGroupId,
  }) async {
    final mock = _mock;
    if (mock != null) return;
    final dio = _requireDio();
    try {
      await dio.delete<void>(
        '$_menuPrefix/items/$menuItemId/modifiers/$modifierGroupId',
      );
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> addModifierOption(
      Map<String, dynamic> payload) async {
    final mock = _mock;
    if (mock != null) return mock.addModifierOption(payload);
    final dio = _requireDio();
    try {
      final body = Map<String, dynamic>.from(payload)
        ..removeWhere((key, value) => value == null);
      final response = await dio.post<Map<String, dynamic>>(
        '$_menuPrefix/modifiers/options',
        data: body,
      );
      return response.data ?? const {};
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> attachModifierToItem(
    String menuItemId,
    Map<String, dynamic> payload,
  ) async {
    final mock = _mock;
    if (mock != null) return mock.attachModifierToItem(menuItemId, payload);
    final dio = _requireDio();
    try {
      await dio.post<void>(
        '$_menuPrefix/items/$menuItemId/modifiers',
        data: payload,
      );
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> createMenuItem(
    Map<String, dynamic> payload, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final mock = _mock;
    if (mock != null) return mock.createMenuItem(payload);
    final dio = _requireDio();
    try {
      final body = Map<String, dynamic>.from(payload)
        ..removeWhere((key, value) => key == 'id' || value == null);
      final formData = FormData.fromMap(body);
      final imagePart = await _buildImagePart(
        imagePath: imagePath,
        imageBytes: imageBytes,
      );
      if (imagePart != null) formData.files.add(MapEntry('image', imagePart));
      final response = await dio.post<Map<String, dynamic>>(
        '$_menuPrefix/items',
        data: formData,
      );
      return response.data ?? const {};
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> updateMenuItem(
    Map<String, dynamic> payload, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final mock = _mock;
    if (mock != null) return mock.updateMenuItem(payload);
    final dio = _requireDio();
    final itemId = payload['id']?.toString();
    if (itemId == null) {
      throw const MenuApiException('Menu item id is required for update');
    }
    final updateMap = Map<String, dynamic>.from(payload)
      ..removeWhere((key, value) => key == 'id' || value == null);
    try {
      final formData = FormData.fromMap(updateMap);
      final imagePart = await _buildImagePart(
        imagePath: imagePath,
        imageBytes: imageBytes,
      );
      if (imagePart != null) formData.files.add(MapEntry('image', imagePart));
      final response = await dio.patch<Map<String, dynamic>>(
        '$_menuPrefix/items/$itemId',
        data: formData,
      );
      return response.data ?? const {};
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<MultipartFile?> _buildImagePart({
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      return MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last,
      );
    }
    if (imageBytes != null && imageBytes.isNotEmpty) {
      return MultipartFile.fromBytes(
        imageBytes,
        filename: 'upload.jpg',
      );
    }
    return null;
  }

  Future<void> deleteMenuItem(String menuItemId) async {
    final mock = _mock;
    if (mock != null) {
      await mock.deleteMenuItem(menuItemId);
      return;
    }
    final dio = _requireDio();
    try {
      await dio.delete<void>('$_menuPrefix/items/$menuItemId');
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> deleteModifierGroup(String groupId) async {
    final mock = _mock;
    if (mock != null) {
      return mock.deleteModifierGroup(groupId);
    }
    final dio = _requireDio();
    try {
      await dio.delete<void>('$_menuPrefix/modifiers/groups/$groupId');
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> setBranchAvailability({
    required String menuItemId,
    required String branchId,
    required bool isAvailable,
  }) async {
    final mock = _mock;
    if (mock != null) {
      return mock.setBranchAvailability(
        menuItemId: menuItemId,
        branchId: branchId,
        isAvailable: isAvailable,
      );
    }
    final dio = _requireDio();
    try {
      await dio.put<void>(
        '$_menuPrefix/items/$menuItemId/branches/availability',
        data: {
          'branchId': branchId,
          'isAvailable': isAvailable,
        },
      );
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> setPriceOverride({
    required String menuItemId,
    required String branchId,
    required double priceUsd,
  }) async {
    final mock = _mock;
    if (mock != null) {
      return mock.setPriceOverride(
        menuItemId: menuItemId,
        branchId: branchId,
        priceUsd: priceUsd,
      );
    }
    final dio = _requireDio();
    try {
      await dio.put<void>(
        '$_menuPrefix/items/$menuItemId/branches/price',
        data: {
          'branchId': branchId,
          'priceUsd': priceUsd,
        },
      );
    } on DioException catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Dio _requireDio() {
    final dio = _dio;
    if (dio == null) {
      throw const MenuApiException('HTTP client not available for mock API');
    }
    return dio;
  }

  List<Map<String, dynamic>> _mapList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return const [];
  }
}

class MenuApiException implements Exception {
  const MenuApiException(this.message, [this.statusCode]);

  factory MenuApiException.fromDio(DioException exception) {
    final message =
        exception.response?.data?['message']?.toString() ?? exception.message;
    return MenuApiException(
      message ?? 'Menu API error',
      exception.response?.statusCode,
    );
  }

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'MenuApiException(statusCode: $statusCode, message: $message)';
}
