import 'package:modular_pos/features/tenant/data/dto/tenant_provision_owner_membership_dto.dart';
import 'package:modular_pos/features/tenant/data/dto/tenant_provision_tenant_dto.dart';

class TenantProvisionResultDto {
  const TenantProvisionResultDto({
    required this.tenant,
    required this.ownerMembership,
    required this.branch,
  });

  final TenantProvisionTenantDto tenant;
  final TenantProvisionOwnerMembershipDto ownerMembership;
  final Object? branch;

  factory TenantProvisionResultDto.fromJson(Map<String, dynamic> json) {
    final tenantJson = json['tenant'];
    final ownerMembershipJson = json['ownerMembership'];

    final tenantMap = tenantJson is Map
        ? tenantJson.cast<String, dynamic>()
        : const <String, dynamic>{};
    final ownerMembershipMap = ownerMembershipJson is Map
        ? ownerMembershipJson.cast<String, dynamic>()
        : const <String, dynamic>{};

    return TenantProvisionResultDto(
      tenant: TenantProvisionTenantDto.fromJson(tenantMap),
      ownerMembership: TenantProvisionOwnerMembershipDto.fromJson(
        ownerMembershipMap,
      ),
      branch: json['branch'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant': tenant.toJson(),
      'ownerMembership': ownerMembership.toJson(),
      'branch': branch,
    };
  }
}
