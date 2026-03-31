DateTime resolveRestockOccurredAt(String? value, {DateTime? referenceTime}) {
  final trimmed = value?.trim() ?? '';
  final reference = referenceTime ?? DateTime.now();
  if (trimmed.isEmpty) {
    return reference;
  }
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) {
    return reference;
  }
  if (_isDateOnlyInput(trimmed)) {
    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
      reference.hour,
      reference.minute,
      reference.second,
      reference.millisecond,
      reference.microsecond,
    );
  }
  return parsed;
}

String? restockOccurredAtToUtcIso(String? value, {DateTime? referenceTime}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  return resolveRestockOccurredAt(
    trimmed,
    referenceTime: referenceTime,
  ).toUtc().toIso8601String();
}

bool _isDateOnlyInput(String value) =>
    RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);
