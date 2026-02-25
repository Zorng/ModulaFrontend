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
          membershipId: membership.membershipId,
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

AuthSession upsertTenantMembership(
  AuthSession currentSession, {
  required String tenantId,
  required String tenantName,
  required String role,
  List<UserBranch> branches = const <UserBranch>[],
}) {
  final normalizedTenantId = tenantId.trim();
  if (normalizedTenantId.isEmpty) return currentSession;

  final normalizedTenantName = tenantName.trim().isEmpty
      ? normalizedTenantId
      : tenantName.trim();
  final normalizedRole = role.trim().isEmpty ? 'MEMBER' : role.trim();

  final existingIndex = currentSession.memberships.indexWhere(
    (membership) => membership.tenantId.trim() == normalizedTenantId,
  );

  final existingMembership = existingIndex >= 0
      ? currentSession.memberships[existingIndex]
      : null;
  final nextBranches = branches.isEmpty
      ? (existingMembership?.branches ?? const <UserBranch>[])
      : branches;

  final nextMembership = TenantMembership(
    membershipId: existingMembership?.membershipId ?? '',
    tenantId: normalizedTenantId,
    tenantName: normalizedTenantName,
    role: normalizedRole,
    branches: nextBranches,
  );

  final nextMemberships = currentSession.memberships.toList(growable: true);
  if (existingIndex >= 0) {
    final previousMembership = nextMemberships[existingIndex];
    final isUnchanged =
        previousMembership.tenantName == nextMembership.tenantName &&
        previousMembership.role == nextMembership.role &&
        _sameBranches(previousMembership.branches, nextMembership.branches);
    if (isUnchanged) return currentSession;
    nextMemberships[existingIndex] = nextMembership;
  } else {
    nextMemberships.add(nextMembership);
  }

  return currentSession.copyWith(
    memberships: nextMemberships.toList(growable: false),
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

bool _sameBranches(List<UserBranch> a, List<UserBranch> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final left = a[i];
    final right = b[i];
    if (left.id != right.id) return false;
    if (left.name != right.name) return false;
    if (left.role != right.role) return false;
    if (left.active != right.active) return false;
    if (left.employeeId != right.employeeId) return false;
    if (left.branchId != right.branchId) return false;
  }
  return true;
}
