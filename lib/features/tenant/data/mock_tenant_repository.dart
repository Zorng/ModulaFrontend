import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/tenant/data/tenant_repository.dart';
import 'package:modular_pos/features/tenant/domain/models/tenant_profile.dart';
import 'package:modular_pos/features/tenant/domain/models/tenant_provision_result.dart';

class MockTenantRepository implements TenantRepository {
  int _sequence = 1;
  TenantProfile? _currentTenantProfile;

  @override
  Future<TenantProvisionResult> createTenant({
    required String tenantName,
  }) async {
    final normalizedName = tenantName.trim();
    if (normalizedName.isEmpty) {
      throw const ApiClientException(
        message: 'tenantName is required',
        code: 'INVALID_INPUT',
        statusCode: 422,
      );
    }

    final tenantId = 'mock-tenant-${_sequence++}';
    _currentTenantProfile = TenantProfile(
      tenantId: tenantId,
      tenantName: normalizedName,
      tenantAddress: null,
      contactNumber: null,
      logoUrl: null,
      status: 'ACTIVE',
    );

    return TenantProvisionResult(
      tenantId: tenantId,
      tenantName: normalizedName,
      tenantStatus: 'ACTIVE',
      ownerMembershipId: 'mock-membership-$tenantId',
      ownerRoleKey: 'OWNER',
      ownerStatus: 'ACTIVE',
      branch: null,
    );
  }

  @override
  Future<TenantProfile> getCurrentTenantProfile() async {
    final current = _currentTenantProfile;
    if (current == null) {
      throw const ApiClientException(
        message: 'Tenant context required.',
        code: 'TENANT_CONTEXT_REQUIRED',
        statusCode: 403,
      );
    }
    return current;
  }
}
