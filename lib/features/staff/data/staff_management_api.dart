import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';

final staffManagementApiProvider = Provider<StaffManagementApi>((ref) {
  final dio = ref.watch(dioProvider);
  return StaffManagementApi(dio);
});

class StaffManagementApi {
  StaffManagementApi(this._dio)
      : _prefix = dotenv.env['AUTH_API_PREFIX'] ?? '/v1/auth';

  final Dio _dio;
  final String _prefix;

  Future<Map<String, dynamic>> fetchStaffList({String? branchId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/staff',
      queryParameters: branchId != null && branchId.isNotEmpty
          ? {'branch_id': branchId}
          : null,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> fetchShiftSchedule({
    required String userId,
    required String branchId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/users/$userId/shifts',
      queryParameters: {'branch_id': branchId},
    );
    return response.data ?? const {};
  }
}
