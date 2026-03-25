Map<String, dynamic> asDtoMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> asDtoList(dynamic value) {
  if (value is List) {
    return value.map(asDtoMap).toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

String dtoToString(dynamic value) {
  return value?.toString() ?? '';
}

String? dtoToNullableString(dynamic value) {
  final raw = dtoToString(value).trim();
  return raw.isEmpty ? null : raw;
}

double dtoToDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

double? dtoToNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int dtoToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

bool dtoToBool(dynamic value) {
  if (value is bool) return value;
  final raw = value?.toString().trim().toLowerCase() ?? '';
  return raw == 'true' || raw == '1';
}

DateTime? dtoToDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

List<String> dtoToStringList(dynamic value) {
  if (value is List) {
    return value
        .map((entry) => entry?.toString() ?? '')
        .toList(growable: false);
  }
  return const <String>[];
}
