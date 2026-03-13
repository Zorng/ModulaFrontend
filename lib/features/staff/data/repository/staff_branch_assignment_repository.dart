import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/data/api/staff_branch_assignment_api.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';

abstract class StaffBranchAssignmentRepository {
  Future<StaffMembershipBranchAssignment> fetchBranchAssignments(
    String membershipId,
  );

  Future<StaffMembershipBranchAssignment> assignBranches({
    required String membershipId,
    required List<String> branchIds,
    String? intentId,
  });
}

final staffBranchAssignmentRepositoryProvider =
    Provider<StaffBranchAssignmentRepository>((ref) {
      final api = ref.read(staffBranchAssignmentApiProvider);
      return RemoteStaffBranchAssignmentRepository(api);
    });

class RemoteStaffBranchAssignmentRepository
    implements StaffBranchAssignmentRepository {
  const RemoteStaffBranchAssignmentRepository(this._api);

  final StaffBranchAssignmentApi _api;

  @override
  Future<StaffMembershipBranchAssignment> fetchBranchAssignments(
    String membershipId,
  ) async {
    final dto = await _api.fetchBranchAssignments(membershipId);
    return _toDomain(dto);
  }

  @override
  Future<StaffMembershipBranchAssignment> assignBranches({
    required String membershipId,
    required List<String> branchIds,
    String? intentId,
  }) async {
    final dto = await _api.assignBranches(
      membershipId: membershipId,
      branchIds: branchIds,
      intentId: intentId,
    );
    return _toDomain(dto);
  }

  StaffMembershipBranchAssignment _toDomain(dynamic dto) {
    return StaffMembershipBranchAssignment(
      membershipId: dto.membershipId,
      tenantId: dto.tenantId,
      membershipStatus: parseMembershipLifecycleStatus(dto.membershipStatus),
      pendingBranchIds: dto.pendingBranchIds,
      activeBranchIds: dto.activeBranchIds,
    );
  }
}
