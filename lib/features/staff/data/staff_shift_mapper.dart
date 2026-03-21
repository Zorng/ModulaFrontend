import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/staff/data/dto/staff_membership_dto.dart';
import 'package:modular_pos/features/staff/data/dto/staff_shift_dto.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';

StaffShiftSchedule mapStaffShiftScheduleDto(StaffShiftScheduleDto dto) {
  return StaffShiftSchedule(
    membershipId: dto.membershipId,
    patterns: dto.patterns.map(mapStaffShiftPatternDto).toList(growable: false),
    instances: dto.instances
        .map(mapStaffShiftInstanceDto)
        .toList(growable: false),
  );
}

StaffShiftPattern mapStaffShiftPatternDto(StaffShiftPatternDto dto) {
  return StaffShiftPattern(
    id: dto.id,
    tenantId: dto.tenantId,
    membershipId: dto.membershipId,
    branchId: dto.branchId,
    daysOfWeek: dto.daysOfWeek,
    plannedStartTime: dto.plannedStartTime,
    plannedEndTime: dto.plannedEndTime,
    status: parseStaffShiftPatternStatus(dto.status),
    effectiveFrom: dto.effectiveFrom,
    effectiveTo: dto.effectiveTo,
    note: dto.note,
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
  );
}

StaffShiftInstance mapStaffShiftInstanceDto(StaffShiftInstanceDto dto) {
  return StaffShiftInstance(
    id: dto.id,
    tenantId: dto.tenantId,
    membershipId: dto.membershipId,
    branchId: dto.branchId,
    patternId: dto.patternId,
    date: dto.date,
    plannedStartTime: dto.plannedStartTime,
    plannedEndTime: dto.plannedEndTime,
    status: parseStaffShiftInstanceStatus(dto.status),
    note: dto.note,
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
  );
}

StaffMembershipSummary mapStaffMembershipDto(StaffMembershipDto dto) {
  return StaffMembershipSummary(
    membershipId: dto.membershipId,
    tenantId: dto.tenantId,
    accountId: dto.accountId,
    roleKey: dto.roleKey,
    membershipStatus: parseMembershipLifecycleStatus(dto.membershipStatus),
    phone: dto.phone,
    firstName: dto.firstName,
    lastName: dto.lastName,
    staffProfileStatus: dto.staffProfileStatus,
    invitedAt: dto.invitedAt,
    acceptedAt: dto.acceptedAt,
    rejectedAt: dto.rejectedAt,
    revokedAt: dto.revokedAt,
    pendingBranchIds: dto.pendingBranchIds,
    activeBranchIds: dto.activeBranchIds,
  );
}

BranchListItem mapShiftBranchData(
  Map<String, dynamic> data, {
  String? tenantIdFallback,
}) {
  return BranchListItem(
    branchId: (data['branchId'] ?? data['id'] ?? data['branch_id'] ?? '')
        .toString()
        .trim(),
    tenantId: (data['tenantId'] ?? data['tenant_id'] ?? tenantIdFallback ?? '')
        .toString()
        .trim(),
    branchName:
        (data['branchName'] ?? data['name'] ?? data['branch_name'] ?? 'Branch')
            .toString(),
    status: (data['status'] ?? 'ACTIVE').toString().trim().toUpperCase(),
  );
}
