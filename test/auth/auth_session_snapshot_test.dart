import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

void main() {
  test('AuthSession snapshot round-trips user/memberships (tokens excluded)', () {
    const branches = [
      UserBranch(
        id: 'assign-1',
        name: 'Main Branch',
        role: 'ADMIN',
        active: true,
        branchId: 'branch-1',
        employeeId: 'user-1',
      ),
    ];

    const membership = TenantMembership(
      tenantId: 'tenant-1',
      tenantName: 'tenant-1',
      role: 'ADMIN',
      branches: branches,
    );

    final session = AuthSession(
      user: User(
        id: 'user-1',
        name: 'Demo User',
        role: 'ADMIN',
        tenantId: 'tenant-1',
        phone: '+1234567890',
        status: 'ACTIVE',
        branches: branches,
      ),
      memberships: const [membership],
      activeTenantId: 'tenant-1',
      accessToken: 'access',
      refreshToken: 'refresh',
      accessTokenExpiresAt: DateTime(2025, 1, 1),
      refreshTokenExpiresAt: DateTime(2025, 1, 2),
    );

    final json = session.toJson();
    final roundTrip = AuthSession.fromJson(json);

    expect(roundTrip.accessToken, isEmpty);
    expect(roundTrip.refreshToken, isEmpty);

    expect(roundTrip.user.id, 'user-1');
    expect(roundTrip.user.name, 'Demo User');
    expect(roundTrip.user.role, 'ADMIN');
    expect(roundTrip.user.tenantId, 'tenant-1');
    expect(roundTrip.user.phone, '+1234567890');
    expect(roundTrip.user.status, 'ACTIVE');
    expect(roundTrip.user.branches, hasLength(1));
    final branch = roundTrip.user.branches.first;
    expect(branch.id, 'assign-1');
    expect(branch.branchId, 'branch-1');
    expect(branch.name, 'Main Branch');
    expect(branch.role, 'ADMIN');
    expect(branch.active, true);

    expect(roundTrip.memberships, hasLength(1));
    expect(roundTrip.activeTenantId, 'tenant-1');

    final roundTripMembership = roundTrip.memberships.first;
    expect(roundTripMembership.tenantId, 'tenant-1');
    expect(roundTripMembership.tenantName, 'tenant-1');
    expect(roundTripMembership.role, 'ADMIN');
    expect(roundTripMembership.branches, hasLength(1));
  });
}
