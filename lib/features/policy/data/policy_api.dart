import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';

final policyApiProvider = Provider<PolicyApi>((ref) {
  final dio = ref.watch(dioProvider);
  return PolicyApi(dio);
});

class PolicyApi {
  PolicyApi(this._dio)
      : _prefix = dotenv.env['POLICY_API_PREFIX'] ?? '/v1/policies';

  final Dio _dio;
  final String _prefix;

  Future<Map<String, dynamic>> getPolicies() async {
    final response = await _dio.get<Map<String, dynamic>>(_prefix);
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> getSalesPolicies() async {
    final response = await _dio.get<Map<String, dynamic>>('$_prefix/sales');
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> getInventoryPolicies() async {
    final response =
        await _dio.get<Map<String, dynamic>>('$_prefix/inventory');
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateTax({
    required bool saleVatEnabled,
    required double saleVatRatePercent,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/tax',
      data: {
        'saleVatEnabled': saleVatEnabled,
        'saleVatRatePercent': saleVatRatePercent,
      },
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateCurrency({
    required double saleFxRateKhrPerUsd,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/currency',
      data: {'saleFxRateKhrPerUsd': saleFxRateKhrPerUsd},
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateRounding({
    bool? saleKhrRoundingEnabled,
    String? saleKhrRoundingMode,
    String? saleKhrRoundingGranularity,
  }) async {
    final body = <String, dynamic>{};
    if (saleKhrRoundingEnabled != null) {
      body['saleKhrRoundingEnabled'] = saleKhrRoundingEnabled;
    }
    if (saleKhrRoundingMode != null) {
      body['saleKhrRoundingMode'] = saleKhrRoundingMode;
    }
    if (saleKhrRoundingGranularity != null) {
      body['saleKhrRoundingGranularity'] = saleKhrRoundingGranularity;
    }
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/rounding',
      data: body,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateInventory({
    bool? inventoryAutoSubtractOnSale,
    bool? inventoryExpiryTrackingEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (inventoryAutoSubtractOnSale != null) {
      body['inventoryAutoSubtractOnSale'] = inventoryAutoSubtractOnSale;
    }
    if (inventoryExpiryTrackingEnabled != null) {
      body['inventoryExpiryTrackingEnabled'] =
          inventoryExpiryTrackingEnabled;
    }
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/inventory',
      data: body,
    );
    return response.data ?? const {};
  }
}
