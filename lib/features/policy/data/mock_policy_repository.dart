import 'package:modular_pos/features/policy/data/policy_repository.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

class MockPolicyRepository implements PolicyRepository {
  MockPolicyRepository()
    : _policy = const BranchPolicy(
        tenantId: 'tenant-001',
        branchId: 'branch-001',
        saleVatEnabled: true,
        saleVatRatePercent: 10,
        saleFxRateKhrPerUsd: 4100,
        saleKhrRoundingEnabled: true,
        saleKhrRoundingMode: BranchPolicyRoundingModes.nearest,
        saleKhrRoundingGranularity: BranchPolicyRoundingGranularities.hundred,
        saleAllowPayLater: true,
        createdAt: '2026-02-17T10:00:00.000Z',
        updatedAt: '2026-02-17T10:00:00.000Z',
      );

  BranchPolicy _policy;

  @override
  Future<BranchPolicy> fetchCurrentBranchPolicy() async {
    return _policy;
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
    _policy = _policy.copyWith(
      saleVatEnabled: saleVatEnabled,
      saleVatRatePercent: saleVatRatePercent,
      saleFxRateKhrPerUsd: saleFxRateKhrPerUsd,
      saleKhrRoundingEnabled: saleKhrRoundingEnabled,
      saleKhrRoundingMode: saleKhrRoundingMode,
      saleKhrRoundingGranularity: saleKhrRoundingGranularity,
      saleAllowPayLater: saleAllowPayLater,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    return _policy;
  }
}
