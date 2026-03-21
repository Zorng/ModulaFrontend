import 'package:modular_pos/core/network/api_contract.dart';

class DiscountRuleListEnvelope {
  const DiscountRuleListEnvelope._();

  static List<Map<String, dynamic>> unwrapDataList(
    dynamic body, {
    String fallbackMessage = 'Discount request failed.',
  }) {
    final raw = ApiContract.asJsonMap(body);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    final data = ApiContract.unwrapData(raw);
    if (data is! List) return const <Map<String, dynamic>>[];

    return data
        .whereType<Map>()
        .map((entry) => ApiContract.asJsonMap(entry))
        .toList(growable: false);
  }

  static Map<String, dynamic> unwrapDataMap(
    dynamic body, {
    String fallbackMessage = 'Discount request failed.',
  }) {
    final raw = ApiContract.asJsonMap(body);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    final data = ApiContract.unwrapData(raw);
    return ApiContract.asJsonMap(data);
  }

  static void _throwIfFailure(
    Map<String, dynamic> raw, {
    required String fallbackMessage,
  }) {
    if (raw['success'] != false) return;
    final message = ApiContract.errorMessage(raw);
    throw ApiClientException(
      message: (message ?? '').trim().isNotEmpty
          ? message!.trim()
          : fallbackMessage,
      code: ApiContract.errorCode(raw),
      details: ApiContract.errorDetails(raw),
    );
  }
}
