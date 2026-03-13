import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/branchV2/data/branch_mapper.dart';

void main() {
  test('resolveTenantAccess allows store role to manage tenant', () {
    final access = BranchMapper.resolveTenantAccess(
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

    expect(access.canManageTenant, isTrue);
    expect(access.roleKey, 'STORE');
  });
}
