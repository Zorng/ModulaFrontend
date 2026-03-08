import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/data/membership_invitation_api.dart';
import 'package:modular_pos/features/auth/domain/models/membership_invitation.dart';

abstract class MembershipInvitationRepository {
  Future<List<MembershipInvitation>> listInvitations({
    String? accessTokenOverride,
  });

  Future<MembershipInvitationAcceptResult> acceptInvitation({
    required String membershipId,
    String? intentId,
    String? accessTokenOverride,
  });

  Future<MembershipInvitationRejectResult> rejectInvitation({
    required String membershipId,
    String? intentId,
    String? accessTokenOverride,
  });
}

final membershipInvitationRepositoryProvider =
    Provider<MembershipInvitationRepository>((ref) {
      final api = ref.read(membershipInvitationApiProvider);
      return RemoteMembershipInvitationRepository(api);
    });

class RemoteMembershipInvitationRepository
    implements MembershipInvitationRepository {
  const RemoteMembershipInvitationRepository(this._api);

  final MembershipInvitationApi _api;

  @override
  Future<List<MembershipInvitation>> listInvitations({
    String? accessTokenOverride,
  }) async {
    final dtos = await _api.listInvitations(
      accessTokenOverride: accessTokenOverride,
    );
    return dtos
        .map(
          (dto) => MembershipInvitation(
            membershipId: dto.membershipId,
            tenantId: dto.tenantId,
            tenantName: dto.tenantName,
            roleKey: dto.roleKey,
            invitedAt: dto.invitedAt,
            invitedByMembershipId: dto.invitedByMembershipId,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<MembershipInvitationAcceptResult> acceptInvitation({
    required String membershipId,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    final dto = await _api.acceptInvitation(
      membershipId: membershipId,
      intentId: intentId,
      accessTokenOverride: accessTokenOverride,
    );
    return MembershipInvitationAcceptResult(
      membershipId: dto.membershipId,
      tenantId: dto.tenantId,
      status: parseMembershipInvitationStatus(dto.status),
      activeBranchIds: dto.activeBranchIds,
    );
  }

  @override
  Future<MembershipInvitationRejectResult> rejectInvitation({
    required String membershipId,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    final dto = await _api.rejectInvitation(
      membershipId: membershipId,
      intentId: intentId,
      accessTokenOverride: accessTokenOverride,
    );
    return MembershipInvitationRejectResult(
      membershipId: dto.membershipId,
      tenantId: dto.tenantId,
      status: parseMembershipInvitationStatus(dto.status),
    );
  }
}
