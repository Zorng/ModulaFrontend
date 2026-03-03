import 'package:modular_pos/core/network/api_contract.dart';

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
}
