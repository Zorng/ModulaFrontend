import 'package:modular_pos/features/tenant/data/dto/current_tenant_profile_dto.dart';
import 'package:modular_pos/features/tenant/data/dto/tenant_provision_result_dto.dart';
import 'package:modular_pos/features/tenant/domain/models/tenant_profile.dart';
import 'package:modular_pos/features/tenant/domain/models/tenant_provision_result.dart';

class TenantMappers {
  const TenantMappers._();

  static String _requiredString(String value, {String fallback = ''}) {
    final normalized = value.trim();
    if (normalized.isEmpty) return fallback;
    return normalized;
  }

  static String? _nullableString(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return null;
    return normalized;
  }

  static String _tenantStatus(String value, {String fallback = 'ACTIVE'}) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'ACTIVE' || normalized == 'FROZEN') return normalized;
    return fallback;
  }

  static TenantProfile toTenantProfile(CurrentTenantProfileDto dto) {
    final tenantId = _requiredString(dto.tenantId);
    final tenantName = _requiredString(
      dto.tenantName,
      fallback: tenantId.isEmpty ? 'Tenant' : tenantId,
    );

    return TenantProfile(
      tenantId: tenantId,
      tenantName: tenantName,
      tenantAddress: _nullableString(dto.tenantAddress),
      contactNumber: _nullableString(dto.contactNumber),
      logoUrl: _nullableString(dto.logoUrl),
      status: _tenantStatus(dto.status),
    );
  }

  static TenantProvisionResult toTenantProvisionResult(
    TenantProvisionResultDto dto,
  ) {
    final tenantId = _requiredString(dto.tenant.id);
    final tenantName = _requiredString(
      dto.tenant.name,
      fallback: tenantId.isEmpty ? 'Tenant' : tenantId,
    );

    return TenantProvisionResult(
      tenantId: tenantId,
      tenantName: tenantName,
      tenantStatus: _tenantStatus(dto.tenant.status),
      ownerMembershipId: _requiredString(dto.ownerMembership.id),
      ownerRoleKey: _requiredString(
        dto.ownerMembership.roleKey,
        fallback: 'OWNER',
      ),
      ownerStatus: _requiredString(
        dto.ownerMembership.status,
        fallback: 'ACTIVE',
      ),
      branch: dto.branch,
    );
  }
}
