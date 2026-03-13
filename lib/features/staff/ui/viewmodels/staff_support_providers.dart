import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/branchV2/data/branch_repository.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/staff/data/repository/staff_membership_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';

final staffTenantBranchesProvider = FutureProvider<List<BranchListItem>>((
  ref,
) async {
  final repository = ref.read(branchRepositoryProvider);
  return repository.loadAccessibleBranches();
});

final staffMembershipOptionsProvider =
    FutureProvider<List<StaffMembershipSummary>>((ref) async {
      final repository = ref.read(staffMembershipRepositoryProvider);
      return repository.fetchMemberships(limit: 200, status: 'ALL');
    });
