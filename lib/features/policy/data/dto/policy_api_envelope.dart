import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/policy/data/policy_error_codes.dart';

typedef PolicyJsonMap = Map<String, dynamic>;

class PolicyApiEnvelope {
  const PolicyApiEnvelope._();

  static PolicyJsonMap unwrapDataMap(
    dynamic payload, {
    String fallbackMessage = 'Policy request failed.',
  }) {
    final raw = ApiContract.asJsonMap(payload);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    final data = ApiContract.unwrapData(raw);
    return ApiContract.asJsonMap(data);
  }

  static void _throwIfFailure(
    PolicyJsonMap raw, {
    required String fallbackMessage,
  }) {
    if (raw['success'] == true) return;
    final message = ApiContract.errorMessage(raw);
    throw ApiClientException(
      message: (message ?? '').trim().isNotEmpty ? message!.trim() : fallbackMessage,
      code: PolicyErrorCodes.normalize(ApiContract.errorCode(raw)),
      details: ApiContract.errorDetails(raw),
    );
  }
}
