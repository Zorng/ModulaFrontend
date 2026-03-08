import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/auth/data/dto/membership_invitation_dto.dart';

final membershipInvitationApiProvider = Provider<MembershipInvitationApi>((ref) {
  final dio = ref.read(dioProvider);
  return MembershipInvitationApi(dio);
});

class MembershipInvitationApi {
  MembershipInvitationApi(this._dio);

  final Dio _dio;
  static const _prefix = '/v0/org/memberships';

  Future<List<MembershipInvitationDto>> listInvitations({
    String? accessTokenOverride,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_prefix/invitations',
        options: _optionsWithAccessToken(accessTokenOverride),
      );
      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      final invitations = data['invitations'];
      if (invitations is! List) return const <MembershipInvitationDto>[];
      return invitations
          .whereType<Map>()
          .map((entry) => MembershipInvitationDto.fromJson(
                ApiContract.asJsonMap(entry),
              ))
          .toList(growable: false);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load invitations.',
      );
    }
  }

  Future<MembershipInvitationAcceptResultDto> acceptInvitation({
    required String membershipId,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    final normalizedMembershipId = membershipId.trim();
    try {
      final response = await _dio.post<dynamic>(
        '$_prefix/invitations/$normalizedMembershipId/accept',
        options: _optionsWithAccessToken(
          accessTokenOverride,
          options: withIdempotency(
            request: IdempotencyRequest(
              actionKey: 'org.membership.invitation.accept',
              payload: {'membershipId': normalizedMembershipId},
              intentId: (intentId ?? '').trim().isEmpty
                  ? null
                  : intentId!.trim(),
              scope: IdempotencyScope.account,
            ),
          ),
        ),
      );
      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      return MembershipInvitationAcceptResultDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to accept invitation.',
      );
    }
  }

  Future<MembershipInvitationRejectResultDto> rejectInvitation({
    required String membershipId,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    final normalizedMembershipId = membershipId.trim();
    try {
      final response = await _dio.post<dynamic>(
        '$_prefix/invitations/$normalizedMembershipId/reject',
        options: _optionsWithAccessToken(
          accessTokenOverride,
          options: withIdempotency(
            request: IdempotencyRequest(
              actionKey: 'org.membership.invitation.revoke',
              payload: {'membershipId': normalizedMembershipId},
              intentId: (intentId ?? '').trim().isEmpty
                  ? null
                  : intentId!.trim(),
              scope: IdempotencyScope.account,
            ),
          ),
        ),
      );
      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      return MembershipInvitationRejectResultDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to reject invitation.',
      );
    }
  }

  Options? _optionsWithAccessToken(
    String? accessTokenOverride, {
    Options? options,
  }) {
    final token = (accessTokenOverride ?? '').trim();
    if (token.isEmpty) return options;
    final current = options ?? Options();
    final headers = <String, dynamic>{
      ...(current.headers ?? const <String, dynamic>{}),
      'Authorization': 'Bearer $token',
    };
    return current.copyWith(headers: headers);
  }
}
