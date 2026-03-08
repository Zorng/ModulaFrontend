enum MembershipLifecycleStatus { invited, active, revoked, unknown }

MembershipLifecycleStatus parseMembershipLifecycleStatus(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'INVITED':
      return MembershipLifecycleStatus.invited;
    case 'ACTIVE':
      return MembershipLifecycleStatus.active;
    case 'REVOKED':
      return MembershipLifecycleStatus.revoked;
    default:
      return MembershipLifecycleStatus.unknown;
  }
}

String formatMembershipLifecycleStatus(MembershipLifecycleStatus status) {
  switch (status) {
    case MembershipLifecycleStatus.invited:
      return 'Invited';
    case MembershipLifecycleStatus.active:
      return 'Active';
    case MembershipLifecycleStatus.revoked:
      return 'Revoked';
    case MembershipLifecycleStatus.unknown:
      return 'Unknown';
  }
}

String formatRoleKey(String roleKey) {
  final normalized = roleKey.trim().toUpperCase();
  if (normalized.isEmpty) return 'Unknown';
  return normalized
      .split('_')
      .map((part) {
        if (part.isEmpty) return part;
        return '${part[0]}${part.substring(1).toLowerCase()}';
      })
      .join(' ');
}

class StaffMembershipSummary {
  const StaffMembershipSummary({
    required this.membershipId,
    required this.tenantId,
    required this.accountId,
    required this.roleKey,
    required this.membershipStatus,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.staffProfileStatus,
    required this.invitedAt,
    required this.acceptedAt,
    required this.rejectedAt,
    required this.revokedAt,
    required this.pendingBranchIds,
    required this.activeBranchIds,
  });

  final String membershipId;
  final String tenantId;
  final String accountId;
  final String roleKey;
  final MembershipLifecycleStatus membershipStatus;
  final String phone;
  final String? firstName;
  final String? lastName;
  final String? staffProfileStatus;
  final DateTime? invitedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? revokedAt;
  final List<String> pendingBranchIds;
  final List<String> activeBranchIds;

  String get displayName {
    final parts = <String>[
      if ((firstName ?? '').trim().isNotEmpty) firstName!.trim(),
      if ((lastName ?? '').trim().isNotEmpty) lastName!.trim(),
    ];
    final fullName = parts.join(' ').trim();
    if (fullName.isNotEmpty) return fullName;
    return phone.trim().isEmpty ? 'Unknown staff' : phone.trim();
  }

  String get roleLabel => formatRoleKey(roleKey);

  String get statusLabel => formatMembershipLifecycleStatus(membershipStatus);

  List<String> get branchIds => switch (membershipStatus) {
    MembershipLifecycleStatus.invited => pendingBranchIds,
    MembershipLifecycleStatus.active => activeBranchIds,
    MembershipLifecycleStatus.revoked => activeBranchIds.isNotEmpty
        ? activeBranchIds
        : pendingBranchIds,
    MembershipLifecycleStatus.unknown => activeBranchIds.isNotEmpty
        ? activeBranchIds
        : pendingBranchIds,
  };

  DateTime? get primaryLifecycleTimestamp => switch (membershipStatus) {
    MembershipLifecycleStatus.invited => invitedAt,
    MembershipLifecycleStatus.active => acceptedAt ?? invitedAt,
    MembershipLifecycleStatus.revoked => revokedAt ?? rejectedAt ?? invitedAt,
    MembershipLifecycleStatus.unknown => invitedAt ?? acceptedAt ?? revokedAt,
  };

  String get primaryLifecycleLabel => switch (membershipStatus) {
    MembershipLifecycleStatus.invited => 'Invited',
    MembershipLifecycleStatus.active => 'Accepted',
    MembershipLifecycleStatus.revoked => 'Revoked',
    MembershipLifecycleStatus.unknown => 'Updated',
  };
}

class StaffMembershipDetail extends StaffMembershipSummary {
  const StaffMembershipDetail({
    required super.membershipId,
    required super.tenantId,
    required super.accountId,
    required super.roleKey,
    required super.membershipStatus,
    required super.phone,
    required super.firstName,
    required super.lastName,
    required super.staffProfileStatus,
    required super.invitedAt,
    required super.acceptedAt,
    required super.rejectedAt,
    required super.revokedAt,
    required super.pendingBranchIds,
    required super.activeBranchIds,
  });
}

class StaffMembershipBranchAssignment {
  const StaffMembershipBranchAssignment({
    required this.membershipId,
    required this.tenantId,
    required this.membershipStatus,
    required this.pendingBranchIds,
    required this.activeBranchIds,
  });

  final String membershipId;
  final String tenantId;
  final MembershipLifecycleStatus membershipStatus;
  final List<String> pendingBranchIds;
  final List<String> activeBranchIds;

  List<String> get branchIds => switch (membershipStatus) {
    MembershipLifecycleStatus.invited => pendingBranchIds,
    MembershipLifecycleStatus.active => activeBranchIds,
    MembershipLifecycleStatus.revoked => activeBranchIds.isNotEmpty
        ? activeBranchIds
        : pendingBranchIds,
    MembershipLifecycleStatus.unknown => activeBranchIds.isNotEmpty
        ? activeBranchIds
        : pendingBranchIds,
  };
}

class MembershipInviteResult {
  const MembershipInviteResult({
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
  final MembershipLifecycleStatus status;
}

class MembershipRoleUpdateResult {
  const MembershipRoleUpdateResult({
    required this.membershipId,
    required this.tenantId,
    required this.roleKey,
  });

  final String membershipId;
  final String tenantId;
  final String roleKey;
}

class MembershipRevokeResult {
  const MembershipRevokeResult({
    required this.membershipId,
    required this.tenantId,
    required this.status,
  });

  final String membershipId;
  final String tenantId;
  final MembershipLifecycleStatus status;
}
