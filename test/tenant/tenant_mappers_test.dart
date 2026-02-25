import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/tenant/data/dto/current_tenant_profile_dto.dart';
import 'package:modular_pos/features/tenant/data/dto/tenant_provision_owner_membership_dto.dart';
import 'package:modular_pos/features/tenant/data/dto/tenant_provision_result_dto.dart';
import 'package:modular_pos/features/tenant/data/dto/tenant_provision_tenant_dto.dart';
import 'package:modular_pos/features/tenant/data/tenant_mappers.dart';

void main() {
  test(
    'toTenantProfile applies deterministic defaults and null normalization',
    () {
      final dto = CurrentTenantProfileDto(
        tenantId: 'tenant-1',
        tenantName: '   ',
        tenantAddress: '   ',
        contactNumber: '',
        logoUrl: '  https://example.com/logo.png  ',
        status: '',
      );

      final mapped = TenantMappers.toTenantProfile(dto);

      expect(mapped.tenantId, 'tenant-1');
      expect(mapped.tenantName, 'tenant-1');
      expect(mapped.tenantAddress, isNull);
      expect(mapped.contactNumber, isNull);
      expect(mapped.logoUrl, 'https://example.com/logo.png');
      expect(mapped.status, 'ACTIVE');
    },
  );

  test('toTenantProvisionResult applies deterministic defaults', () {
    final dto = TenantProvisionResultDto(
      tenant: const TenantProvisionTenantDto(
        id: 'tenant-2',
        name: ' ',
        status: ' ',
      ),
      ownerMembership: const TenantProvisionOwnerMembershipDto(
        id: ' ',
        roleKey: ' ',
        status: ' ',
      ),
      branch: null,
    );

    final mapped = TenantMappers.toTenantProvisionResult(dto);

    expect(mapped.tenantId, 'tenant-2');
    expect(mapped.tenantName, 'tenant-2');
    expect(mapped.tenantStatus, 'ACTIVE');
    expect(mapped.ownerMembershipId, '');
    expect(mapped.ownerRoleKey, 'OWNER');
    expect(mapped.ownerStatus, 'ACTIVE');
    expect(mapped.branch, isNull);
  });
}
