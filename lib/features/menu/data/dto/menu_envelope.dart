import 'package:modular_pos/core/network/api_contract.dart';

typedef MenuJsonMap = Map<String, dynamic>;

class MenuEnvelope {
  const MenuEnvelope._();

  static MenuJsonMap unwrapDataMap(
    dynamic body, {
    String fallbackMessage = 'Menu request failed.',
  }) {
    final raw = ApiContract.asJsonMap(body);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    final data = ApiContract.unwrapData(raw);
    return ApiContract.asJsonMap(data);
  }

  static List<MenuJsonMap> unwrapDataList(
    dynamic body, {
    String fallbackMessage = 'Menu request failed.',
  }) {
    final raw = ApiContract.asJsonMap(body);
    _throwIfFailure(raw, fallbackMessage: fallbackMessage);
    final data = ApiContract.unwrapData(raw);
    if (data is! List) return const <MenuJsonMap>[];

    return data
        .whereType<Map>()
        .map((entry) => ApiContract.asJsonMap(entry))
        .toList(growable: false);
  }

  static void _throwIfFailure(
    MenuJsonMap raw, {
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
