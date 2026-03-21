import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/policy/data/dto/policy_dto.dart';
import 'package:modular_pos/features/policy/data/dto/policy_api_envelope.dart';
import 'package:modular_pos/features/policy/data/policy_error_codes.dart';

final policyApiProvider = Provider<PolicyApi>((ref) {
  final dio = ref.watch(dioProvider);
  return PolicyApi(dio);
});

class PolicyApi {
  PolicyApi(this._dio) : _prefix = AppEnv.policyApiPrefix;

  final Dio _dio;
  final String _prefix;

  Future<BranchPolicyDto> getCurrentBranchPolicy() async {
    try {
      final response = await _dio.get<dynamic>('$_prefix/current-branch');
      final data = PolicyApiEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to load branch policy.',
      );
      return BranchPolicyDto.fromJson(data);
    } on DioError catch (error) {
      throw _mapPolicyDioError(
        error,
        fallbackMessage: 'Failed to load branch policy.',
      );
    }
  }

  Future<BranchPolicyDto> updateCurrentBranchPolicy({
    bool? saleVatEnabled,
    double? saleVatRatePercent,
    double? saleFxRateKhrPerUsd,
    bool? saleKhrRoundingEnabled,
    String? saleKhrRoundingMode,
    String? saleKhrRoundingGranularity,
    bool? saleAllowPayLater,
    bool? saleAllowManualExternalPaymentClaim,
  }) async {
    final payload = UpdateBranchPolicyInputDto(
      saleVatEnabled: saleVatEnabled,
      saleVatRatePercent: saleVatRatePercent,
      saleFxRateKhrPerUsd: saleFxRateKhrPerUsd,
      saleKhrRoundingEnabled: saleKhrRoundingEnabled,
      saleKhrRoundingMode: saleKhrRoundingMode,
      saleKhrRoundingGranularity: saleKhrRoundingGranularity,
      saleAllowPayLater: saleAllowPayLater,
      saleAllowManualExternalPaymentClaim: saleAllowManualExternalPaymentClaim,
    ).toJson();
    try {
      final response = await _dio.patch<dynamic>(
        '$_prefix/current-branch',
        data: payload,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'policy.currentBranch.update',
            payload: payload,
          ),
        ),
      );
      final data = PolicyApiEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to update branch policy.',
      );
      return BranchPolicyDto.fromJson(data);
    } on DioError catch (error) {
      throw _mapPolicyDioError(
        error,
        fallbackMessage: 'Failed to update branch policy.',
      );
    }
  }
}

ApiClientException _mapPolicyDioError(
  DioError error, {
  required String fallbackMessage,
}) {
  final isOfflineLike =
      error.response == null && error.type != DioErrorType.badResponse;
  if (isOfflineLike) {
    return const ApiClientException(
      message: 'This action requires online connectivity.',
      code: PolicyErrorCodes.offlineUnreachable,
    );
  }
  final mapped = ApiClientException.fromDio(
    error,
    fallbackMessage: fallbackMessage,
  );
  return ApiClientException(
    message: mapped.message,
    code: PolicyErrorCodes.normalize(mapped.code),
    statusCode: mapped.statusCode,
    details: mapped.details,
  );
}
