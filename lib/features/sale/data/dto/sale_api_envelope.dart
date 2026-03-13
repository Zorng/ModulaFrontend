import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';

class SaleApiEnvelope {
  const SaleApiEnvelope._();

  static Map<String, dynamic> unwrapDataMap(
    dynamic payload, {
    required String fallbackMessage,
  }) {
    final raw = ApiContract.asJsonMap(payload);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    return ApiContract.asJsonMap(ApiContract.unwrapData(raw));
  }

  static void _throwIfFailure(
    Map<String, dynamic> raw, {
    required String fallbackMessage,
  }) {
    if (raw['success'] == true) return;
    final message = ApiContract.errorMessage(raw);
    throw ApiClientException(
      message: (message ?? '').trim().isNotEmpty
          ? message!.trim()
          : fallbackMessage,
      code: SaleCheckoutReasonCodes.normalize(ApiContract.errorCode(raw)),
      details: ApiContract.errorDetails(raw),
    );
  }
}
