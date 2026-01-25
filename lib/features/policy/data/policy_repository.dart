import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/policy/data/policy_api.dart';
import 'package:modular_pos/features/policy/data/dto/policy_bundle_dto.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  final api = ref.watch(policyApiProvider);
  return PolicyRepository(api);
});

class PolicyRepository {
  PolicyRepository(this._api);

  final PolicyApi _api;

  Future<PolicyBundle> fetchPolicies({String? branchId}) async {
    final dto = await _api.getPolicies(branchId: branchId);
    final sales = _toSales(dto.sales);
    final inventory = _toInventory(dto.inventory);
    final cashSession = _toCashSession(dto.cashSession);
    final attendance = _toAttendance(dto.attendance);
    return PolicyBundle(
      sales: sales,
      inventory: inventory,
      cashSession: cashSession,
      attendance: attendance,
    );
  }

  Future<SalesPolicy> fetchSalesPolicies() async {
    final dto = await _api.getSalesPolicies();
    return _toSales(dto.sales);
  }

  Future<InventoryPolicy> fetchInventoryPolicies() async {
    final dto = await _api.getInventoryPolicies();
    return _toInventory(dto.inventory);
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
    bool? cashAllowPaidOut,
    bool? cashRequireRefundApproval,
    bool? cashAllowManualAdjustment,
  }) async {
    await _api.updateCashSession(
      branchId: branchId,
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

  SalesPolicy _toSales(SalesPolicyDto dto) {
    return SalesPolicy(
      saleVatEnabled: dto.saleVatEnabled,
      saleVatRatePercent: dto.saleVatRatePercent,
      saleFxRateKhrPerUsd: dto.saleFxRateKhrPerUsd,
      saleKhrRoundingEnabled: dto.saleKhrRoundingEnabled,
      saleKhrRoundingMode: dto.saleKhrRoundingMode,
      saleKhrRoundingGranularity: dto.saleKhrRoundingGranularity,
    );
  }

  InventoryPolicy _toInventory(InventoryPolicyDto dto) {
    return InventoryPolicy(
      inventoryAutoSubtractOnSale: dto.inventoryAutoSubtractOnSale,
      inventoryExpiryTrackingEnabled: dto.inventoryExpiryTrackingEnabled,
    );
  }

  CashSessionPolicy _toCashSession(CashSessionPolicyDto dto) {
    return CashSessionPolicy(
      cashAllowPaidOut: dto.cashAllowPaidOut,
      cashRequireRefundApproval: dto.cashRequireRefundApproval,
      cashAllowManualAdjustment: dto.cashAllowManualAdjustment,
    );
  }

  AttendancePolicy _toAttendance(AttendancePolicyDto dto) {
    return AttendancePolicy(
      attendanceAutoFromCashSession: dto.attendanceAutoFromCashSession,
      attendanceRequireOutOfShiftApproval: dto.attendanceRequireOutOfShiftApproval,
      attendanceEarlyCheckinBufferEnabled: dto.attendanceEarlyCheckinBufferEnabled,
      attendanceCheckinBufferMinutes: dto.attendanceCheckinBufferMinutes,
      attendanceAllowManagerEdits: dto.attendanceAllowManagerEdits,
    );
  }
}
