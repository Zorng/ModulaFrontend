class AttendanceShiftScheduleEntryDto {
  const AttendanceShiftScheduleEntryDto({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isOff,
  });

  final int dayOfWeek;
  final String? startTime;
  final String? endTime;
  final bool isOff;

  factory AttendanceShiftScheduleEntryDto.fromJson(Map<String, dynamic> json) {
    return AttendanceShiftScheduleEntryDto(
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? -1,
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      isOff: json['isOff'] as bool? ?? false,
    );
  }
}

