import 'package:modular_pos/features/policy/data/policy_mapper.dart';
import 'package:modular_pos/features/policy/data/policy_api.dart';
import 'package:modular_pos/features/policy/data/policy_repository.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

class RemotePolicyRepository implements PolicyRepository {
  RemotePolicyRepository(this._api);

  final PolicyApi _api;

  @override
  Future<BranchPolicy> fetchCurrentBranchPolicy() async {
    final dto = await _api.getCurrentBranchPolicy();
    return mapBranchPolicyDto(dto);
  }

  @override
  Future<BranchPolicy> updateCurrentBranchPolicy({
    bool? saleVatEnabled,
    double? saleVatRatePercent,
    double? saleFxRateKhrPerUsd,
    bool? saleKhrRoundingEnabled,
    String? saleKhrRoundingMode,
    String? saleKhrRoundingGranularity,
    bool? saleAllowPayLater,
  }) async {
    final dto = await _api.updateCurrentBranchPolicy(
      saleVatEnabled: saleVatEnabled,
      saleVatRatePercent: saleVatRatePercent,
      saleFxRateKhrPerUsd: saleFxRateKhrPerUsd,
      saleKhrRoundingEnabled: saleKhrRoundingEnabled,
      saleKhrRoundingMode: saleKhrRoundingMode,
      saleKhrRoundingGranularity: saleKhrRoundingGranularity,
      saleAllowPayLater: saleAllowPayLater,
    );
    return mapBranchPolicyDto(dto);
  }
}
