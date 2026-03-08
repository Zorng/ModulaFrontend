import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/staff/data/api/staff_api_helpers.dart';
import 'package:modular_pos/features/staff/data/dto/staff_membership_branch_assignment_dto.dart';

final staffBranchAssignmentApiProvider = Provider<StaffBranchAssignmentApi>((
  ref,
) {
  final dio = ref.read(dioProvider);
  return StaffBranchAssignmentApi(dio);
});

class StaffBranchAssignmentApi {
  StaffBranchAssignmentApi(this._dio);

  final Dio _dio;
  static const _prefix = '/v0/hr/staff/memberships';

  Future<StaffMembershipBranchAssignmentDto> fetchBranchAssignments(
    String membershipId,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_prefix/${membershipId.trim()}/branches',
      );
      final data = StaffApiHelpers.unwrapMap(response.data);
      return StaffMembershipBranchAssignmentDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load branch assignments.',
      );
    }
  }

  Future<StaffMembershipBranchAssignmentDto> assignBranches({
    required String membershipId,
    required List<String> branchIds,
    String? intentId,
  }) async {
    final normalizedBranchIds = branchIds
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final payload = {'branchIds': normalizedBranchIds};
    try {
      final response = await _dio.post<dynamic>(
        '$_prefix/${membershipId.trim()}/branches',
        data: payload,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'hr.staff.branch.assign',
            payload: {'membershipId': membershipId.trim(), ...payload},
            intentId: (intentId ?? '').trim().isEmpty ? null : intentId!.trim(),
            scope: IdempotencyScope.tenant,
          ),
        ),
      );
      final data = StaffApiHelpers.unwrapMap(response.data);
      return StaffMembershipBranchAssignmentDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to save branch assignments.',
      );
    }
  }
}
