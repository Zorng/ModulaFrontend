import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/staff/data/api/staff_api_helpers.dart';
import 'package:modular_pos/features/staff/data/dto/staff_attendance_review_record_dto.dart';

final staffAttendanceReviewApiProvider = Provider<StaffAttendanceReviewApi>((
  ref,
) {
  final dio = ref.read(dioProvider);
  return StaffAttendanceReviewApi(dio);
});

class StaffAttendanceReviewApi {
  StaffAttendanceReviewApi(this._dio);

  final Dio _dio;
  static const _prefix = '/v0/attendance/tenant';

  Future<List<StaffAttendanceReviewRecordDto>> fetchTenantAttendance({
    String? branchId,
    String? accountId,
    String? occurredFrom,
    String? occurredTo,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        _prefix,
        queryParameters: {
          if ((branchId ?? '').trim().isNotEmpty) 'branchId': branchId!.trim(),
          if ((accountId ?? '').trim().isNotEmpty)
            'accountId': accountId!.trim(),
          if ((occurredFrom ?? '').trim().isNotEmpty)
            'occurredFrom': occurredFrom!.trim(),
          if ((occurredTo ?? '').trim().isNotEmpty)
            'occurredTo': occurredTo!.trim(),
          'limit': limit,
          'offset': offset,
        },
      );
      final list = StaffApiHelpers.unwrapPagedItems(response.data);
      return list
          .map(StaffAttendanceReviewRecordDto.fromJson)
          .toList(growable: false);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load attendance records.',
      );
    }
  }
}
