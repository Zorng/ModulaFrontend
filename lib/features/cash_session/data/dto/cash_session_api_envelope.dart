import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_error_codes.dart';

class CashSessionApiEnvelope {
  const CashSessionApiEnvelope._();

  static Map<String, dynamic> unwrapDataMap(
    dynamic body, {
    required String fallbackMessage,
  }) {
    final raw = ApiContract.asJsonMap(body);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    return ApiContract.asJsonMap(ApiContract.unwrapData(body));
  }

  static Map<String, dynamic> unwrapRequiredSessionMap(
    dynamic body, {
    required String fallbackMessage,
  }) {
    final dataMap = unwrapDataMap(body, fallbackMessage: fallbackMessage);
    if (dataMap.isEmpty || dataMap.containsKey('session')) {
      throw ApiClientException(message: fallbackMessage);
    }
    return dataMap;
  }

  static void unwrapSuccess(
    dynamic body, {
    required String fallbackMessage,
  }) {
    final raw = ApiContract.asJsonMap(body);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    ApiContract.unwrapData(body);
  }

  static List<Map<String, dynamic>> unwrapDataList(
    dynamic body, {
    required String fallbackMessage,
  }) {
    final raw = ApiContract.asJsonMap(body);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    final data = ApiContract.unwrapData(body);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }
    final dataMap = ApiContract.asJsonMap(data);
    final list = dataMap['movements'] ?? dataMap['items'];
    if (list is! List) {
      throw ApiClientException(message: fallbackMessage);
    }
    return list
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  static Map<String, dynamic>? unwrapOptionalSessionMap(
    dynamic body, {
    required String fallbackMessage,
  }) {
    final dataMap = unwrapDataMap(body, fallbackMessage: fallbackMessage);
    if (!dataMap.containsKey('session')) {
      throw ApiClientException(message: fallbackMessage);
    }
    final session = dataMap['session'];
    if (session == null) return null;
    final sessionMap = ApiContract.asJsonMap(session);
    return sessionMap.isEmpty ? null : sessionMap;
  }

  static void _throwIfFailure(
    Map<String, dynamic> raw, {
    required String fallbackMessage,
  }) {
    if (raw['success'] == false) {
      throw ApiClientException(
        message: ApiContract.errorMessage(raw) ?? fallbackMessage,
        code: CashSessionErrorCodes.normalize(ApiContract.errorCode(raw)),
        details: ApiContract.errorDetails(raw),
      );
    }
  }
}
