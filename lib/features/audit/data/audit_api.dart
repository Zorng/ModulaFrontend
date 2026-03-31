import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/audit/data/dto/audit_event_dto.dart';
import 'package:modular_pos/features/audit/domain/models/audit_event.dart';

final auditApiPrefixProvider = Provider<String>((_) => AppEnv.auditApiPrefix);

final auditApiProvider = Provider<AuditApi>((ref) {
  final dio = ref.read(dioProvider);
  final prefix = ref.read(auditApiPrefixProvider);
  return AuditApi(dio, prefix: prefix);
});

class AuditApi {
  AuditApi(this._dio, {String prefix = '/v0/audit'}) : _prefix = prefix;

  final Dio _dio;
  final String _prefix;

  Future<AuditEventPageDto> listEvents({
    String? branchId,
    String? actionKey,
    AuditOutcome? outcome,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_prefix/events',
        queryParameters: {
          if ((branchId ?? '').trim().isNotEmpty) 'branchId': branchId!.trim(),
          if ((actionKey ?? '').trim().isNotEmpty)
            'actionKey': actionKey!.trim(),
          if (outcome != null) 'outcome': outcome.wireValue,
          'limit': limit,
          'offset': offset,
        },
      );
      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      return AuditEventPageDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load audit events.',
      );
    }
  }
}
