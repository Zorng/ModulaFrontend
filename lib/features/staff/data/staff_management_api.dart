import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/staff/data/dto/shift_schedule_entry_dto.dart';
import 'package:modular_pos/features/staff/data/dto/staff_dto.dart';

final staffManagementApiProvider = Provider<StaffManagementApi>((ref) {
  final dio = ref.watch(dioProvider);
  return StaffManagementApi(dio);
});

class StaffManagementApi {
  StaffManagementApi(this._dio)
      : _prefix = dotenv.env['AUTH_API_PREFIX'] ?? '/v1/auth';

  final Dio _dio;
  final String _prefix;

  Future<List<StaffDto>> fetchStaffList({String? branchId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/staff',
      queryParameters: branchId != null && branchId.isNotEmpty
          ? {'branch_id': branchId}
          : null,
    );
    final root = response.data ?? const <String, dynamic>{};
    final raw = root['staff'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => StaffDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ShiftScheduleEntryDto>> fetchShiftSchedule({
    required String userId,
    required String branchId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/users/$userId/shifts',
      queryParameters: {'branch_id': branchId},
    );
    final root = response.data ?? const <String, dynamic>{};
    final raw = root['schedule'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ShiftScheduleEntryDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
