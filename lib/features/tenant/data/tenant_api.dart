import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/tenant/data/dto/current_tenant_profile_dto.dart';
import 'package:modular_pos/features/tenant/data/dto/tenant_provision_result_dto.dart';

final tenantApiProvider = Provider<TenantApi>((ref) {
  final dio = ref.watch(dioProvider);
  return TenantApi(dio);
});

class TenantApi {
  TenantApi(this._dio);

  final Dio _dio;
  static const String _prefix = '/v0/org';

  Future<TenantProvisionResultDto> createTenant({
    required String tenantName,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_prefix/tenants',
        data: {'tenantName': tenantName},
        options: Options(contentType: Headers.jsonContentType),
      );

      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      return TenantProvisionResultDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Tenant request failed.',
      );
    }
  }

  Future<CurrentTenantProfileDto> getCurrentTenantProfile() async {
    try {
      final response = await _dio.get<dynamic>('$_prefix/tenant/current');
      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      return CurrentTenantProfileDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Tenant request failed.',
      );
    }
  }
}
