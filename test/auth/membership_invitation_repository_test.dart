import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/auth/data/dto/membership_invitation_dto.dart';
import 'package:modular_pos/features/auth/data/membership_invitation_api.dart';
import 'package:modular_pos/features/auth/data/membership_invitation_repository.dart';
import 'package:modular_pos/features/auth/domain/models/membership_invitation.dart';

class _MockMembershipInvitationApi extends Mock
    implements MembershipInvitationApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(const MembershipInvitationDto(
      membershipId: '',
      tenantId: '',
      tenantName: '',
      roleKey: '',
      invitedAt: null,
      invitedByMembershipId: '',
    ));
  });

  test('repository maps invitation DTOs into domain models', () async {
    final api = _MockMembershipInvitationApi();
    when(() => api.listInvitations(accessTokenOverride: any(named: 'accessTokenOverride'))).thenAnswer(
      (_) async => const [
        MembershipInvitationDto(
          membershipId: 'membership-1',
          tenantId: 'tenant-1',
          tenantName: 'X Cafe',
          roleKey: 'CASHIER',
          invitedAt: null,
          invitedByMembershipId: 'membership-owner',
        ),
      ],
    );
    when(
      () => api.acceptInvitation(
        membershipId: any(named: 'membershipId'),
        intentId: any(named: 'intentId'),
        accessTokenOverride: any(named: 'accessTokenOverride'),
      ),
    ).thenAnswer(
      (_) async => const MembershipInvitationAcceptResultDto(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        status: 'ACTIVE',
        activeBranchIds: ['branch-1'],
      ),
    );
    when(
      () => api.rejectInvitation(
        membershipId: any(named: 'membershipId'),
        intentId: any(named: 'intentId'),
        accessTokenOverride: any(named: 'accessTokenOverride'),
      ),
    ).thenAnswer(
      (_) async => const MembershipInvitationRejectResultDto(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        status: 'REVOKED',
      ),
    );

    final repository = RemoteMembershipInvitationRepository(
      api,
    );

    final invitations = await repository.listInvitations();
    final accepted = await repository.acceptInvitation(
      membershipId: 'membership-1',
    );
    final rejected = await repository.rejectInvitation(
      membershipId: 'membership-1',
    );

    expect(invitations, hasLength(1));
    expect(invitations.first.tenantName, 'X Cafe');
    expect(accepted.status, MembershipInvitationStatus.active);
    expect(accepted.activeBranchIds, ['branch-1']);
    expect(rejected.status, MembershipInvitationStatus.revoked);
  });
}
