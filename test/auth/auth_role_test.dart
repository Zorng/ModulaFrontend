import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

AuthSession _session({
  required String userRole,
  required String activeTenantId,
  String? userTenantId,
  required List<TenantMembership> memberships,
}) {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: userRole,
      tenantId: userTenantId ?? activeTenantId,
      branches: const [],
    ),
    memberships: memberships,
    activeTenantId: activeTenantId,
    accessToken: 'access',
    refreshToken: 'refresh',
    accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
  );
}

void main() {
  test(
    'resolveSessionAuthRole prefers active-tenant membership role over user role',
    () {
      final session = _session(
        userRole: '',
        activeTenantId: 'tenant-1',
        memberships: const [
          TenantMembership(
            tenantId: 'tenant-1',
            tenantName: 'Tenant 1',
            role: 'OWNER',
            branches: [],
          ),
        ],
      );

      expect(resolveSessionAuthRole(session), AuthRole.owner);
    },
  );

  test('resolveSessionAuthRole falls back to user role when needed', () {
    final session = _session(
      userRole: 'admin',
      activeTenantId: 'tenant-1',
      memberships: const [
        TenantMembership(
          tenantId: 'tenant-1',
          tenantName: 'Tenant 1',
          role: '',
          branches: [],
        ),
      ],
    );

    expect(resolveSessionAuthRole(session), AuthRole.admin);
  });

  test('parseAuthRole maps store role to owner', () {
    expect(parseAuthRole('store'), AuthRole.owner);
    expect(parseAuthRole('STORE'), AuthRole.owner);
  });

  test('resolveSessionAuthRole maps active-tenant store role to owner', () {
    final session = _session(
      userRole: '',
      activeTenantId: 'tenant-1',
      memberships: const [
        TenantMembership(
          tenantId: 'tenant-1',
          tenantName: 'Tenant 1',
          role: 'store',
          branches: [],
        ),
      ],
    );

    expect(resolveSessionAuthRole(session), AuthRole.owner);
  });

  test(
    'resolveSessionAuthRole falls back to user tenant when active tenant id is empty',
    () {
      final session = _session(
        userRole: '',
        activeTenantId: '',
        userTenantId: 'tenant-1',
        memberships: const [
          TenantMembership(
            tenantId: 'tenant-1',
            tenantName: 'Tenant 1',
            role: 'OWNER',
            branches: [],
          ),
        ],
      );

      expect(resolveSessionAuthRole(session), AuthRole.owner);
    },
  );
}
