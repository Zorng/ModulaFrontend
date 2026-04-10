final RegExp _e164PhonePattern = RegExp(r'^\+[1-9]\d{7,14}$');
final RegExp _cambodiaLocalPhonePattern = RegExp(r'^0\d{8,9}$');
final RegExp _cambodiaIntlWithoutPlusPattern = RegExp(r'^855\d{8,9}$');

String normalizePhoneInput(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');
}

bool isAcceptedPhoneInput(String value) {
  final normalized = normalizePhoneInput(value);
  if (normalized.isEmpty) return false;
  return _e164PhonePattern.hasMatch(normalized) ||
      _cambodiaLocalPhonePattern.hasMatch(normalized) ||
      _cambodiaIntlWithoutPlusPattern.hasMatch(normalized);
}
