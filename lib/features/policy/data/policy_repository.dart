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

  Future<PolicyBundle> fetchPolicies() async {
    final payload = await _api.getPolicies();
    final sales = SalesPolicy.fromJson(payload);
    final inventory = InventoryPolicy.fromJson(payload);
    return PolicyBundle(sales: sales, inventory: inventory);
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
    required bool saleVatEnabled,
    required double saleVatRatePercent,
  }) async {
    await _api.updateTax(
      saleVatEnabled: saleVatEnabled,
      saleVatRatePercent: saleVatRatePercent,
    );
    return fetchPolicies();
  }

  Future<PolicyBundle> updateCurrency({
    required double saleFxRateKhrPerUsd,
  }) async {
    await _api.updateCurrency(saleFxRateKhrPerUsd: saleFxRateKhrPerUsd);
    return fetchPolicies();
  }

  Future<PolicyBundle> updateRounding({
    bool? saleKhrRoundingEnabled,
    String? saleKhrRoundingMode,
    String? saleKhrRoundingGranularity,
  }) async {
    await _api.updateRounding(
      saleKhrRoundingEnabled: saleKhrRoundingEnabled,
      saleKhrRoundingMode: saleKhrRoundingMode,
      saleKhrRoundingGranularity: saleKhrRoundingGranularity,
    );
    return fetchPolicies();
  }

  Future<PolicyBundle> updateInventory({
    bool? inventoryAutoSubtractOnSale,
    bool? inventoryExpiryTrackingEnabled,
  }) async {
    await _api.updateInventory(
      inventoryAutoSubtractOnSale: inventoryAutoSubtractOnSale,
      inventoryExpiryTrackingEnabled: inventoryExpiryTrackingEnabled,
    );
    return fetchPolicies();
  }
}
