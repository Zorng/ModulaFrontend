class ShiftScheduleEntryDto {
  const ShiftScheduleEntryDto({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isOff,
  });

  final int dayOfWeek;
  final String? startTime;
  final String? endTime;
  final bool isOff;

  factory ShiftScheduleEntryDto.fromJson(Map<String, dynamic> json) {
    return ShiftScheduleEntryDto(
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? -1,
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      isOff: json['is_off'] as bool? ?? false,
    );
  }
}

