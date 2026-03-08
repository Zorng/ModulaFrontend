import 'package:modular_pos/features/staff/data/api/staff_api_helpers.dart';

class StaffMembershipBranchAssignmentDto {
  const StaffMembershipBranchAssignmentDto({
    required this.membershipId,
    required this.tenantId,
    required this.membershipStatus,
    required this.pendingBranchIds,
    required this.activeBranchIds,
  });

  final String membershipId;
  final String tenantId;
  final String membershipStatus;
  final List<String> pendingBranchIds;
  final List<String> activeBranchIds;

  factory StaffMembershipBranchAssignmentDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return StaffMembershipBranchAssignmentDto(
      membershipId: json['membershipId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      membershipStatus: json['membershipStatus']?.toString() ?? '',
      pendingBranchIds: StaffApiHelpers.stringList(json['pendingBranchIds']),
      activeBranchIds: StaffApiHelpers.stringList(json['activeBranchIds']),
    );
  }
}
