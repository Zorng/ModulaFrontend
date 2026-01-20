import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_api.dart';
import 'package:modular_pos/features/staff_attendance/data/dto/attendance_record_dto.dart';
import 'package:modular_pos/features/staff_attendance/data/dto/attendance_shift_schedule_dto.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_shift_schedule.dart';

final staffAttendanceRepositoryProvider =
    Provider<StaffAttendanceRepository>((ref) {
  final api = ref.watch(staffAttendanceApiProvider);
  return StaffAttendanceRepository(api);
});

class StaffAttendanceRepository {
  StaffAttendanceRepository(this._api);

  final StaffAttendanceApi _api;

  Future<List<AttendanceRecord>> fetchAdminAttendance({
    String? branchId,
    String? employeeId,
    String? from,
    String? to,
    int limit = 100,
    int offset = 0,
  }) async {
    final records = await _api.fetchAllAttendance(
      branchId: branchId,
      employeeId: employeeId,
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
    return records.map(_mapRecord).toList();
  }

  Future<List<AttendanceRecord>> fetchMyAttendance({
    String? branchId,
    String? from,
    String? to,
    int limit = 100,
    int offset = 0,
  }) async {
    final records = await _api.fetchMyAttendance(
      branchId: branchId,
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
    return records.map(_mapRecord).toList();
  }

  Future<List<AttendanceShiftScheduleEntry>> fetchMyShiftSchedule({
    String? branchId,
  }) async {
    final schedule = await _api.fetchMyShiftSchedule(branchId: branchId);
    return schedule.map(_mapShiftSchedule).toList();
  }

  Future<AttendanceRecord?> checkIn({
    required String occurredAt,
    Map<String, num>? location,
    String? shiftStatus,
    int? earlyMinutes,
    String? note,
  }) async {
    final result = await _api.checkIn(
      occurredAt: occurredAt,
      location: location,
      shiftStatus: shiftStatus,
      earlyMinutes: earlyMinutes,
      note: note,
    );
    if (result == null) return null;
    if (result.status == 'CHECKED_IN' && result.record != null) {
      return _mapRecord(result.record!);
    }
    return null;
  }

  Future<AttendanceRecord?> checkOut({
    required String occurredAt,
    Map<String, num>? location,
  }) async {
    final record = await _api.checkOut(
      occurredAt: occurredAt,
      location: location,
    );
    if (record == null) return null;
    return _mapRecord(record);
  }

  AttendanceRecord _mapRecord(AttendanceRecordDto dto) {
    AttendanceLocation? parsedLocation;
    final location = dto.location;
    if (location != null) {
      parsedLocation = AttendanceLocation(lat: location.lat, lng: location.lng);
    }
    return AttendanceRecord(
      id: dto.id,
      tenantId: dto.tenantId,
      branchId: dto.branchId,
      employeeId: dto.employeeId,
      type: dto.type,
      occurredAt: dto.occurredAt.toLocal(),
      createdAt: dto.createdAt.toLocal(),
      location: parsedLocation,
    );
  }

  AttendanceShiftScheduleEntry _mapShiftSchedule(
    AttendanceShiftScheduleEntryDto dto,
  ) {
    return AttendanceShiftScheduleEntry(
      dayOfWeek: dto.dayOfWeek,
      startTime: dto.startTime,
      endTime: dto.endTime,
      isOff: dto.isOff,
    );
  }
}
