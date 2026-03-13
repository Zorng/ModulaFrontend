enum MembershipInvitationStatus { invited, active, revoked, unknown }

MembershipInvitationStatus parseMembershipInvitationStatus(String value) {
  switch (value.trim().toUpperCase()) {
    case 'INVITED':
      return MembershipInvitationStatus.invited;
    case 'ACTIVE':
      return MembershipInvitationStatus.active;
    case 'REVOKED':
      return MembershipInvitationStatus.revoked;
    default:
      return MembershipInvitationStatus.unknown;
  }
}

class MembershipInvitation {
  const MembershipInvitation({
    required this.membershipId,
    required this.tenantId,
    required this.tenantName,
    required this.roleKey,
    required this.invitedAt,
    required this.invitedByMembershipId,
  });

  final String membershipId;
  final String tenantId;
  final String tenantName;
  final String roleKey;
  final DateTime? invitedAt;
  final String invitedByMembershipId;
}

class MembershipInvitationAcceptResult {
  const MembershipInvitationAcceptResult({
    required this.membershipId,
    required this.tenantId,
    required this.status,
    required this.activeBranchIds,
  });

  final String membershipId;
  final String tenantId;
  final MembershipInvitationStatus status;
  final List<String> activeBranchIds;
}

class MembershipInvitationRejectResult {
  const MembershipInvitationRejectResult({
    required this.membershipId,
    required this.tenantId,
    required this.status,
  });

  final String membershipId;
  final String tenantId;
  final MembershipInvitationStatus status;
}
