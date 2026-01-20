import 'package:modular_pos/features/staff_attendance/data/dto/attendance_record_dto.dart';

class CheckInResultDto {
  const CheckInResultDto({
    required this.status,
    required this.record,
  });

  final String status;
  final AttendanceRecordDto? record;

  factory CheckInResultDto.fromJson(Map<String, dynamic> json) {
    final recordRaw = json['record'];
    return CheckInResultDto(
      status: json['status']?.toString() ?? '',
      record: recordRaw is Map<String, dynamic>
          ? AttendanceRecordDto.fromJson(recordRaw)
          : null,
    );
  }
}

