import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/policy/data/dto/policy_bundle_dto.dart';

final policyApiProvider = Provider<PolicyApi>((ref) {
  final dio = ref.watch(dioProvider);
  return PolicyApi(dio);
});

class PolicyApi {
  PolicyApi(this._dio) : _prefix = AppEnv.policyApiPrefix;

  final Dio _dio;
  final String _prefix;

  Future<PolicyBundleDto> getPolicies({String? branchId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _prefix,
      queryParameters: branchId != null && branchId.isNotEmpty
          ? {'branchId': branchId}
          : null,
    );
    return PolicyBundleDto.fromJson(response.data ?? const {});
  }

  Future<PolicyBundleDto> getSalesPolicies() async {
    final response = await _dio.get<Map<String, dynamic>>('$_prefix/sales');
    return PolicyBundleDto.fromJson(response.data ?? const {});
  }

  Future<PolicyBundleDto> getInventoryPolicies() async {
    final response = await _dio.get<Map<String, dynamic>>('$_prefix/inventory');
    return PolicyBundleDto.fromJson(response.data ?? const {});
  }

  Future<void> updateTax({
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
    await _dio.patch<Map<String, dynamic>>('$_prefix/tax', data: body);
    // ignore response; repository re-fetches canonical policies.
  }

  Future<void> updateCurrency({
    String? branchId,
    required double saleFxRateKhrPerUsd,
  }) async {
    final body = <String, dynamic>{'saleFxRateKhrPerUsd': saleFxRateKhrPerUsd};
    if (branchId != null && branchId.isNotEmpty) {
      body['branchId'] = branchId;
    }
    await _dio.patch<Map<String, dynamic>>('$_prefix/currency', data: body);
  }

  Future<void> updateRounding({
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
    await _dio.patch<Map<String, dynamic>>('$_prefix/rounding', data: body);
  }

  Future<void> updateInventory({
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
      body['inventoryExpiryTrackingEnabled'] = inventoryExpiryTrackingEnabled;
    }
    await _dio.patch<Map<String, dynamic>>('$_prefix/inventory', data: body);
  }

  Future<void> updateCashSession({
    String? branchId,
    bool? cashAllowPaidOut,
    bool? cashRequireRefundApproval,
    bool? cashAllowManualAdjustment,
  }) async {
    final body = <String, dynamic>{};
    if (branchId != null && branchId.isNotEmpty) {
      body['branchId'] = branchId;
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
    await _dio.patch<Map<String, dynamic>>(
      '$_prefix/cash-sessions',
      data: body,
    );
  }

  Future<void> updateAttendance({
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
    await _dio.patch<Map<String, dynamic>>('$_prefix/attendance', data: body);
  }
}
