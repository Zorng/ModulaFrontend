import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_api.dart';
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
    final payload = await _api.fetchAllAttendance(
      branchId: branchId,
      employeeId: employeeId,
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
    final raw = payload['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => _mapRecord(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<AttendanceRecord>> fetchMyAttendance({
    String? branchId,
    String? from,
    String? to,
    int limit = 100,
    int offset = 0,
  }) async {
    final payload = await _api.fetchMyAttendance(
      branchId: branchId,
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
    final raw = payload['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => _mapRecord(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<AttendanceShiftScheduleEntry>> fetchMyShiftSchedule({
    String? branchId,
  }) async {
    final payload = await _api.fetchMyShiftSchedule(branchId: branchId);
    final raw = payload['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => _mapShiftSchedule(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<AttendanceRecord?> checkIn({
    required String occurredAt,
    Map<String, num>? location,
    String? shiftStatus,
    int? earlyMinutes,
    String? note,
  }) async {
    final payload = await _api.checkIn(
      occurredAt: occurredAt,
      location: location,
      shiftStatus: shiftStatus,
      earlyMinutes: earlyMinutes,
      note: note,
    );
    final data = payload['data'];
    if (data is! Map) return null;
    final status = data['status']?.toString() ?? '';
    if (status == 'CHECKED_IN') {
      final record = data['record'];
      if (record is Map) {
        return _mapRecord(Map<String, dynamic>.from(record));
      }
    }
    return null;
  }

  Future<AttendanceRecord?> checkOut({
    required String occurredAt,
    Map<String, num>? location,
  }) async {
    final payload = await _api.checkOut(
      occurredAt: occurredAt,
      location: location,
    );
    final data = payload['data'];
    if (data is Map) {
      return _mapRecord(Map<String, dynamic>.from(data));
    }
    return null;
  }

  AttendanceRecord _mapRecord(Map<String, dynamic> json) {
    final location = json['location'];
    AttendanceLocation? parsedLocation;
    if (location is Map<String, dynamic>) {
      final lat = location['lat'];
      final lng = location['lng'];
      if (lat is num && lng is num) {
        parsedLocation = AttendanceLocation(lat: lat.toDouble(), lng: lng.toDouble());
      }
    }

    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      occurredAt: DateTime.tryParse(json['occurredAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      location: parsedLocation,
    );
  }

  AttendanceShiftScheduleEntry _mapShiftSchedule(
    Map<String, dynamic> json,
  ) {
    return AttendanceShiftScheduleEntry(
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? -1,
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      isOff: json['isOff'] as bool? ?? false,
    );
  }
}
