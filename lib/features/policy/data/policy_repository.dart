import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/policy/data/policy_api.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  final api = ref.watch(policyApiProvider);
  return PolicyRepository(api);
});

class PolicyRepository {
  PolicyRepository(this._api);

  final PolicyApi _api;

  Future<PolicyBundle> fetchPolicies({String? branchId}) async {
    final payload = await _api.getPolicies(branchId: branchId);
    final sales = SalesPolicy.fromJson(payload);
    final inventory = InventoryPolicy.fromJson(payload);
    final cashSession = CashSessionPolicy.fromJson(payload);
    final attendance = AttendancePolicy.fromJson(payload);
    return PolicyBundle(
      sales: sales,
      inventory: inventory,
      cashSession: cashSession,
      attendance: attendance,
    );
  }

  Future<SalesPolicy> fetchSalesPolicies() async {
    final payload = await _api.getSalesPolicies();
    return SalesPolicy.fromJson(payload);
  }

  Future<InventoryPolicy> fetchInventoryPolicies() async {
    final payload = await _api.getInventoryPolicies();
    return InventoryPolicy.fromJson(payload);
  }

  Future<PolicyBundle> updateTax({
    String? branchId,
    required bool saleVatEnabled,
    required double saleVatRatePercent,
  }) async {
    await _api.updateTax(
      branchId: branchId,
      saleVatEnabled: saleVatEnabled,
      saleVatRatePercent: saleVatRatePercent,
    );
    return fetchPolicies(branchId: branchId);
  }

  Future<PolicyBundle> updateCurrency({
    String? branchId,
    required double saleFxRateKhrPerUsd,
  }) async {
    await _api.updateCurrency(
      branchId: branchId,
      saleFxRateKhrPerUsd: saleFxRateKhrPerUsd,
    );
    return fetchPolicies(branchId: branchId);
  }

  Future<PolicyBundle> updateRounding({
    String? branchId,
    bool? saleKhrRoundingEnabled,
    String? saleKhrRoundingMode,
    String? saleKhrRoundingGranularity,
  }) async {
    await _api.updateRounding(
      branchId: branchId,
      saleKhrRoundingEnabled: saleKhrRoundingEnabled,
      saleKhrRoundingMode: saleKhrRoundingMode,
      saleKhrRoundingGranularity: saleKhrRoundingGranularity,
    );
    return fetchPolicies(branchId: branchId);
  }

  Future<PolicyBundle> updateInventory({
    String? branchId,
    bool? inventoryAutoSubtractOnSale,
    bool? inventoryExpiryTrackingEnabled,
  }) async {
    await _api.updateInventory(
      branchId: branchId,
      inventoryAutoSubtractOnSale: inventoryAutoSubtractOnSale,
      inventoryExpiryTrackingEnabled: inventoryExpiryTrackingEnabled,
    );
    return fetchPolicies(branchId: branchId);
  }

  Future<PolicyBundle> updateCashSession({
    String? branchId,
    bool? cashRequireSessionForSales,
    bool? cashAllowPaidOut,
    bool? cashRequireRefundApproval,
    bool? cashAllowManualAdjustment,
  }) async {
    await _api.updateCashSession(
      branchId: branchId,
      cashRequireSessionForSales: cashRequireSessionForSales,
      cashAllowPaidOut: cashAllowPaidOut,
      cashRequireRefundApproval: cashRequireRefundApproval,
      cashAllowManualAdjustment: cashAllowManualAdjustment,
    );
    return fetchPolicies(branchId: branchId);
  }

  Future<PolicyBundle> updateAttendance({
    String? branchId,
    bool? attendanceAutoFromCashSession,
    bool? attendanceRequireOutOfShiftApproval,
    bool? attendanceEarlyCheckinBufferEnabled,
    int? attendanceCheckinBufferMinutes,
    bool? attendanceAllowManagerEdits,
  }) async {
    await _api.updateAttendance(
      branchId: branchId,
      attendanceAutoFromCashSession: attendanceAutoFromCashSession,
      attendanceRequireOutOfShiftApproval: attendanceRequireOutOfShiftApproval,
      attendanceEarlyCheckinBufferEnabled:
          attendanceEarlyCheckinBufferEnabled,
      attendanceCheckinBufferMinutes: attendanceCheckinBufferMinutes,
      attendanceAllowManagerEdits: attendanceAllowManagerEdits,
    );
    return fetchPolicies(branchId: branchId);
  }
}
