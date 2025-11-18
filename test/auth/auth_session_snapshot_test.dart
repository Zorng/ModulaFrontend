import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

void main() {
  test('AuthSession snapshot round-trips user and branches', () {
    final session = AuthSession(
      user: User(
        id: 'user-1',
        name: 'Demo User',
        role: 'ADMIN',
        tenantId: 'tenant-1',
        phone: '+1234567890',
        status: 'ACTIVE',
        branches: const [
          UserBranch(
            id: 'assign-1',
            name: 'Main Branch',
            role: 'ADMIN',
            active: true,
            branchId: 'branch-1',
            employeeId: 'user-1',
          ),
        ],
      ),
      accessToken: 'access',
      refreshToken: 'refresh',
      accessTokenExpiresAt: DateTime(2025, 1, 1),
      refreshTokenExpiresAt: DateTime(2025, 1, 2),
    );

    final json = session.toJson();
    final roundTrip = AuthSession.fromJson(json);

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
  });
}
