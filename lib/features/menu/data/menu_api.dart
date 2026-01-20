import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/menu/data/dto/menu_branch_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_category_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_with_modifiers_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';

final menuApiProvider = Provider<MenuApi>((ref) {
  final dio = ref.watch(dioProvider);
  return MenuApi.real(dio);
});

class MenuApi {
  MenuApi.real(Dio dio)
      : _dio = dio,
        _menuPrefix = dotenv.env['MENU_API_PREFIX'] ?? '/v1/menu';

  final Dio _dio;
  final String _menuPrefix;

  Future<List<MenuBranchDto>> fetchBranches() async {
    // Branch data is sourced from the authenticated user's branch assignments.
    return const [];
  }

  Future<List<MenuCategoryDto>> fetchCategories({
    bool? isActive,
  }) async {
    final dio = _requireDio();
    try {
      final response = await dio.get<dynamic>(
        '$_menuPrefix/categories',
        queryParameters: isActive == null ? null : {'isActive': isActive},
      );
    final raw = _unwrap(response.data);
    final categories = raw['categories'] ?? raw['data'] ?? raw;
    return _parseList(categories, MenuCategoryDto.fromJson);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<List<ModifierGroupDto>> fetchModifierGroups() async {
    final dio = _requireDio();
    try {
      final response = await dio.get<dynamic>('$_menuPrefix/modifiers/groups');
      final raw = _unwrap(response.data);
      final groups =
          raw['modifierGroups'] ?? raw['groups'] ?? raw['data'] ?? raw;
      return _parseList(groups, ModifierGroupDto.fromJson);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<List<ModifierOptionDto>> fetchModifierOptions(
      String modifierGroupId) async {
    final dio = _requireDio();
    try {
      final response = await dio.get<dynamic>(
        '$_menuPrefix/modifiers/groups/$modifierGroupId/options',
      );
      final raw = _unwrap(response.data);
      final options = raw['options'] ?? raw['data'] ?? raw;
      return _parseList(options, ModifierOptionDto.fromJson);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<List<MenuItemDto>> fetchMenuItems({String? branchId}) async {
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
      final raw = _unwrap(response.data);
      final items = raw['items'] ?? raw['data'] ?? raw;
      return _parseList(items, MenuItemDto.fromJson);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<MenuItemWithModifiersDto> fetchMenuItemWithModifiers(
    String menuItemId,
  ) async {
    final dio = _requireDio();
    try {
      final response = await dio.get<dynamic>(
        '$_menuPrefix/items/$menuItemId/with-modifiers',
      );
      final raw = _unwrap(response.data);
      return MenuItemWithModifiersDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<MenuCategoryDto> createCategory(
      Map<String, dynamic> payload) async {
    final dio = _requireDio();
    try {
      final body = Map<String, dynamic>.from(payload)
        ..removeWhere((key, value) => value == null);
      final response = await dio.post<Map<String, dynamic>>(
        '$_menuPrefix/categories',
        data: body,
      );
      final raw = _unwrap(response.data);
      return MenuCategoryDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<MenuCategoryDto> updateCategory(
      Map<String, dynamic> payload) async {
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
      final raw = _unwrap(response.data);
      return MenuCategoryDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final dio = _requireDio();
    try {
      await dio.delete<void>('$_menuPrefix/categories/$categoryId');
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<ModifierGroupDto> createModifierGroup(
      Map<String, dynamic> payload) async {
    final dio = _requireDio();
    try {
      final body = Map<String, dynamic>.from(payload)
        ..removeWhere((key, value) => value == null);
      final response = await dio.post<Map<String, dynamic>>(
        '$_menuPrefix/modifiers/groups',
        data: body,
      );
      final raw = _unwrap(response.data);
      return ModifierGroupDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<ModifierGroupDto> updateModifierGroup(
      Map<String, dynamic> payload) async {
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
      final raw = _unwrap(response.data);
      return ModifierGroupDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<ModifierOptionDto> updateModifierOption(
    String optionId,
    Map<String, dynamic> payload,
  ) async {
    final dio = _requireDio();
    try {
      final body = Map<String, dynamic>.from(payload)
        ..removeWhere((key, value) => value == null || key == 'id');
      final response = await dio.patch<Map<String, dynamic>>(
        '$_menuPrefix/modifiers/options/$optionId',
        data: body,
      );
      final raw = _unwrap(response.data);
      return ModifierOptionDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> deleteModifierOption(String optionId) async {
    final dio = _requireDio();
    try {
      await dio.delete<void>('$_menuPrefix/modifiers/options/$optionId');
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> detachModifierFromItem({
    required String menuItemId,
    required String modifierGroupId,
  }) async {
    final dio = _requireDio();
    try {
      await dio.delete<void>(
        '$_menuPrefix/items/$menuItemId/modifiers/$modifierGroupId',
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<ModifierOptionDto> addModifierOption(
      Map<String, dynamic> payload) async {
    final dio = _requireDio();
    try {
      final body = Map<String, dynamic>.from(payload)
        ..removeWhere((key, value) => value == null);
      final response = await dio.post<Map<String, dynamic>>(
        '$_menuPrefix/modifiers/options',
        data: body,
      );
      final raw = _unwrap(response.data);
      return ModifierOptionDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> attachModifierToItem(
    String menuItemId,
    Map<String, dynamic> payload,
  ) async {
    final dio = _requireDio();
    try {
      await dio.post<void>(
        '$_menuPrefix/items/$menuItemId/modifiers',
        data: payload,
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<MenuItemDto> createMenuItem(
    Map<String, dynamic> payload, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
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
      final raw = _unwrap(response.data);
      return MenuItemDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<MenuItemDto> updateMenuItem(
    Map<String, dynamic> payload, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
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
      final raw = _unwrap(response.data);
      return MenuItemDto.fromJson(raw);
    } on DioError catch (error) {
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
    final dio = _requireDio();
    try {
      await dio.delete<void>('$_menuPrefix/items/$menuItemId');
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> deleteModifierGroup(String groupId) async {
    final dio = _requireDio();
    try {
      await dio.delete<void>('$_menuPrefix/modifiers/groups/$groupId');
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> setBranchAvailability({
    required String menuItemId,
    required String branchId,
    required bool isAvailable,
  }) async {
    final dio = _requireDio();
    try {
      await dio.put<void>(
        '$_menuPrefix/items/$menuItemId/branches/availability',
        data: {
          'branchId': branchId,
          'isAvailable': isAvailable,
        },
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> setPriceOverride({
    required String menuItemId,
    required String branchId,
    required double priceUsd,
  }) async {
    final dio = _requireDio();
    try {
      await dio.put<void>(
        '$_menuPrefix/items/$menuItemId/branches/price',
        data: {
          'branchId': branchId,
          'priceUsd': priceUsd,
        },
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Dio _requireDio() {
    return _dio;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _unwrap(dynamic body) {
    final map = _asMap(body);
    final inner = map['data'];
    if (map['success'] == true && inner is Map) {
      return _asMap(inner);
    }
    return map;
  }

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => fromJson(_asMap(e)))
          .toList(growable: false);
    }
    if (data is Map<String, dynamic>) {
      return [fromJson(data)];
    }
    return <T>[];
  }
}

class MenuApiException implements Exception {
  const MenuApiException(this.message, [this.statusCode]);

  factory MenuApiException.fromDio(DioError exception) {
    final data = exception.response?.data;
    final message = data is Map ? data['message']?.toString() : null;
    return MenuApiException(
      message ?? exception.message ?? 'Menu API error',
      exception.response?.statusCode,
    );
  }

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'MenuApiException(statusCode: $statusCode, message: $message)';
}
