import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/staff/data/repository/staff_branch_assignment_repository.dart';
import 'package:modular_pos/features/staff/data/repository/staff_membership_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_support_providers.dart';

class StaffMembershipDetailPageData {
  const StaffMembershipDetailPageData({
    required this.detail,
    required this.branchAssignment,
    required this.availableBranches,
  });

  final StaffMembershipDetail detail;
  final StaffMembershipBranchAssignment branchAssignment;
  final List<BranchListItem> availableBranches;

  Map<String, String> get branchNameById => {
    for (final branch in availableBranches) branch.branchId: branch.branchName,
  };
}

final staffMembershipDetailPageProvider =
    FutureProvider.family<StaffMembershipDetailPageData, String>((
      ref,
      membershipId,
    ) async {
      final detailRepository = ref.read(staffMembershipRepositoryProvider);
      final assignmentRepository = ref.read(
        staffBranchAssignmentRepositoryProvider,
      );
      final branches = await ref.read(staffTenantBranchesProvider.future);
      final detail = await detailRepository.fetchMembershipDetail(membershipId);
      final branchAssignment = await assignmentRepository.fetchBranchAssignments(
        membershipId,
      );
      return StaffMembershipDetailPageData(
        detail: detail,
        branchAssignment: branchAssignment,
        availableBranches: branches,
      );
    });
