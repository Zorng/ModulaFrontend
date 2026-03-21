class DiscountScopes {
  const DiscountScopes._();

  static const item = 'ITEM';
  static const branchWide = 'BRANCH_WIDE';

  static const values = <String>{item, branchWide};

  static String normalize(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    if (normalized == 'BRANCH' || normalized == 'SALE') {
      return branchWide;
    }
    if (values.contains(normalized)) return normalized;
    return item;
  }
}
