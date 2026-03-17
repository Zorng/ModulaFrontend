import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/inventory/data/dto/branch_stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/branch_stock_projection_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/inventory_category_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/inventory_journal_entry_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api_envelope.dart';
import 'package:modular_pos/features/inventory/data/inventory_paginated_result.dart';
import 'package:modular_pos/features/inventory/data/dto/on_hand_record_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/restock_batch_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_aggregate_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';

final inventoryApiProvider = Provider<InventoryApi>((ref) {
  final dio = ref.watch(dioProvider);
  return InventoryApi(dio);
});

class InventoryApi {
  InventoryApi(this._dio) : _prefix = AppEnv.inventoryApiPrefix;

  final Dio _dio;
  final String _prefix;

  // Categories
  Future<List<InventoryCategoryDto>> fetchCategories({
    String status = 'all',
  }) async {
    final query = <String, dynamic>{
      'status': _normalizeInventoryListStatus(status),
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/categories',
      queryParameters: query,
    );
    final list = InventoryApiEnvelope.unwrapDataList(
      response.data,
      fallbackMessage: 'Failed to fetch categories.',
    );
    return list.map(InventoryCategoryDto.fromJson).toList(growable: false);
  }

  Future<InventoryCategoryDto> createCategory(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_prefix/categories',
        data: body,
        options: _writeOptions(
          actionKey: 'inventory.categories.create',
          payload: body,
        ),
      );
      final json = InventoryApiEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to create category.',
      );
      return InventoryCategoryDto.fromJson(json);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to create category.',
      );
    }
  }

  Future<InventoryCategoryDto> updateCategory(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_prefix/categories/$id',
        data: body,
        options: _writeOptions(
          actionKey: 'inventory.categories.update',
          payload: {'categoryId': id, ...body},
        ),
      );
      final json = InventoryApiEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to update category.',
      );
      return InventoryCategoryDto.fromJson(json);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to update category.',
      );
    }
  }

  Future<void> deleteCategory(String id, {bool? safeMode}) async {
    try {
      await _dio.post<void>(
        '$_prefix/categories/$id/archive',
        options: _writeOptions(
          actionKey: 'inventory.categories.archive',
          payload: {'categoryId': id},
        ),
      );
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to archive category.',
      );
    }
  }

  // Stock items (master)
  Future<InventoryPaginatedResult<StockItemDto>> fetchStockItems({
    String status = 'all',
    String? search,
    String? categoryId,
    int? limit,
    int? offset,
  }) async {
    final query = <String, dynamic>{
      'status': _normalizeInventoryListStatus(status),
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };
    try {
      final response = await _getInventoryJson(
        '$_prefix/items',
        dio: _dio,
        queryParameters: query,
      );
      final result = InventoryApiEnvelope.unwrapPaginatedDataList(
        response.data,
        fallbackMessage: 'Failed to fetch stock items.',
      );
      return InventoryPaginatedResult<StockItemDto>(
        items: result.items.map(StockItemDto.fromJson).toList(growable: false),
        limit: result.limit,
        offset: result.offset,
        total: result.total,
        hasMore: result.hasMore,
      );
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to fetch stock items.',
      );
    }
  }

  Future<StockItemDto> fetchStockItemById(String stockItemId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/items/$stockItemId',
      );
      final json = InventoryApiEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to read stock item.',
      );
      return StockItemDto.fromJson(json);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to read stock item.',
      );
    }
  }

  Future<StockItemDto> createStockItem(
    Map<String, dynamic> body, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    try {
      final payload = Map<String, dynamic>.from(body)
        ..removeWhere((key, value) => value == null);
      if ((imagePath ?? '').trim().isNotEmpty ||
          (imageBytes != null && imageBytes.isNotEmpty)) {
        payload['imageUrl'] = await _uploadInventoryImage(
          dio: _dio,
          imagePath: imagePath,
          imageBytes: imageBytes,
        );
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '$_prefix/items',
        data: payload,
        options: _writeOptions(
          actionKey: 'inventory.items.create',
          payload: payload,
        ),
      );
      final json = InventoryApiEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to create stock item.',
      );
      return StockItemDto.fromJson(json);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to create stock item.',
      );
    }
  }

  Future<StockItemDto> updateStockItem(
    String id,
    Map<String, dynamic> body, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    try {
      final payload = Map<String, dynamic>.from(body);
      if ((imagePath ?? '').trim().isNotEmpty ||
          (imageBytes != null && imageBytes.isNotEmpty)) {
        payload['imageUrl'] = await _uploadInventoryImage(
          dio: _dio,
          imagePath: imagePath,
          imageBytes: imageBytes,
        );
      }
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_prefix/items/$id',
        data: payload,
        options: _writeOptions(
          actionKey: 'inventory.items.update',
          payload: {'stockItemId': id, ...payload},
        ),
      );
      final json = InventoryApiEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to update stock item.',
      );
      return StockItemDto.fromJson(json);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to update stock item.',
      );
    }
  }

  Future<void> archiveStockItem(String id) async {
    try {
      await _dio.post<void>(
        '$_prefix/items/$id/archive',
        options: _writeOptions(
          actionKey: 'inventory.items.archive',
          payload: {'stockItemId': id},
        ),
      );
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to archive stock item.',
      );
    }
  }

  Future<void> restoreStockItem(String id) async {
    try {
      await _dio.post<void>(
        '$_prefix/items/$id/restore',
        options: _writeOptions(
          actionKey: 'inventory.items.restore',
          payload: {'stockItemId': id},
        ),
      );
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to restore stock item.',
      );
    }
  }

  Future<List<BranchStockItemDto>> fetchBranchStockItems({
    required String branchId,
    bool includeArchivedItems = true,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/stock/branch',
      queryParameters: <String, dynamic>{
        'branchId': branchId,
        'includeArchivedItems': includeArchivedItems,
      },
    );
    final list = InventoryApiEnvelope.unwrapDataList(
      response.data,
      fallbackMessage: 'Failed to fetch branch stock items.',
    );
    return list
        .map((json) => BranchStockItemDto.fromJson(json))
        .toList(growable: false);
  }

  Future<void> assignStockItemToBranch({
    required String stockItemId,
    required String branchId,
    required int minThreshold,
  }) async {
    throw UnsupportedError(
      'Branch assignment is not supported by the current inventory contract.',
    );
  }

  Future<List<OnHandRecordDto>> fetchOnHand({
    required String branchId,
    bool includeArchivedItems = true,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/stock/branch',
      queryParameters: <String, dynamic>{
        'branchId': branchId,
        'includeArchivedItems': includeArchivedItems,
      },
    );
    final list = InventoryApiEnvelope.unwrapDataList(
      response.data,
      fallbackMessage: 'Failed to fetch on-hand projections.',
    );
    return list
        .map((json) => OnHandRecordDto.fromJson(json))
        .toList(growable: false);
  }

  Future<List<StockAggregateItemDto>> fetchAggregateStock({
    bool includeArchivedItems = true,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/stock/aggregate',
      queryParameters: <String, dynamic>{
        'includeArchivedItems': includeArchivedItems,
      },
    );
    final list = InventoryApiEnvelope.unwrapDataList(
      response.data,
      fallbackMessage: 'Failed to fetch aggregate stock.',
    );
    return list.map(StockAggregateItemDto.fromJson).toList(growable: false);
  }

  Future<InventoryPaginatedResult<RestockBatchDto>> fetchRestockBatches({
    String? branchId,
    String status = 'all',
    String? stockItemId,
    int? limit,
    int? offset,
  }) async {
    final query = <String, dynamic>{
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      'status': _normalizeInventoryListStatus(status),
      if (stockItemId != null && stockItemId.isNotEmpty)
        'stockItemId': stockItemId,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/restock-batches',
      queryParameters: query,
    );
    final result = InventoryApiEnvelope.unwrapPaginatedDataList(
      response.data,
      fallbackMessage: 'Failed to fetch restock batches.',
    );
    return InventoryPaginatedResult<RestockBatchDto>(
      items: result.items.map(RestockBatchDto.fromJson).toList(growable: false),
      limit: result.limit,
      offset: result.offset,
      total: result.total,
      hasMore: result.hasMore,
    );
  }

  Future<InventoryJournalEntryDto?> createRestockBatch({
    required String branchId,
    required String stockItemId,
    required int quantityInBaseUnit,
    String? receivedAt,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
    String? note,
  }) async {
    try {
      final payload = <String, dynamic>{
        'branchId': branchId,
        'stockItemId': stockItemId,
        'quantityInBaseUnit': quantityInBaseUnit,
        if (receivedAt != null && receivedAt.isNotEmpty)
          'receivedAt': receivedAt,
        if (expiryDate != null && expiryDate.isNotEmpty)
          'expiryDate': expiryDate,
        if (supplierName != null && supplierName.isNotEmpty)
          'supplierName': supplierName,
        if (purchaseCostUsd != null) 'purchaseCostUsd': purchaseCostUsd,
        if (note != null && note.isNotEmpty) 'note': note,
      };
      final response = await _dio.post<Map<String, dynamic>>(
        '$_prefix/restock-batches',
        data: payload,
        options: _writeOptions(
          actionKey: 'inventory.restockBatches.create',
          payload: payload,
        ),
      );
      final raw = InventoryApiEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to create restock batch.',
      );
      final journal = raw['journalEntry'];
      if (journal is Map) {
        return InventoryJournalEntryDto.fromJson(
          InventoryApiEnvelope.asMap(journal),
        );
      }
      return null;
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to create restock batch.',
      );
    }
  }

  Future<RestockBatchDto> updateRestockBatchMetadata({
    required String batchId,
    required String branchId,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
    String? note,
  }) async {
    try {
      final payload = <String, dynamic>{
        'branchId': branchId,
        if (expiryDate != null && expiryDate.isNotEmpty)
          'expiryDate': expiryDate,
        if (supplierName != null && supplierName.isNotEmpty)
          'supplierName': supplierName,
        if (purchaseCostUsd != null) 'purchaseCostUsd': purchaseCostUsd,
        if (note != null && note.isNotEmpty) 'note': note,
      };
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_prefix/restock-batches/$batchId',
        data: payload,
        options: _writeOptions(
          actionKey: 'inventory.restockBatches.updateMeta',
          payload: {'batchId': batchId, ...payload},
        ),
      );
      final json = InventoryApiEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to update restock batch.',
      );
      return RestockBatchDto.fromJson(json);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to update restock batch.',
      );
    }
  }

  Future<void> archiveRestockBatch({
    required String batchId,
    required String branchId,
  }) async {
    try {
      await _dio.post<void>(
        '$_prefix/restock-batches/$batchId/archive',
        queryParameters: <String, dynamic>{'branchId': branchId},
        options: _writeOptions(
          actionKey: 'inventory.restockBatches.archive',
          payload: {'batchId': batchId, 'branchId': branchId},
        ),
      );
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to archive restock batch.',
      );
    }
  }

  Future<int?> applyAdjustment({
    required String branchId,
    required String stockItemId,
    required String style,
    int? deltaInBaseUnit,
    int? countedOnHandInBaseUnit,
    required String reasonCode,
    String? note,
  }) async {
    try {
      final normalizedStyle = style.trim().toUpperCase();
      final payload = <String, dynamic>{
        'branchId': branchId,
        'stockItemId': stockItemId,
        'style': normalizedStyle == 'SET_TO_COUNT' ? 'SET_TO_COUNT' : 'DELTA',
        'reasonCode': reasonCode.trim().toUpperCase(),
        if (note != null && note.isNotEmpty) 'note': note,
      };
      if (payload['style'] == 'SET_TO_COUNT') {
        if (countedOnHandInBaseUnit != null) {
          payload['countedOnHandInBaseUnit'] = countedOnHandInBaseUnit;
        }
      } else if (deltaInBaseUnit != null) {
        payload['deltaInBaseUnit'] = deltaInBaseUnit;
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '$_prefix/adjustments',
        data: payload,
        options: _writeOptions(
          actionKey: 'inventory.adjustments.apply',
          payload: payload,
        ),
      );
      final json = InventoryApiEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to apply inventory adjustment.',
      );
      return _extractResultingOnHand(json);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to apply inventory adjustment.',
      );
    }
  }

  // Inventory journal / stock movements
  Future<InventoryJournalEntryDto?> receiveStock({
    required String branchId,
    required String stockItemId,
    required num qty,
    String? note,
    String? occurredAt,
  }) async {
    throw UnsupportedError(
      'Use createRestockBatch for restocking under the current inventory contract.',
    );
  }

  Future<InventoryJournalEntryDto?> wasteStock({
    required String branchId,
    required String stockItemId,
    required num qty,
    required String note,
    String? occurredAt,
  }) async {
    throw UnsupportedError(
      'Use applyAdjustment for inventory deductions under the current inventory contract.',
    );
  }

  Future<InventoryJournalEntryDto?> correctStock({
    required String branchId,
    required String stockItemId,
    required num delta,
    required String note,
    String? occurredAt,
  }) async {
    throw UnsupportedError(
      'Use applyAdjustment for inventory corrections under the current inventory contract.',
    );
  }

  Future<InventoryPaginatedResult<InventoryJournalEntryDto>> fetchJournal({
    required String branchId,
    String? stockItemId,
    String? reasonCode,
    DateTime? date,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'branchId': branchId,
      if (stockItemId != null && stockItemId.isNotEmpty)
        'stockItemId': stockItemId,
      if ((reasonCode ?? '').trim().isNotEmpty)
        'reasonCode': _normalizeInventoryJournalReasonCode(reasonCode!),
      if (date != null)
        'date': _formatInventoryJournalQueryDate(date)
      else ...{
        if (from != null) 'from': _formatInventoryJournalQueryDate(from),
        if (to != null) 'to': _formatInventoryJournalQueryDate(to),
      },
      'limit': limit <= 0 ? 50 : limit,
      'offset': offset < 0 ? 0 : offset,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/journal',
      queryParameters: query,
    );
    final result = InventoryApiEnvelope.unwrapPaginatedDataList(
      response.data,
      fallbackMessage: 'Failed to fetch inventory journal.',
    );
    return InventoryPaginatedResult<InventoryJournalEntryDto>(
      items: result.items
          .map(InventoryJournalEntryDto.fromJson)
          .toList(growable: false),
      limit: result.limit,
      offset: result.offset,
      total: result.total,
      hasMore: result.hasMore,
    );
  }

  Future<InventoryPaginatedResult<InventoryJournalEntryDto>>
  fetchTenantJournal({
    String? branchId,
    String? stockItemId,
    String? reasonCode,
    DateTime? date,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (stockItemId != null && stockItemId.isNotEmpty)
        'stockItemId': stockItemId,
      if ((reasonCode ?? '').trim().isNotEmpty)
        'reasonCode': _normalizeInventoryJournalReasonCode(reasonCode!),
      if (date != null)
        'date': _formatInventoryJournalQueryDate(date)
      else ...{
        if (from != null) 'from': _formatInventoryJournalQueryDate(from),
        if (to != null) 'to': _formatInventoryJournalQueryDate(to),
      },
      'limit': limit <= 0 ? 50 : limit,
      'offset': offset < 0 ? 0 : offset,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/journal/all',
      queryParameters: query,
    );
    final result = InventoryApiEnvelope.unwrapPaginatedDataList(
      response.data,
      fallbackMessage: 'Failed to fetch tenant inventory journal.',
    );
    return InventoryPaginatedResult<InventoryJournalEntryDto>(
      items: result.items
          .map(InventoryJournalEntryDto.fromJson)
          .toList(growable: false),
      limit: result.limit,
      offset: result.offset,
      total: result.total,
      hasMore: result.hasMore,
    );
  }

  Future<List<InventoryJournalEntryDto>> fetchLowStockAlerts({
    String? branchId,
  }) async {
    // branchId comes from working-context token; never send overrides in query.
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/branch/alerts/low-stock',
    );
    final list = InventoryApiEnvelope.unwrapDataList(
      response.data,
      fallbackMessage: 'Failed to fetch low-stock alerts.',
    );
    return list.map(InventoryJournalEntryDto.fromJson).toList(growable: false);
  }
}

String _formatInventoryJournalQueryDate(DateTime value) {
  final date = DateTime(value.year, value.month, value.day);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

int? _extractResultingOnHand(Map<String, dynamic> payload) {
  final direct = _toInt(payload['resultingOnHandInBaseUnit']);
  if (direct != null) return direct;
  final adjustment = payload['adjustment'];
  if (adjustment is Map) {
    return _toInt(
      InventoryApiEnvelope.asMap(adjustment)['resultingOnHandInBaseUnit'],
    );
  }
  final projection = _extractProjection(payload);
  if (projection != null) return projection.onHandInBaseUnit;
  return null;
}

BranchStockProjectionDto? _extractProjection(Map<String, dynamic> payload) {
  final directProjection = payload['branchStockProjection'];
  if (directProjection is Map) {
    return BranchStockProjectionDto.fromJson(
      InventoryApiEnvelope.asMap(directProjection),
    );
  }

  final adjustment = payload['adjustment'];
  if (adjustment is Map) {
    final nested = InventoryApiEnvelope.asMap(
      adjustment,
    )['branchStockProjection'];
    if (nested is Map) {
      return BranchStockProjectionDto.fromJson(
        InventoryApiEnvelope.asMap(nested),
      );
    }
  }
  return null;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _normalizeInventoryListStatus(String raw) {
  final normalized = raw.trim().toLowerCase();
  switch (normalized) {
    case 'active':
    case 'archived':
    case 'all':
      return normalized;
    default:
      return 'all';
  }
}

String _normalizeInventoryJournalReasonCode(String raw) {
  final normalized = raw.trim().toLowerCase();
  switch (normalized) {
    case 'restock':
    case 'receive':
      return 'RESTOCK';
    case 'sale':
    case 'sale_deduction':
      return 'SALE_DEDUCTION';
    case 'void':
    case 'voided':
    case 'void_reversal':
      return 'VOID_REVERSAL';
    case 'adjustment':
    case 'waste':
    case 'add':
    case 'remove':
      return 'ADJUSTMENT';
    case 'other':
    case 'unknown':
    case 'reopen':
      return 'OTHER';
    default:
      return 'OTHER';
  }
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

Future<Response<Map<String, dynamic>>> _getInventoryJson(
  String path, {
  required Dio dio,
  Map<String, dynamic>? queryParameters,
}) async {
  try {
    return await dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
  } on DioError catch (error) {
    if (error.response?.statusCode != 304) rethrow;

    return dio.get<Map<String, dynamic>>(
      path,
      queryParameters: {
        ...?queryParameters,
        '_': DateTime.now().microsecondsSinceEpoch,
      },
      options: Options(
        headers: const {
          'Cache-Control': 'no-store, no-cache, max-age=0',
          'Pragma': 'no-cache',
        },
      ),
    );
  }
}

Future<String> _uploadInventoryImage({
  required Dio dio,
  String? imagePath,
  List<int>? imageBytes,
}) async {
  final imagePart = await _buildImagePart(
    imagePath: imagePath,
    imageBytes: imageBytes,
  );
  if (imagePart == null) {
    throw const ApiClientException(
      message: 'Image file is required for upload.',
      code: 'UPLOAD_FILE_REQUIRED',
    );
  }
  try {
    final response = await dio.post<dynamic>(
      '/v0/media/images/upload',
      data: FormData.fromMap({'image': imagePart, 'area': 'inventory'}),
    );
    final raw = InventoryApiEnvelope.unwrapDataMap(
      response.data,
      fallbackMessage: 'Failed to upload inventory image.',
    );
    final imageUrl = raw['imageUrl']?.toString().trim() ?? '';
    if (imageUrl.isEmpty) {
      throw const ApiClientException(
        message: 'Image upload failed: imageUrl is missing.',
        code: 'IMAGE_UPLOAD_FAILED',
      );
    }
    return imageUrl;
  } on DioError catch (error) {
    throw ApiClientException.fromDio(
      error,
      fallbackMessage: 'Failed to upload inventory image.',
    );
  }
}

Future<MultipartFile?> _buildImagePart({
  String? imagePath,
  List<int>? imageBytes,
}) async {
  final filename = _resolveFilename(imagePath);
  final subtype = _resolveImageSubtype(
    imagePath: imagePath,
    imageBytes: imageBytes,
  );
  final contentType = subtype == null ? null : MediaType('image', subtype);
  if (imageBytes != null && imageBytes.isNotEmpty) {
    return MultipartFile.fromBytes(
      imageBytes,
      filename: filename ?? _filenameForSubtype(subtype),
      contentType: contentType,
    );
  }
  if (imagePath != null && imagePath.isNotEmpty) {
    return MultipartFile.fromFile(
      imagePath,
      filename: filename,
      contentType: contentType,
    );
  }
  return null;
}

String? _resolveImageSubtype({String? imagePath, List<int>? imageBytes}) {
  final bytes = imageBytes ?? const <int>[];
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return 'png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'webp';
  }

  final lower = (imagePath ?? '').trim().toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'jpeg';
  if (lower.endsWith('.png')) return 'png';
  if (lower.endsWith('.webp')) return 'webp';
  return null;
}

String _filenameForSubtype(String? subtype) {
  switch (subtype) {
    case 'png':
      return 'upload.png';
    case 'webp':
      return 'upload.webp';
    case 'jpeg':
    default:
      return 'upload.jpg';
  }
}

String? _resolveFilename(String? imagePath) {
  final rawPath = (imagePath ?? '').trim();
  if (rawPath.isEmpty) return null;
  final normalized = rawPath.replaceAll('\\', '/');
  final idx = normalized.lastIndexOf('/');
  if (idx < 0 || idx == normalized.length - 1) return normalized;
  return normalized.substring(idx + 1);
}
