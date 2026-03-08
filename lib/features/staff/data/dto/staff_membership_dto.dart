import 'package:modular_pos/features/staff/data/api/staff_api_helpers.dart';

class StaffMembershipDto {
  const StaffMembershipDto({
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
  final String membershipStatus;
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

  factory StaffMembershipDto.fromJson(Map<String, dynamic> json) {
    return StaffMembershipDto(
      membershipId: json['membershipId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      accountId: json['accountId']?.toString() ?? '',
      roleKey: json['roleKey']?.toString() ?? '',
      membershipStatus: json['membershipStatus']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      staffProfileStatus: json['staffProfileStatus']?.toString(),
      invitedAt: StaffApiHelpers.parseDateTime(json['invitedAt']),
      acceptedAt: StaffApiHelpers.parseDateTime(json['acceptedAt']),
      rejectedAt: StaffApiHelpers.parseDateTime(json['rejectedAt']),
      revokedAt: StaffApiHelpers.parseDateTime(json['revokedAt']),
      pendingBranchIds: StaffApiHelpers.stringList(json['pendingBranchIds']),
      activeBranchIds: StaffApiHelpers.stringList(json['activeBranchIds']),
    );
  }
}
