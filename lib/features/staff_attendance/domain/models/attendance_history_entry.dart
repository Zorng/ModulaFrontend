class AttendanceHistoryEntry {
  const AttendanceHistoryEntry({
    required this.date,
    this.checkInAt,
    this.checkOutAt,
  });

  final String date;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
}
