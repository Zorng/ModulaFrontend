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

  Future<Map<String, dynamic>> getPolicies({String? branchId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _prefix,
      queryParameters:
          branchId != null && branchId.isNotEmpty ? {'branchId': branchId} : null,
    );
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
    String? branchId,
    required bool saleVatEnabled,
    required double saleVatRatePercent,
  }) async {
    final body = <String, dynamic>{
      'saleVatEnabled': saleVatEnabled,
      'saleVatRatePercent': saleVatRatePercent,
    };
    if (branchId != null && branchId.isNotEmpty) {
      body['branchId'] = branchId;
    }
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/tax',
      data: body,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateCurrency({
    String? branchId,
    required double saleFxRateKhrPerUsd,
  }) async {
    final body = <String, dynamic>{
      'saleFxRateKhrPerUsd': saleFxRateKhrPerUsd,
    };
    if (branchId != null && branchId.isNotEmpty) {
      body['branchId'] = branchId;
    }
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/currency',
      data: body,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateRounding({
    String? branchId,
    bool? saleKhrRoundingEnabled,
    String? saleKhrRoundingMode,
    String? saleKhrRoundingGranularity,
  }) async {
    final body = <String, dynamic>{};
    if (branchId != null && branchId.isNotEmpty) {
      body['branchId'] = branchId;
    }
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
    String? branchId,
    bool? inventoryAutoSubtractOnSale,
    bool? inventoryExpiryTrackingEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (branchId != null && branchId.isNotEmpty) {
      body['branchId'] = branchId;
    }
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

  Future<Map<String, dynamic>> updateCashSession({
    String? branchId,
    bool? cashRequireSessionForSales,
    bool? cashAllowPaidOut,
    bool? cashRequireRefundApproval,
    bool? cashAllowManualAdjustment,
  }) async {
    final body = <String, dynamic>{};
    if (branchId != null && branchId.isNotEmpty) {
      body['branchId'] = branchId;
    }
    if (cashRequireSessionForSales != null) {
      body['cashRequireSessionForSales'] = cashRequireSessionForSales;
    }
    if (cashAllowPaidOut != null) {
      body['cashAllowPaidOut'] = cashAllowPaidOut;
    }
    if (cashRequireRefundApproval != null) {
      body['cashRequireRefundApproval'] = cashRequireRefundApproval;
    }
    if (cashAllowManualAdjustment != null) {
      body['cashAllowManualAdjustment'] = cashAllowManualAdjustment;
    }
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/cash-sessions',
      data: body,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> updateAttendance({
    String? branchId,
    bool? attendanceAutoFromCashSession,
    bool? attendanceRequireOutOfShiftApproval,
    bool? attendanceEarlyCheckinBufferEnabled,
    int? attendanceCheckinBufferMinutes,
    bool? attendanceAllowManagerEdits,
  }) async {
    final body = <String, dynamic>{};
    if (branchId != null && branchId.isNotEmpty) {
      body['branchId'] = branchId;
    }
    if (attendanceAutoFromCashSession != null) {
      body['attendanceAutoFromCashSession'] = attendanceAutoFromCashSession;
    }
    if (attendanceRequireOutOfShiftApproval != null) {
      body['attendanceRequireOutOfShiftApproval'] =
          attendanceRequireOutOfShiftApproval;
    }
    if (attendanceEarlyCheckinBufferEnabled != null) {
      body['attendanceEarlyCheckinBufferEnabled'] =
          attendanceEarlyCheckinBufferEnabled;
    }
    if (attendanceCheckinBufferMinutes != null) {
      body['attendanceCheckinBufferMinutes'] = attendanceCheckinBufferMinutes;
    }
    if (attendanceAllowManagerEdits != null) {
      body['attendanceAllowManagerEdits'] = attendanceAllowManagerEdits;
    }
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/attendance',
      data: body,
    );
    return response.data ?? const {};
  }
}
