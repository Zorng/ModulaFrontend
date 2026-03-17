import 'package:modular_pos/features/policy/data/dto/policy_dto.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

BranchPolicy mapBranchPolicyDto(
  BranchPolicyDto dto, {
  String? tenantIdFallback,
  String? branchIdFallback,
}) {
  return BranchPolicy(
    tenantId: dto.tenantId.trim().isNotEmpty
        ? dto.tenantId.trim()
        : (tenantIdFallback ?? '').trim(),
    branchId: dto.branchId.trim().isNotEmpty
        ? dto.branchId.trim()
        : (branchIdFallback ?? '').trim(),
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
