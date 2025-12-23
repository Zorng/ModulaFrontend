import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/policy/data/policy_repository.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

final policyNotifierProvider =
    NotifierProvider<PolicyNotifier, PolicyState>(PolicyNotifier.new);

class PolicyState {
  const PolicyState({
    this.isLoading = false,
    this.error,
    this.salesPolicy = const SalesPolicy(),
    this.inventoryPolicy = const InventoryPolicy(),
    this.cashSessionPolicy = const CashSessionPolicy(),
    this.attendancePolicy = const AttendancePolicy(),
  });

  final bool isLoading;
  final String? error;
  final SalesPolicy salesPolicy;
  final InventoryPolicy inventoryPolicy;
  final CashSessionPolicy cashSessionPolicy;
  final AttendancePolicy attendancePolicy;

  PolicyState copyWith({
    bool? isLoading,
    String? error,
    SalesPolicy? salesPolicy,
    InventoryPolicy? inventoryPolicy,
    CashSessionPolicy? cashSessionPolicy,
    AttendancePolicy? attendancePolicy,
  }) {
    return PolicyState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      salesPolicy: salesPolicy ?? this.salesPolicy,
      inventoryPolicy: inventoryPolicy ?? this.inventoryPolicy,
      cashSessionPolicy: cashSessionPolicy ?? this.cashSessionPolicy,
      attendancePolicy: attendancePolicy ?? this.attendancePolicy,
    );
  }
}

class PolicyNotifier extends Notifier<PolicyState> {
  bool _hasRequestedInitialLoad = false;
  String? _lastBranchId;

  PolicyRepository get _repo => ref.read(policyRepositoryProvider);

  @override
  PolicyState build() {
    final branchId = ref.watch(authActiveBranchIdProvider);
    if (!_hasRequestedInitialLoad || branchId != _lastBranchId) {
      _hasRequestedInitialLoad = true;
      _lastBranchId = branchId;
      // Reset loading state on branch change so UI reflects fresh fetch.
      Future.microtask(() => load(branchId: branchId));
    }
    return const PolicyState(isLoading: true);
  }

  String? get _branchId => ref.read(authActiveBranchIdProvider);

  Future<void> load({String? branchId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bundle = await _repo.fetchPolicies(branchId: branchId);
      state = state.copyWith(
        isLoading: false,
        error: null,
        salesPolicy: bundle.sales,
        inventoryPolicy: bundle.inventory,
        cashSessionPolicy: bundle.cashSession,
        attendancePolicy: bundle.attendance,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateVat({
    required bool enabled,
    required double ratePercent,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bundle = await _repo.updateTax(
        branchId: _branchId,
        saleVatEnabled: enabled,
        saleVatRatePercent: ratePercent,
      );
      state = state.copyWith(
        isLoading: false,
        salesPolicy: bundle.sales,
        inventoryPolicy: bundle.inventory,
        cashSessionPolicy: bundle.cashSession,
        attendancePolicy: bundle.attendance,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateCurrency(double fxRateKhrPerUsd) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bundle =
          await _repo.updateCurrency(
        branchId: _branchId,
        saleFxRateKhrPerUsd: fxRateKhrPerUsd,
      );
      state = state.copyWith(
        isLoading: false,
        salesPolicy: bundle.sales,
        inventoryPolicy: bundle.inventory,
        cashSessionPolicy: bundle.cashSession,
        attendancePolicy: bundle.attendance,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateRounding({
    bool? roundingEnabled,
    String? roundingMode,
    String? roundingGranularity,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bundle = await _repo.updateRounding(
        branchId: _branchId,
        saleKhrRoundingEnabled: roundingEnabled,
        saleKhrRoundingMode: roundingMode,
        saleKhrRoundingGranularity: roundingGranularity,
      );
      state = state.copyWith(
        isLoading: false,
        salesPolicy: bundle.sales,
        inventoryPolicy: bundle.inventory,
        cashSessionPolicy: bundle.cashSession,
        attendancePolicy: bundle.attendance,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateInventory({
    bool? autoSubtractOnSale,
    bool? expiryTrackingEnabled,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bundle = await _repo.updateInventory(
        branchId: _branchId,
        inventoryAutoSubtractOnSale: autoSubtractOnSale,
        inventoryExpiryTrackingEnabled: expiryTrackingEnabled,
      );
      state = state.copyWith(
        isLoading: false,
        salesPolicy: bundle.sales,
        inventoryPolicy: bundle.inventory,
        cashSessionPolicy: bundle.cashSession,
        attendancePolicy: bundle.attendance,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateCashSession({
    bool? requireSessionForSales,
    bool? allowPaidOut,
    bool? requireRefundApproval,
    bool? allowManualAdjustment,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bundle = await _repo.updateCashSession(
        branchId: _branchId,
        cashRequireSessionForSales: requireSessionForSales,
        cashAllowPaidOut: allowPaidOut,
        cashRequireRefundApproval: requireRefundApproval,
        cashAllowManualAdjustment: allowManualAdjustment,
      );
      state = state.copyWith(
        isLoading: false,
        salesPolicy: bundle.sales,
        inventoryPolicy: bundle.inventory,
        cashSessionPolicy: bundle.cashSession,
        attendancePolicy: bundle.attendance,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateAttendance({
    bool? autoFromCashSession,
    bool? requireOutOfShiftApproval,
    bool? earlyCheckinBufferEnabled,
    int? checkinBufferMinutes,
    bool? allowManagerEdits,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bundle = await _repo.updateAttendance(
        branchId: _branchId,
        attendanceAutoFromCashSession: autoFromCashSession,
        attendanceRequireOutOfShiftApproval: requireOutOfShiftApproval,
        attendanceEarlyCheckinBufferEnabled: earlyCheckinBufferEnabled,
        attendanceCheckinBufferMinutes: checkinBufferMinutes,
        attendanceAllowManagerEdits: allowManagerEdits,
      );
      state = state.copyWith(
        isLoading: false,
        salesPolicy: bundle.sales,
        inventoryPolicy: bundle.inventory,
        cashSessionPolicy: bundle.cashSession,
        attendancePolicy: bundle.attendance,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
