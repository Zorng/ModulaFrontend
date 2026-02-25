import 'package:modular_pos/features/tenant/data/tenant_api.dart';
import 'package:modular_pos/features/tenant/data/tenant_mappers.dart';
import 'package:modular_pos/features/tenant/data/tenant_repository.dart';
import 'package:modular_pos/features/tenant/domain/models/tenant_profile.dart';
import 'package:modular_pos/features/tenant/domain/models/tenant_provision_result.dart';

class RemoteTenantRepository implements TenantRepository {
  const RemoteTenantRepository(this._api);

  final TenantApi _api;

  @override
  Future<TenantProvisionResult> createTenant({
    required String tenantName,
  }) async {
    final dto = await _api.createTenant(tenantName: tenantName);
    return TenantMappers.toTenantProvisionResult(dto);
  }

  @override
  Future<TenantProfile> getCurrentTenantProfile() async {
    final dto = await _api.getCurrentTenantProfile();
    return TenantMappers.toTenantProfile(dto);
  }
}
