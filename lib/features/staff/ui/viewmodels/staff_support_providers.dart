import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/branchV2/data/branch_repository.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/staff/data/repository/staff_membership_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';

final staffTenantBranchesProvider = FutureProvider<List<BranchListItem>>((
  ref,
) async {
  // Re-fetch when branchControllerProvider's branch list changes (e.g., after
  // a new branch is created), so invite/shift/attendance screens stay in sync.
  ref.watch(branchControllerProvider.select((s) => s.branches.length));
  final repository = ref.read(branchRepositoryProvider);
  return repository.loadAccessibleBranches();
});

final staffMembershipOptionsProvider =
    FutureProvider<List<StaffMembershipSummary>>((ref) async {
      final repository = ref.read(staffMembershipRepositoryProvider);
      return repository.fetchMemberships(limit: 200, status: 'ALL');
    });
