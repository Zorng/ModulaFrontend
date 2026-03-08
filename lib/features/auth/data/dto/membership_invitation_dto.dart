class MembershipInvitationDto {
  const MembershipInvitationDto({
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

  factory MembershipInvitationDto.fromJson(Map<String, dynamic> json) {
    return MembershipInvitationDto(
      membershipId: json['membershipId']?.toString().trim() ?? '',
      tenantId: json['tenantId']?.toString().trim() ?? '',
      tenantName: json['tenantName']?.toString().trim() ?? '',
      roleKey: json['roleKey']?.toString().trim() ?? '',
      invitedAt: DateTime.tryParse(json['invitedAt']?.toString().trim() ?? ''),
      invitedByMembershipId:
          json['invitedByMembershipId']?.toString().trim() ?? '',
    );
  }
}

class MembershipInvitationAcceptResultDto {
  const MembershipInvitationAcceptResultDto({
    required this.membershipId,
    required this.tenantId,
    required this.status,
    required this.activeBranchIds,
  });

  final String membershipId;
  final String tenantId;
  final String status;
  final List<String> activeBranchIds;

  factory MembershipInvitationAcceptResultDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return MembershipInvitationAcceptResultDto(
      membershipId: json['membershipId']?.toString().trim() ?? '',
      tenantId: json['tenantId']?.toString().trim() ?? '',
      status: json['status']?.toString().trim() ?? '',
      activeBranchIds: (json['activeBranchIds'] is List)
          ? (json['activeBranchIds'] as List)
                .map((entry) => entry?.toString().trim() ?? '')
                .where((entry) => entry.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
    );
  }
}

class MembershipInvitationRejectResultDto {
  const MembershipInvitationRejectResultDto({
    required this.membershipId,
    required this.tenantId,
    required this.status,
  });

  final String membershipId;
  final String tenantId;
  final String status;

  factory MembershipInvitationRejectResultDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return MembershipInvitationRejectResultDto(
      membershipId: json['membershipId']?.toString().trim() ?? '',
      tenantId: json['tenantId']?.toString().trim() ?? '',
      status: json['status']?.toString().trim() ?? '',
    );
  }
}
