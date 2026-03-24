import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/menu/data/dto/menu_branch_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_category_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_composition_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_detail_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_modifier_option_effect_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_with_modifiers_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';
import 'package:modular_pos/features/menu/data/menu_api_helpers.dart';

final menuApiProvider = Provider<MenuApi>((ref) {
  final dio = ref.watch(dioProvider);
  return MenuApi.real(dio);
});

class MenuApi {
  MenuApi.real(Dio dio) : _dio = dio, _menuPrefix = AppEnv.menuApiPrefix;

  final Dio _dio;
  final String _menuPrefix;

  Future<List<MenuBranchDto>> fetchBranches() async {
    final dio = _requireDio();
    try {
      final response = await dio.get<dynamic>('/v0/auth/context/branches');
      final raw = MenuApiHelpers.unwrap(response.data);
      final branches = raw['branches'] ?? raw['items'] ?? raw['data'];
      if (branches == null) return const <MenuBranchDto>[];
      return MenuApiHelpers.parseList(
        branches,
        MenuBranchDto.fromJson,
      ).where((entry) => entry.id.trim().isNotEmpty).toList(growable: false);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<List<MenuCategoryDto>> fetchCategories({String? status}) async {
    final dio = _requireDio();
    try {
      final response = await dio.get<dynamic>(
        '$_menuPrefix/categories',
        queryParameters: status == null ? null : {'status': status},
      );
      final raw = MenuApiHelpers.unwrap(response.data);
      final categories = raw['categories'] ?? raw['data'] ?? raw;
      return MenuApiHelpers.parseList(categories, MenuCategoryDto.fromJson);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<List<ModifierGroupDto>> fetchModifierGroups({String? status}) async {
    final dio = _requireDio();
    try {
      final response = await dio.get<dynamic>(
        '$_menuPrefix/modifier-groups',
        queryParameters: status == null ? null : {'status': status},
      );
      final raw = MenuApiHelpers.unwrap(response.data);
      final groups =
          raw['modifierGroups'] ?? raw['groups'] ?? raw['data'] ?? raw;
      return MenuApiHelpers.parseList(groups, ModifierGroupDto.fromJson);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<List<ModifierOptionDto>> fetchModifierOptions(
    String modifierGroupId,
  ) async {
    final groups = await fetchModifierGroups();
    final target = groups.firstWhere(
      (entry) => entry.id == modifierGroupId,
      orElse: () => const ModifierGroupDto(
        id: '',
        tenantId: '',
        name: '',
        selectionMode: 'SINGLE',
        minSelections: 0,
        maxSelections: 1,
        isRequired: false,
        status: 'ACTIVE',
        options: <ModifierOptionDto>[],
        selectionType: 'single',
        pricingBehavior: 'addon',
        defaultOptionId: null,
        isActive: true,
      ),
    );
    return target.options;
  }

  Future<List<MenuItemDto>> fetchMenuItems({
    bool includeAllBranches = false,
    String status = 'active',
    String? categoryId,
    String? search,
    int? limit,
    int? offset,
    String? branchId,
  }) async {
    final dio = _requireDio();
    final normalizedStatus = status.trim().isEmpty
        ? 'active'
        : status.trim().toLowerCase();
    final requestStatus = switch (normalizedStatus) {
      'active' => 'ACTIVE',
      'archived' => 'ARCHIVED',
      _ => normalizedStatus,
    };
    final path = includeAllBranches
        ? '$_menuPrefix/items/all'
        : '$_menuPrefix/items';
    final normalizedCategoryId = _nullableCategoryId(categoryId);
    final normalizedSearch = search?.trim();
    final normalizedBranchId = branchId?.trim();
    final query = <String, dynamic>{
      'status': requestStatus,
      if (normalizedCategoryId != null) 'categoryId': normalizedCategoryId,
      if (normalizedSearch != null && normalizedSearch.isNotEmpty)
        'search': normalizedSearch,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      // branchId is only a filter on management lane; it must not override token context.
      if (includeAllBranches &&
          normalizedBranchId != null &&
          normalizedBranchId.isNotEmpty)
        'branchId': normalizedBranchId,
    };
    try {
      final response = await dio.get<dynamic>(path, queryParameters: query);
      final raw = MenuApiHelpers.unwrap(response.data);
      final items = raw['items'] ?? raw['data'] ?? raw;
      return MenuApiHelpers.parseList(items, MenuItemDto.fromJson);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<MenuItemWithModifiersDto> fetchMenuItemWithModifiers(
    String menuItemId,
  ) async {
    final detail = await fetchMenuItemDetail(menuItemId);
    return MenuItemWithModifiersDto(
      item: detail.item,
      modifierGroups: detail.modifierGroups,
      categoryName: detail.categoryName,
      baseComponents: detail.baseComponents,
    );
  }

  Future<MenuItemDetailDto> fetchMenuItemDetail(String menuItemId) async {
    final dio = _requireDio();
    try {
      final response = await dio.get<dynamic>('$_menuPrefix/items/$menuItemId');
      final raw = MenuApiHelpers.unwrap(response.data);
      return MenuItemDetailDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> upsertMenuItemComposition({
    required String menuItemId,
    required List<MenuComponentDto> baseComponents,
  }) async {
    final dio = _requireDio();
    final body = MenuCompositionUpsertRequestDto(
      baseComponents: baseComponents,
    ).toJson();
    try {
      await dio.put<void>(
        '$_menuPrefix/items/$menuItemId/composition',
        data: body,
        options: _writeOptions(
          actionKey: 'menu.composition.upsert',
          payload: {'menuItemId': menuItemId, ...body},
        ),
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<MenuCompositionEvaluateDto> evaluateMenuItemComposition({
    required String menuItemId,
    required List<String> selectedModifierOptionIds,
  }) async {
    final dio = _requireDio();
    final body = MenuCompositionEvaluateRequestDto(
      selectedModifierOptionIds: selectedModifierOptionIds,
    ).toJson();
    try {
      final response = await dio.post<dynamic>(
        '$_menuPrefix/items/$menuItemId/composition/evaluate',
        data: body,
      );
      final raw = MenuApiHelpers.unwrap(response.data);
      return MenuCompositionEvaluateDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> upsertMenuItemModifierOptionEffects({
    required String menuItemId,
    required List<MenuModifierOptionEffectDto> effects,
  }) async {
    final dio = _requireDio();
    final body = MenuModifierOptionEffectsUpsertRequestDto(
      effects: effects,
    ).toJson();
    try {
      await dio.put<void>(
        '$_menuPrefix/items/$menuItemId/modifier-option-effects',
        data: body,
        options: _writeOptions(
          actionKey: 'menu.modifierOptionEffects.upsert',
          payload: {'menuItemId': menuItemId, ...body},
        ),
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<MenuCategoryDto> createCategory(Map<String, dynamic> payload) async {
    final dio = _requireDio();
    try {
      final body = Map<String, dynamic>.from(payload)
        ..removeWhere((key, value) => value == null);
      final response = await dio.post<Map<String, dynamic>>(
        '$_menuPrefix/categories',
        data: body,
        options: _writeOptions(
          actionKey: 'menu.categories.create',
          payload: body,
        ),
      );
      final raw = MenuApiHelpers.unwrap(response.data);
      return MenuCategoryDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<MenuCategoryDto> updateCategory(Map<String, dynamic> payload) async {
    final dio = _requireDio();
    final categoryId = payload['id']?.toString();
    if (categoryId == null) {
      throw const MenuApiException('Category id is required for update');
    }
    final updateMap = Map<String, dynamic>.from(payload)
      ..removeWhere((key, value) => value == null || key == 'id');
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '$_menuPrefix/categories/$categoryId',
        data: updateMap,
        options: _writeOptions(
          actionKey: 'menu.categories.update',
          payload: {'categoryId': categoryId, ...updateMap},
        ),
      );
      final raw = MenuApiHelpers.unwrap(response.data);
      return MenuCategoryDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  /// Compatibility method name; uses contract archive endpoint.
  Future<void> deleteCategory(String categoryId) async {
    final dio = _requireDio();
    try {
      await dio.post<void>(
        '$_menuPrefix/categories/$categoryId/archive',
        options: _writeOptions(
          actionKey: 'menu.categories.archive',
          payload: {'categoryId': categoryId},
        ),
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> restoreCategory(String categoryId) async {
    final dio = _requireDio();
    try {
      await dio.post<void>(
        '$_menuPrefix/categories/$categoryId/restore',
        options: _writeOptions(
          actionKey: 'menu.categories.restore',
          payload: {'categoryId': categoryId},
        ),
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<ModifierGroupDto> createModifierGroup(
    Map<String, dynamic> payload,
  ) async {
    final dio = _requireDio();
    try {
      final body = _normalizeModifierGroupWritePayload(payload);
      final response = await dio.post<Map<String, dynamic>>(
        '$_menuPrefix/modifier-groups',
        data: body,
        options: _writeOptions(
          actionKey: 'menu.modifierGroups.create',
          payload: body,
        ),
      );
      final raw = MenuApiHelpers.unwrap(response.data);
      return ModifierGroupDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<ModifierGroupDto> updateModifierGroup(
    Map<String, dynamic> payload,
  ) async {
    final dio = _requireDio();
    final groupId = payload['id']?.toString();
    if (groupId == null) {
      throw const MenuApiException('Modifier group id is required for update');
    }
    final updateMap = _normalizeModifierGroupWritePayload(payload)
      ..remove('id');
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '$_menuPrefix/modifier-groups/$groupId',
        data: updateMap,
        options: _writeOptions(
          actionKey: 'menu.modifierGroups.update',
          payload: {'groupId': groupId, ...updateMap},
        ),
      );
      final raw = MenuApiHelpers.unwrap(response.data);
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
    final groupId = _extractGroupId(payload);
    final body = _normalizeModifierOptionWritePayload(payload)
      ..remove('id')
      ..remove('groupId')
      ..remove('modifierGroupId');
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '$_menuPrefix/modifier-groups/$groupId/options/$optionId',
        data: body,
        options: _writeOptions(
          actionKey: 'menu.modifierOptions.update',
          payload: {'groupId': groupId, 'optionId': optionId, ...body},
        ),
      );
      final raw = MenuApiHelpers.unwrap(response.data);
      return ModifierOptionDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  /// Compatibility method name; uses contract archive endpoint.
  Future<void> deleteModifierOption(String optionId, {String? groupId}) async {
    final resolvedGroupId = (groupId ?? '').trim();
    if (resolvedGroupId.isEmpty) {
      throw const MenuApiException(
        'Modifier group id is required to archive modifier option.',
      );
    }
    final dio = _requireDio();
    try {
      await dio.post<void>(
        '$_menuPrefix/modifier-groups/$resolvedGroupId/options/$optionId/archive',
        options: _writeOptions(
          actionKey: 'menu.modifierOptions.archive',
          payload: {'groupId': resolvedGroupId, 'optionId': optionId},
        ),
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> restoreModifierOption(String optionId, {String? groupId}) async {
    final resolvedGroupId = (groupId ?? '').trim();
    if (resolvedGroupId.isEmpty) {
      throw const MenuApiException(
        'Modifier group id is required to restore modifier option.',
      );
    }
    final dio = _requireDio();
    try {
      await dio.post<void>(
        '$_menuPrefix/modifier-groups/$resolvedGroupId/options/$optionId/restore',
        options: _writeOptions(
          actionKey: 'menu.modifierOptions.restore',
          payload: {'groupId': resolvedGroupId, 'optionId': optionId},
        ),
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<ModifierOptionDto> addModifierOption(
    Map<String, dynamic> payload,
  ) async {
    final dio = _requireDio();
    final groupId = _extractGroupId(payload);
    final body = _normalizeModifierOptionWritePayload(payload)
      ..remove('groupId')
      ..remove('modifierGroupId');
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '$_menuPrefix/modifier-groups/$groupId/options',
        data: body,
        options: _writeOptions(
          actionKey: 'menu.modifierOptions.create',
          payload: {'groupId': groupId, ...body},
        ),
      );
      final raw = MenuApiHelpers.unwrap(response.data);
      return ModifierOptionDto.fromJson(raw);
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
      final body = await _normalizeMenuItemWritePayload(
        payload,
        imagePath: imagePath,
        imageBytes: imageBytes,
      );
      final response = await dio.post<Map<String, dynamic>>(
        '$_menuPrefix/items',
        data: body,
        options: _writeOptions(actionKey: 'menu.items.create', payload: body),
      );
      final raw = MenuApiHelpers.unwrap(response.data);
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
    try {
      final body = await _normalizeMenuItemWritePayload(
        payload,
        imagePath: imagePath,
        imageBytes: imageBytes,
        isPatch: true,
      );
      final response = await dio.patch<Map<String, dynamic>>(
        '$_menuPrefix/items/$itemId',
        data: body,
        options: _writeOptions(
          actionKey: 'menu.items.update',
          payload: {'menuItemId': itemId, ...body},
        ),
      );
      final raw = MenuApiHelpers.unwrap(response.data);
      return MenuItemDto.fromJson(raw);
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  /// Compatibility method name; uses contract archive endpoint.
  Future<void> deleteMenuItem(String menuItemId) async {
    final dio = _requireDio();
    try {
      await dio.post<void>(
        '$_menuPrefix/items/$menuItemId/archive',
        options: _writeOptions(
          actionKey: 'menu.items.archive',
          payload: {'menuItemId': menuItemId},
        ),
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> restoreMenuItem(String menuItemId) async {
    final dio = _requireDio();
    try {
      await dio.post<void>(
        '$_menuPrefix/items/$menuItemId/restore',
        options: _writeOptions(
          actionKey: 'menu.items.restore',
          payload: {'menuItemId': menuItemId},
        ),
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  /// Compatibility method name; uses contract archive endpoint.
  Future<void> deleteModifierGroup(String groupId) async {
    final dio = _requireDio();
    try {
      await dio.post<void>(
        '$_menuPrefix/modifier-groups/$groupId/archive',
        options: _writeOptions(
          actionKey: 'menu.modifierGroups.archive',
          payload: {'groupId': groupId},
        ),
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> restoreModifierGroup(String groupId) async {
    final dio = _requireDio();
    try {
      await dio.post<void>(
        '$_menuPrefix/modifier-groups/$groupId/restore',
        options: _writeOptions(
          actionKey: 'menu.modifierGroups.restore',
          payload: {'groupId': groupId},
        ),
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  Future<void> setItemVisibility({
    required String menuItemId,
    required List<String> visibleBranchIds,
  }) async {
    final dio = _requireDio();
    final body = <String, dynamic>{'visibleBranchIds': visibleBranchIds};
    try {
      await dio.put<void>(
        '$_menuPrefix/items/$menuItemId/visibility',
        data: body,
        options: _writeOptions(
          actionKey: 'menu.items.visibility.set',
          payload: {'menuItemId': menuItemId, ...body},
        ),
      );
    } on DioError catch (error) {
      throw MenuApiException.fromDio(error);
    }
  }

  /// Legacy compatibility wrapper. Prefer [setItemVisibility].
  Future<void> setBranchAvailability({
    required String menuItemId,
    required String branchId,
    required bool isAvailable,
  }) async {
    await setItemVisibility(
      menuItemId: menuItemId,
      visibleBranchIds: isAvailable ? <String>[branchId] : const <String>[],
    );
  }

  Future<void> setPriceOverride({
    required String menuItemId,
    required String branchId,
    required double priceUsd,
  }) {
    throw const MenuApiException(
      'Price override endpoint is not part of /v0/menu contract.',
    );
  }

  Dio _requireDio() {
    return _dio;
  }

  Options _writeOptions({
    required String actionKey,
    required Object payload,
    String? intentId,
  }) {
    return withIdempotency(
      request: IdempotencyRequest(
        actionKey: actionKey,
        payload: payload,
        intentId: (intentId ?? '').trim().isEmpty ? null : intentId?.trim(),
      ),
    );
  }

  Future<Map<String, dynamic>> _normalizeMenuItemWritePayload(
    Map<String, dynamic> payload, {
    String? imagePath,
    List<int>? imageBytes,
    bool isPatch = false,
  }) async {
    final body = Map<String, dynamic>.from(payload)
      ..remove('id')
      ..removeWhere((key, value) => value == null);

    final normalized = <String, dynamic>{};
    if (!isPatch || body.containsKey('name')) {
      normalized['name'] = body['name']?.toString() ?? '';
    }
    if (!isPatch ||
        body.containsKey('basePrice') ||
        body.containsKey('priceUsd') ||
        body.containsKey('price')) {
      normalized['basePrice'] = _asDouble(
        body['basePrice'] ?? body['priceUsd'] ?? body['price'],
      );
    }
    if (!isPatch || body.containsKey('status')) {
      normalized['status'] = _normalizeMenuItemStatus(body['status']?.toString());
    }
    if (!isPatch || body.containsKey('categoryId')) {
      normalized['categoryId'] = _nullableCategoryId(body['categoryId']);
    }
    if (!isPatch || body.containsKey('modifierGroupIds')) {
      normalized['modifierGroupIds'] = _asStringList(body['modifierGroupIds']);
    }
    if (!isPatch ||
        body.containsKey('visibleBranchIds') ||
        body.containsKey('branchIds')) {
      normalized['visibleBranchIds'] = _asStringList(
        body['visibleBranchIds'] ?? body['branchIds'],
      );
    }
    if (!isPatch || body.containsKey('imageUrl')) {
      normalized['imageUrl'] = body['imageUrl']?.toString();
    }

    if ((imagePath ?? '').trim().isNotEmpty ||
        (imageBytes != null && imageBytes.isNotEmpty)) {
      normalized['imageUrl'] = await _uploadMenuImage(
        imagePath: imagePath,
        imageBytes: imageBytes,
      );
    }

    normalized.removeWhere((key, value) => value == null);
    return normalized;
  }

  Map<String, dynamic> _normalizeModifierGroupWritePayload(
    Map<String, dynamic> payload,
  ) {
    final body = Map<String, dynamic>.from(payload)
      ..removeWhere((key, value) => value == null);

    final selectionMode = _normalizeSelectionMode(
      body['selectionMode']?.toString() ?? body['selectionType']?.toString(),
    );
    final minSelections = _asInt(body['minSelections']) ?? 0;
    final maxSelections =
        _asInt(body['maxSelections']) ?? (selectionMode == 'SINGLE' ? 1 : 99);

    return <String, dynamic>{
      if (body['id'] != null) 'id': body['id'],
      'name': body['name']?.toString() ?? '',
      'selectionMode': selectionMode,
      'minSelections': minSelections,
      'maxSelections': maxSelections,
      'isRequired': _asBool(body['isRequired']),
      if (body['defaultOptionId'] != null)
        'defaultOptionId': body['defaultOptionId'],
    };
  }

  Map<String, dynamic> _normalizeModifierOptionWritePayload(
    Map<String, dynamic> payload,
  ) {
    final body = Map<String, dynamic>.from(payload)
      ..removeWhere((key, value) => value == null);
    return <String, dynamic>{
      if (body['id'] != null) 'id': body['id'],
      if (body['groupId'] != null) 'groupId': body['groupId'],
      if (body['modifierGroupId'] != null)
        'modifierGroupId': body['modifierGroupId'],
      'label': body['label']?.toString() ?? body['name']?.toString() ?? '',
      'priceDelta': _asDouble(
        body['priceDelta'] ?? body['priceAdjustmentUsd'] ?? body['price'],
      ),
      if (body['isDefault'] != null) 'isDefault': _asBool(body['isDefault']),
      'componentDeltas': _asComponentDeltas(body['componentDeltas']),
    };
  }

  String _extractGroupId(Map<String, dynamic> payload) {
    final groupId =
        payload['groupId']?.toString() ??
        payload['modifierGroupId']?.toString() ??
        '';
    if (groupId.trim().isEmpty) {
      throw const MenuApiException('Modifier group id is required.');
    }
    return groupId.trim();
  }

  Future<String> _uploadMenuImage({
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final dio = _requireDio();
    if (imageBytes != null && imageBytes.length > 5 * 1024 * 1024) {
      throw const MenuApiException(
        'Image is too large. Maximum size is 5MB.',
        422,
        'UPLOAD_FILE_TOO_LARGE',
      );
    }
    final imagePart = await MenuApiHelpers.buildImagePart(
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    if (imagePart == null) {
      throw const MenuApiException('Image file is required for upload.');
    }
    final formData = FormData.fromMap({'image': imagePart});
    final response = await dio.post<dynamic>(
      '$_menuPrefix/images/upload',
      data: formData,
    );
    final raw = MenuApiHelpers.unwrap(response.data);
    final imageUrl = raw['imageUrl']?.toString().trim() ?? '';
    if (imageUrl.isEmpty) {
      throw const MenuApiException('Image upload failed: imageUrl is missing.');
    }
    return imageUrl;
  }
}

String? _nullableCategoryId(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty || raw.toLowerCase() == 'null') return null;
  return raw;
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((entry) => entry?.toString().trim() ?? '')
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _asComponentDeltas(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((entry) => entry.map((key, val) => MapEntry(key.toString(), val)))
      .toList(growable: false);
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.trim().toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return false;
}

String _normalizeSelectionMode(String? value) {
  final raw = (value ?? '').trim().toUpperCase();
  if (raw == 'MULTI' || raw == 'MULTIPLE') return 'MULTI';
  return 'SINGLE';
}

String _normalizeMenuItemStatus(String? value) {
  final raw = (value ?? '').trim().toUpperCase();
  if (raw == 'ARCHIVED' || raw == 'ARCHIVE' || raw == 'INACTIVE') {
    return 'ARCHIVED';
  }
  return 'ACTIVE';
}

String? _errorCodeFrom(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  final normalized = raw.toUpperCase();
  final isCodeLike = RegExp(r'^[A-Z0-9_]+$').hasMatch(normalized);
  return isCodeLike ? normalized : null;
}

class MenuApiException implements Exception {
  const MenuApiException(this.message, [this.statusCode, this.code]);

  factory MenuApiException.fromDio(DioError exception) {
    final data = exception.response?.data;
    String? message;
    String? code;
    if (data is Map) {
      final map = data.map((key, value) => MapEntry(key.toString(), value));
      final nestedData = map['data'];
      final nestedMap = nestedData is Map
          ? nestedData.map((key, value) => MapEntry(key.toString(), value))
          : const <String, dynamic>{};
      message =
          map['message']?.toString() ??
          map['error']?.toString() ??
          nestedMap['error']?.toString() ??
          nestedMap['message']?.toString();
      code =
          _errorCodeFrom(map['code']) ??
          _errorCodeFrom(map['errorCode']) ??
          _errorCodeFrom(map['error']) ??
          _errorCodeFrom(nestedMap['code']) ??
          _errorCodeFrom(nestedMap['errorCode']) ??
          _errorCodeFrom(nestedMap['error']);
    }
    return MenuApiException(
      message ?? exception.message ?? 'Menu API error',
      exception.response?.statusCode,
      code,
    );
  }

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() =>
      'MenuApiException(statusCode: $statusCode, code: $code, message: $message)';
}
