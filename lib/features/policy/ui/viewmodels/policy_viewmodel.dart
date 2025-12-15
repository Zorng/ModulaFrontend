import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  });

  final bool isLoading;
  final String? error;
  final SalesPolicy salesPolicy;
  final InventoryPolicy inventoryPolicy;

  PolicyState copyWith({
    bool? isLoading,
    String? error,
    SalesPolicy? salesPolicy,
    InventoryPolicy? inventoryPolicy,
  }) {
    return PolicyState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      salesPolicy: salesPolicy ?? this.salesPolicy,
      inventoryPolicy: inventoryPolicy ?? this.inventoryPolicy,
    );
  }
}

class PolicyNotifier extends Notifier<PolicyState> {
  bool _hasRequestedInitialLoad = false;

  PolicyRepository get _repo => ref.read(policyRepositoryProvider);

  @override
  PolicyState build() {
    if (!_hasRequestedInitialLoad) {
      _hasRequestedInitialLoad = true;
      Future.microtask(load);
    }
    return const PolicyState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bundle = await _repo.fetchPolicies();
      state = state.copyWith(
        isLoading: false,
        error: null,
        salesPolicy: bundle.sales,
        inventoryPolicy: bundle.inventory,
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
        saleVatEnabled: enabled,
        saleVatRatePercent: ratePercent,
      );
      state = state.copyWith(
        isLoading: false,
        salesPolicy: bundle.sales,
        inventoryPolicy: bundle.inventory,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateCurrency(double fxRateKhrPerUsd) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bundle =
          await _repo.updateCurrency(saleFxRateKhrPerUsd: fxRateKhrPerUsd);
      state = state.copyWith(
        isLoading: false,
        salesPolicy: bundle.sales,
        inventoryPolicy: bundle.inventory,
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
        saleKhrRoundingEnabled: roundingEnabled,
        saleKhrRoundingMode: roundingMode,
        saleKhrRoundingGranularity: roundingGranularity,
      );
      state = state.copyWith(
        isLoading: false,
        salesPolicy: bundle.sales,
        inventoryPolicy: bundle.inventory,
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
        inventoryAutoSubtractOnSale: autoSubtractOnSale,
        inventoryExpiryTrackingEnabled: expiryTrackingEnabled,
      );
      state = state.copyWith(
        isLoading: false,
        salesPolicy: bundle.sales,
        inventoryPolicy: bundle.inventory,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
