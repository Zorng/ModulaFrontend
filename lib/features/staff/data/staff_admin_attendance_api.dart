import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/staff/data/dto/staff_attendance_record_dto.dart';

final staffAdminAttendanceApiProvider = Provider<StaffAdminAttendanceApi>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return StaffAdminAttendanceApi(dio);
});

class StaffAdminAttendanceApi {
  StaffAdminAttendanceApi(this._dio)
    : _prefix = dotenv.env['ATTENDANCE_API_PREFIX'] ?? '/v1/attendance';

  final Dio _dio;
  final String _prefix;

  Future<List<StaffAttendanceRecordDto>> fetchAttendanceRecords({
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
        if (employeeId != null && employeeId.isNotEmpty)
          'employeeId': employeeId,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        'limit': limit,
        'offset': offset,
      },
    );
    return _parseAttendanceList(response.data);
  }

  List<StaffAttendanceRecordDto> _parseAttendanceList(
    Map<String, dynamic>? payload,
  ) {
    final root = payload ?? const <String, dynamic>{};
    final raw = root['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (e) =>
              StaffAttendanceRecordDto.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }
}
