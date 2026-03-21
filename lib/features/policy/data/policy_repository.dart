import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/features/policy/data/mock_policy_repository.dart';
import 'package:modular_pos/features/policy/data/policy_api.dart';
import 'package:modular_pos/features/policy/data/remote_policy_repository.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

abstract class PolicyRepository {
  Future<BranchPolicy> fetchCurrentBranchPolicy();

  Future<BranchPolicy> updateCurrentBranchPolicy({
    bool? saleVatEnabled,
    double? saleVatRatePercent,
    double? saleFxRateKhrPerUsd,
    bool? saleKhrRoundingEnabled,
    String? saleKhrRoundingMode,
    String? saleKhrRoundingGranularity,
    bool? saleAllowPayLater,
    bool? saleAllowManualExternalPaymentClaim,
  });
}

final useMockPolicyRepositoryProvider = Provider<bool>(
  (ref) => AppEnv.useMockPolicyRepository,
);

final remotePolicyRepositoryProvider = Provider<PolicyRepository>((ref) {
  final api = ref.watch(policyApiProvider);
  return RemotePolicyRepository(api);
});

final mockPolicyRepositoryProvider = Provider<PolicyRepository>((ref) {
  return MockPolicyRepository();
});

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  final useMock = ref.watch(useMockPolicyRepositoryProvider);
  if (useMock) {
    return ref.watch(mockPolicyRepositoryProvider);
  }
  return ref.watch(remotePolicyRepositoryProvider);
});
