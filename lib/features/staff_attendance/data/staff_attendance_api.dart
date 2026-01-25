import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/staff_attendance/data/dto/attendance_record_dto.dart';
import 'package:modular_pos/features/staff_attendance/data/dto/attendance_shift_schedule_dto.dart';
import 'package:modular_pos/features/staff_attendance/data/dto/check_in_result_dto.dart';

final staffAttendanceApiProvider = Provider<StaffAttendanceApi>((ref) {
  final dio = ref.watch(dioProvider);
  return StaffAttendanceApi(dio);
});

class StaffAttendanceApi {
  StaffAttendanceApi(this._dio)
      : _prefix = dotenv.env['ATTENDANCE_API_PREFIX'] ?? '/v1/attendance';

  final Dio _dio;
  final String _prefix;

  Future<List<AttendanceRecordDto>> fetchAllAttendance({
    String? branchId,
    String? employeeId,
    String? from,
    String? to,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/all',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (employeeId != null && employeeId.isNotEmpty) 'employeeId': employeeId,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        'limit': limit,
        'offset': offset,
      },
    );
    return _parseAttendanceList(response.data);
  }

  Future<List<AttendanceRecordDto>> fetchMyAttendance({
    String? branchId,
    String? from,
    String? to,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/me',
      queryParameters: {
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        'limit': limit,
        'offset': offset,
      },
    );
    return _parseAttendanceList(response.data);
  }

  Future<List<AttendanceShiftScheduleEntryDto>> fetchMyShiftSchedule({
    String? branchId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/me/shifts',
      queryParameters:
          branchId != null && branchId.isNotEmpty ? {'branchId': branchId} : null,
    );
    final root = response.data ?? const <String, dynamic>{};
    final raw = root['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AttendanceShiftScheduleEntryDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CheckInResultDto?> checkIn({
    required String occurredAt,
    Map<String, num>? location,
    String? shiftStatus,
    int? earlyMinutes,
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/check-in',
      data: {
        'occurredAt': occurredAt,
        if (location != null) 'location': location,
        if (shiftStatus != null && shiftStatus.isNotEmpty)
          'shiftStatus': shiftStatus,
        if (earlyMinutes != null) 'earlyMinutes': earlyMinutes,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    final root = response.data ?? const <String, dynamic>{};
    final data = root['data'];
    if (data is! Map<String, dynamic>) return null;
    return CheckInResultDto.fromJson(data);
  }

  Future<AttendanceRecordDto?> checkOut({
    required String occurredAt,
    Map<String, num>? location,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/check-out',
      data: {
        'occurredAt': occurredAt,
        if (location != null) 'location': location,
      },
    );
    final root = response.data ?? const <String, dynamic>{};
    final data = root['data'];
    if (data is Map<String, dynamic>) return AttendanceRecordDto.fromJson(data);
    return null;
  }

  List<AttendanceRecordDto> _parseAttendanceList(Map<String, dynamic>? payload) {
    final root = payload ?? const <String, dynamic>{};
    final raw = root['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AttendanceRecordDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
