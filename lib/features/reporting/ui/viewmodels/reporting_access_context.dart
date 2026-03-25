import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/reporting/ui/models/reporting_branch_option.dart';

class ReportingAccessContext {
  const ReportingAccessContext({
    required this.role,
    required this.tenantId,
    required this.activeBranchId,
    required this.branches,
  });

  final AuthRole role;
  final String tenantId;
  final String activeBranchId;
  final List<ReportingBranchOption> branches;

  bool get canViewReporting =>
      role == AuthRole.owner ||
      role == AuthRole.admin ||
      role == AuthRole.manager;

  bool get canUseAllBranches =>
      role == AuthRole.owner || role == AuthRole.admin;

  String? get fallbackBranchId {
    if (activeBranchId.isNotEmpty) return activeBranchId;
    if (branches.isEmpty) return null;
    return branches.first.id;
  }
}

final reportingAccessContextProvider = Provider<ReportingAccessContext?>((ref) {
  final session = ref.watch(
    loginControllerProvider.select((state) => state.session),
  );
  if (session == null) return null;

  final tenantId =
      (ref.watch(authTenantIdProvider) ??
              session.activeTenantId ??
              session.user.tenantId)
          .trim();
  final activeBranchId = (ref.watch(activeBranchContextIdProvider) ?? '')
      .trim();
  final branches = _buildBranchOptions(
    tenantBranches: _branchesForTenant(session.memberships, tenantId),
    sessionBranches: session.user.branches,
  );

  return ReportingAccessContext(
    role: resolveSessionAuthRole(session),
    tenantId: tenantId,
    activeBranchId: activeBranchId,
    branches: branches,
  );
});

List<UserBranch> _branchesForTenant(
  List<TenantMembership> memberships,
  String tenantId,
) {
  final normalizedTenantId = tenantId.trim();
  if (normalizedTenantId.isEmpty) return const <UserBranch>[];

  for (final membership in memberships) {
    if (membership.tenantId.trim() == normalizedTenantId) {
      return membership.branches;
    }
  }

  return const <UserBranch>[];
}

List<ReportingBranchOption> _buildBranchOptions({
  required List<UserBranch> tenantBranches,
  required List<UserBranch> sessionBranches,
}) {
  final seen = <String>{};
  final options = <ReportingBranchOption>[];

  void addBranches(List<UserBranch> branches) {
    for (final branch in branches) {
      final id = branch.branchId.trim().isNotEmpty
          ? branch.branchId.trim()
          : branch.id.trim();
      final name = branch.name.trim();
      if (id.isEmpty || name.isEmpty || !seen.add(id)) continue;
      options.add(ReportingBranchOption(id: id, name: name));
    }
  }

  addBranches(tenantBranches);
  addBranches(sessionBranches);
  options.sort((a, b) => a.name.compareTo(b.name));
  return options;
}
