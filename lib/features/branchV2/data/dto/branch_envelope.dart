import 'package:modular_pos/core/network/api_contract.dart';

typedef BranchJsonMap = Map<String, dynamic>;

/// Shared canonical envelope parser for Branch `/v0` endpoints.
class BranchEnvelope {
  const BranchEnvelope._();

  static BranchJsonMap unwrapDataMap(
    dynamic body, {
    String fallbackMessage = 'Branch request failed.',
  }) {
    final raw = ApiContract.asJsonMap(body);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    final data = ApiContract.unwrapData(raw);
    return ApiContract.asJsonMap(data);
  }

  static List<BranchJsonMap> unwrapDataList(
    dynamic body, {
    String fallbackMessage = 'Branch request failed.',
  }) {
    final raw = ApiContract.asJsonMap(body);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    final data = ApiContract.unwrapData(raw);
    if (data is! List) return const <BranchJsonMap>[];
    return data
        .whereType<Map>()
        .map((item) => ApiContract.asJsonMap(item))
        .toList(growable: false);
  }

  static void _throwIfFailure(
    BranchJsonMap raw, {
    required String fallbackMessage,
  }) {
    if (raw['success'] != false) return;
    final message = ApiContract.errorMessage(raw);
    throw ApiClientException(
      message: (message ?? '').trim().isNotEmpty ? message!.trim() : fallbackMessage,
      code: ApiContract.errorCode(raw),
      details: ApiContract.errorDetails(raw),
    );
  }
}
