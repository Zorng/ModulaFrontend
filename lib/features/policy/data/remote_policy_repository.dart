import 'package:modular_pos/features/policy/data/dto/policy_dto.dart';
import 'package:modular_pos/features/policy/data/policy_api.dart';
import 'package:modular_pos/features/policy/data/policy_repository.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

class RemotePolicyRepository implements PolicyRepository {
  RemotePolicyRepository(this._api);

  final PolicyApi _api;

  @override
  Future<BranchPolicy> fetchCurrentBranchPolicy() async {
    final dto = await _api.getCurrentBranchPolicy();
    return _toBranchPolicy(dto);
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
    return _toBranchPolicy(dto);
  }

  BranchPolicy _toBranchPolicy(BranchPolicyDto dto) {
    return BranchPolicy(
      tenantId: dto.tenantId,
      branchId: dto.branchId,
      saleVatEnabled: dto.saleVatEnabled,
      saleVatRatePercent: dto.saleVatRatePercent,
      saleFxRateKhrPerUsd: dto.saleFxRateKhrPerUsd,
      saleKhrRoundingEnabled: dto.saleKhrRoundingEnabled,
      saleKhrRoundingMode: BranchPolicyRoundingModes.normalize(
        dto.saleKhrRoundingMode,
      ),
      saleKhrRoundingGranularity: BranchPolicyRoundingGranularities.normalize(
        dto.saleKhrRoundingGranularity,
      ),
      saleAllowPayLater: dto.saleAllowPayLater,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }
}
