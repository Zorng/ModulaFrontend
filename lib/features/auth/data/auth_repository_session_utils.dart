import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

String? currentBranchId(AuthSession session) {
  if (session.user.branches.isEmpty) return null;
  final active = session.user.branches.firstWhere(
    (b) => b.active && (b.branchId.isNotEmpty || b.id.isNotEmpty),
    orElse: () => session.user.branches.first,
  );
  if (active.branchId.isNotEmpty) return active.branchId;
  return active.id.isNotEmpty ? active.id : null;
}

AuthSession updateSessionTokensAndContext(
  AuthSession currentSession, {
  required String accessToken,
  required String refreshToken,
  required String tenantId,
  String? branchId,
}) {
  final resolvedBranchId = (branchId ?? '').trim();
  final updatedUser = currentSession.user.copyWith(
    tenantId: tenantId,
    branches: activateBranchForUser(
      currentSession.user.branches,
      resolvedBranchId,
    ),
  );

  final updatedMemberships = currentSession.memberships
      .map(
        (membership) => TenantMembership(
          tenantId: membership.tenantId,
          tenantName: membership.tenantName,
          role: membership.role,
          branches: membership.tenantId == tenantId
              ? activateBranchForUser(membership.branches, resolvedBranchId)
              : membership.branches,
        ),
      )
      .toList(growable: false);

  return currentSession.copyWith(
    user: updatedUser,
    memberships: updatedMemberships,
    activeTenantId: tenantId,
    accessToken: accessToken,
    refreshToken: refreshToken,
    accessTokenExpiresAt: DateTime.now().toUtc().add(
      const Duration(minutes: 15),
    ),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(
      const Duration(hours: 72),
    ),
    tenantSelectionToken: '',
  );
}

List<UserBranch> activateBranchForUser(
  List<UserBranch> branches,
  String branchId,
) {
  if (branches.isEmpty) return branches;
  if (branchId.isEmpty) return branches;

  var matched = false;
  final updated = branches
      .map((branch) {
        final branchIdentity = branch.branchId.isNotEmpty
            ? branch.branchId
            : branch.id;
        final isMatch = branchIdentity == branchId;
        if (isMatch) matched = true;
        return UserBranch(
          id: branch.id,
          name: branch.name,
          role: branch.role,
          active: isMatch,
          employeeId: branch.employeeId,
          branchId: branch.branchId,
        );
      })
      .toList(growable: false);
  return matched ? updated : branches;
}
