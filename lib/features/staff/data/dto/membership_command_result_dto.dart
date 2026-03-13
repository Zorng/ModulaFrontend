class MembershipInviteResultDto {
  const MembershipInviteResultDto({
    required this.membershipId,
    required this.tenantId,
    required this.accountId,
    required this.phone,
    required this.roleKey,
    required this.status,
  });

  final String membershipId;
  final String tenantId;
  final String accountId;
  final String phone;
  final String roleKey;
  final String status;

  factory MembershipInviteResultDto.fromJson(Map<String, dynamic> json) {
    return MembershipInviteResultDto(
      membershipId: json['membershipId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      accountId: json['accountId']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      roleKey: json['roleKey']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class MembershipRoleUpdateResultDto {
  const MembershipRoleUpdateResultDto({
    required this.membershipId,
    required this.tenantId,
    required this.roleKey,
  });

  final String membershipId;
  final String tenantId;
  final String roleKey;

  factory MembershipRoleUpdateResultDto.fromJson(Map<String, dynamic> json) {
    return MembershipRoleUpdateResultDto(
      membershipId: json['membershipId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      roleKey: json['roleKey']?.toString() ?? '',
    );
  }
}

class MembershipRevokeResultDto {
  const MembershipRevokeResultDto({
    required this.membershipId,
    required this.tenantId,
    required this.status,
  });

  final String membershipId;
  final String tenantId;
  final String status;

  factory MembershipRevokeResultDto.fromJson(Map<String, dynamic> json) {
    return MembershipRevokeResultDto(
      membershipId: json['membershipId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}
