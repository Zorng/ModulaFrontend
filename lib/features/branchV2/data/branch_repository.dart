import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/features/branchV2/data/branch_api.dart';
import 'package:modular_pos/features/branchV2/data/mock_branch_repository.dart';
import 'package:modular_pos/features/branchV2/data/remote_branch_repository.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';

abstract class BranchRepository {
  Future<List<BranchListItem>> loadAccessibleBranches();

  Future<BranchActivationDraft> initiateBranchActivation({
    required String branchName,
    String? intentId,
  });

  Future<BranchActivationResult> confirmBranchActivation({
    required String draftId,
    required String paymentToken,
    String? intentId,
  });

  Future<BranchContextTokens> selectBranchContext({
    required String branchId,
  });
}

final useMockBranchRepositoryProvider = Provider<bool>(
  (ref) => AppEnv.useMockBranchRepository,
);

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  final useMock = ref.watch(useMockBranchRepositoryProvider);
  if (useMock) {
    return MockBranchRepository();
  }

  final api = ref.read(branchApiProvider);
  return RemoteBranchRepository(api);
});
