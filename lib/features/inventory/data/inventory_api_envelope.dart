import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/inventory/data/inventory_paginated_result.dart';

typedef InventoryJsonMap = Map<String, dynamic>;

class InventoryApiEnvelope {
  const InventoryApiEnvelope._();

  static InventoryJsonMap asMap(dynamic value) {
    return ApiContract.asJsonMap(value);
  }

  static InventoryJsonMap unwrapDataMap(
    dynamic body, {
    String fallbackMessage = 'Inventory request failed.',
  }) {
    final raw = asMap(body);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    final data = ApiContract.unwrapData(raw);
    final map = asMap(data);
    return map.isNotEmpty ? map : raw;
  }

  static List<InventoryJsonMap> unwrapDataList(
    dynamic body, {
    String fallbackMessage = 'Inventory request failed.',
  }) {
    final raw = asMap(body);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    final data = ApiContract.unwrapData(raw);
    final list = _extractListValue(data);
    if (list is! List) return const <InventoryJsonMap>[];
    return list
        .whereType<Map>()
        .map((entry) => asMap(entry))
        .toList(growable: false);
  }

  static InventoryPaginatedResult<InventoryJsonMap> unwrapPaginatedDataList(
    dynamic body, {
    String fallbackMessage = 'Inventory request failed.',
  }) {
    final raw = asMap(body);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    final data = ApiContract.unwrapData(raw);

    if (data is List) {
      final items = data
          .whereType<Map>()
          .map((entry) => asMap(entry))
          .toList(growable: false);
      return InventoryPaginatedResult<InventoryJsonMap>(
        items: items,
        limit: items.length,
        offset: 0,
        total: items.length,
        hasMore: false,
      );
    }

    final map = asMap(data);
    final items = _extractListValue(map['items'] ?? map) is List
        ? (_extractListValue(map['items'] ?? map) as List)
              .whereType<Map>()
              .map((entry) => asMap(entry))
              .toList(growable: false)
        : const <InventoryJsonMap>[];

    return InventoryPaginatedResult<InventoryJsonMap>(
      items: items,
      limit: _readInt(map['limit']) ?? items.length,
      offset: _readInt(map['offset']) ?? 0,
      total: _readInt(map['total']) ?? items.length,
      hasMore: _readBool(map['hasMore']) ?? false,
    );
  }

  static void _throwIfFailure(
    InventoryJsonMap raw, {
    required String fallbackMessage,
  }) {
    if (raw['success'] != false) return;
    final message = ApiContract.errorMessage(raw);
    throw ApiClientException(
      message: (message ?? '').trim().isNotEmpty
          ? message!.trim()
          : fallbackMessage,
      code: ApiContract.errorCode(raw),
      details: ApiContract.errorDetails(raw),
    );
  }

  static dynamic _extractListValue(dynamic value) {
    if (value is List) return value;
    if (value is! Map) return null;
    final map = asMap(value);
    if (map['data'] is List) return map['data'];
    if (map['items'] is List) return map['items'];
    if (map['entries'] is List) return map['entries'];
    if (map['data'] is Map || map['items'] is Map || map['entries'] is Map) {
      for (final nestedKey in const ['data', 'items', 'entries']) {
        final nested = _extractListValue(map[nestedKey]);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    switch (normalized) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        return null;
    }
  }
}
