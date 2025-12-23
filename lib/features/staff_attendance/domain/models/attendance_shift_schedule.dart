class AttendanceShiftScheduleEntry {
  const AttendanceShiftScheduleEntry({
    required this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.isOff = false,
  });

  final int dayOfWeek; // 0=Sun ... 6=Sat
  final String? startTime;
  final String? endTime;
  final bool isOff;
}
