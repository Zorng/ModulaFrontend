import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/features/tenant/data/mock_tenant_repository.dart';
import 'package:modular_pos/features/tenant/data/remote_tenant_repository.dart';
import 'package:modular_pos/features/tenant/data/tenant_api.dart';
import 'package:modular_pos/features/tenant/domain/models/tenant_profile.dart';
import 'package:modular_pos/features/tenant/domain/models/tenant_provision_result.dart';

abstract class TenantRepository {
  Future<TenantProvisionResult> createTenant({required String tenantName});
  Future<TenantProfile> getCurrentTenantProfile({String? accessTokenOverride});
}

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  if (AppEnv.useMockTenantRepository) {
    return MockTenantRepository();
  }

  final api = ref.read(tenantApiProvider);
  return RemoteTenantRepository(api);
});
