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

class AttendanceDateRange {
  const AttendanceDateRange({required this.start, required this.end});

  final String start;
  final String end;
}

enum AttendanceTab { check, history }

