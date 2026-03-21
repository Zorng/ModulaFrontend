class DiscountStatuses {
  const DiscountStatuses._();

  static const active = 'ACTIVE';
  static const inactive = 'INACTIVE';
  static const archived = 'ARCHIVED';

  static const values = <String>{active, inactive, archived};

  static String normalize(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    if (values.contains(normalized)) return normalized;
    return inactive;
  }
}
