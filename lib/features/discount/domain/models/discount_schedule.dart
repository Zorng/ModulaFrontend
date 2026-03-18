class DiscountSchedule {
  const DiscountSchedule({this.startAt, this.endAt});

  final DateTime? startAt;
  final DateTime? endAt;

  bool get isAlwaysOn => startAt == null && endAt == null;

  bool isEffectiveAt(DateTime instant) {
    final normalizedInstant = instant.toUtc();
    final normalizedStart = startAt?.toUtc();
    final normalizedEnd = endAt?.toUtc();
    if (normalizedStart != null &&
        normalizedInstant.isBefore(normalizedStart)) {
      return false;
    }
    if (normalizedEnd != null && normalizedInstant.isAfter(normalizedEnd)) {
      return false;
    }
    return true;
  }

  DiscountSchedule copyWith({
    DateTime? startAt,
    DateTime? endAt,
    bool clearStartAt = false,
    bool clearEndAt = false,
  }) {
    return DiscountSchedule(
      startAt: clearStartAt ? null : (startAt ?? this.startAt),
      endAt: clearEndAt ? null : (endAt ?? this.endAt),
    );
  }
}
