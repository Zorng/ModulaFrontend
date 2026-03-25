import 'package:modular_pos/features/auth/domain/models/auth_session.dart';

enum AuthRole { owner, admin, manager, cashier, unknown }

AuthRole parseAuthRole(String? rawRole) {
  final normalized = (rawRole ?? '').trim().toLowerCase();
  switch (normalized) {
    case 'owner':
    case 'tenant_owner':
    case 'store':
      return AuthRole.owner;
    case 'admin':
      return AuthRole.admin;
    case 'manager':
      return AuthRole.manager;
    case 'cashier':
      return AuthRole.cashier;
    default:
      return AuthRole.unknown;
  }
}

bool isAdminRole(String? rawRole) => parseAuthRole(rawRole) == AuthRole.admin;

bool isOwnerRole(String? rawRole) => parseAuthRole(rawRole) == AuthRole.owner;

bool isAdminOrOwnerRole(String? rawRole) {
  final role = parseAuthRole(rawRole);
  return role == AuthRole.admin || role == AuthRole.owner;
}

bool isCashierRole(String? rawRole) =>
    parseAuthRole(rawRole) == AuthRole.cashier;

bool isManagerRole(String? rawRole) =>
    parseAuthRole(rawRole) == AuthRole.manager;

AuthRole resolveSessionAuthRole(AuthSession? session) {
  if (session == null) return AuthRole.unknown;

  final memberships = session.memberships;
  final sessionTenantId = (session.activeTenantId ?? '').trim();
  final activeTenantId = sessionTenantId.isNotEmpty
      ? sessionTenantId
      : session.user.tenantId.trim();
  if (activeTenantId.isNotEmpty) {
    for (final membership in memberships) {
      if (membership.tenantId.trim() != activeTenantId) continue;
      final tenantRole = parseAuthRole(membership.role);
      if (tenantRole != AuthRole.unknown) return tenantRole;
      break;
    }
  }

  final userRole = parseAuthRole(session.user.role);
  if (userRole != AuthRole.unknown) return userRole;

  for (final membership in memberships) {
    final tenantRole = parseAuthRole(membership.role);
    if (tenantRole != AuthRole.unknown) return tenantRole;
  }

  return AuthRole.unknown;
}

bool isBranchOperatorAuthRole(AuthRole role) {
  switch (role) {
    case AuthRole.owner:
    case AuthRole.admin:
    case AuthRole.manager:
    case AuthRole.cashier:
      return true;
    case AuthRole.unknown:
      return false;
  }
}

bool isVoidReviewerAuthRole(AuthRole role) {
  switch (role) {
    case AuthRole.owner:
    case AuthRole.admin:
    case AuthRole.manager:
      return true;
    case AuthRole.cashier:
    case AuthRole.unknown:
      return false;
  }
}
