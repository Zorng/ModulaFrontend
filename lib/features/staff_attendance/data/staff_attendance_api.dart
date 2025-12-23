import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';

final staffAttendanceApiProvider = Provider<StaffAttendanceApi>((ref) {
  final dio = ref.watch(dioProvider);
  return StaffAttendanceApi(dio);
});

class StaffAttendanceApi {
  StaffAttendanceApi(this._dio)
      : _prefix = dotenv.env['ATTENDANCE_API_PREFIX'] ?? '/v1/attendance';

  final Dio _dio;
  final String _prefix;

  Future<Map<String, dynamic>> fetchAllAttendance({
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
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> fetchMyAttendance({
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
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> fetchMyShiftSchedule({String? branchId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/me/shifts',
      queryParameters:
          branchId != null && branchId.isNotEmpty ? {'branchId': branchId} : null,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> checkIn({
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
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> checkOut({
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
    return response.data ?? const {};
  }
}
