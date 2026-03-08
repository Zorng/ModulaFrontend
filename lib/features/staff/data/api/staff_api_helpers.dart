import 'package:modular_pos/core/network/api_contract.dart';

typedef StaffJsonMap = Map<String, dynamic>;

class StaffApiHelpers {
  const StaffApiHelpers._();

  static StaffJsonMap unwrapMap(dynamic body) {
    final unwrapped = ApiContract.unwrapData(body);
    return ApiContract.asJsonMap(unwrapped);
  }

  static List<StaffJsonMap> unwrapList(dynamic body) {
    final unwrapped = ApiContract.unwrapData(body);
    if (unwrapped is List) {
      return unwrapped
          .whereType<Map>()
          .map((entry) => ApiContract.asJsonMap(entry))
          .toList(growable: false);
    }
    return const <StaffJsonMap>[];
  }

  static List<String> stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? parseDateTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static double? parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  static int? parseInt(dynamic value) {
    if (value is num) return value.toInt();
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }
}
