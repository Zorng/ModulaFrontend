import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/staff/data/api/staff_api_helpers.dart';
import 'package:modular_pos/features/staff/data/dto/membership_command_result_dto.dart';

final membershipCommandApiProvider = Provider<MembershipCommandApi>((ref) {
  final dio = ref.read(dioProvider);
  return MembershipCommandApi(dio);
});

class MembershipCommandApi {
  MembershipCommandApi(this._dio);

  final Dio _dio;
  static const _prefix = '/v0/org/memberships';

  Future<MembershipInviteResultDto> inviteMember({
    required String tenantId,
    required String phone,
    required String roleKey,
    String? intentId,
  }) async {
    final payload = {
      'tenantId': tenantId.trim(),
      'phone': phone.trim(),
      'roleKey': roleKey.trim().toUpperCase(),
    };
    try {
      final response = await _dio.post<dynamic>(
        '$_prefix/invite',
        data: payload,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'org.membership.invite',
            payload: payload,
            intentId: (intentId ?? '').trim().isEmpty ? null : intentId!.trim(),
            scope: IdempotencyScope.tenant,
          ),
        ),
      );
      final data = StaffApiHelpers.unwrapMap(response.data);
      return MembershipInviteResultDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to invite team member.',
      );
    }
  }

  Future<MembershipRoleUpdateResultDto> changeRole({
    required String membershipId,
    required String roleKey,
    String? intentId,
  }) async {
    final payload = {'roleKey': roleKey.trim().toUpperCase()};
    try {
      final response = await _dio.post<dynamic>(
        '$_prefix/${membershipId.trim()}/role',
        data: payload,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'org.membership.role.change',
            payload: {'membershipId': membershipId.trim(), ...payload},
            intentId: (intentId ?? '').trim().isEmpty ? null : intentId!.trim(),
            scope: IdempotencyScope.tenant,
          ),
        ),
      );
      final data = StaffApiHelpers.unwrapMap(response.data);
      return MembershipRoleUpdateResultDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to update membership role.',
      );
    }
  }

  Future<MembershipRevokeResultDto> revokeMembership({
    required String membershipId,
    String? intentId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_prefix/${membershipId.trim()}/revoke',
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'org.membership.revoke',
            payload: {'membershipId': membershipId.trim()},
            intentId: (intentId ?? '').trim().isEmpty ? null : intentId!.trim(),
            scope: IdempotencyScope.tenant,
          ),
        ),
      );
      final data = StaffApiHelpers.unwrapMap(response.data);
      return MembershipRevokeResultDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to revoke membership.',
      );
    }
  }
}
