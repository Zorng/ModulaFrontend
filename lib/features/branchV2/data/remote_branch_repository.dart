import 'package:modular_pos/features/branchV2/data/branch_api.dart';
import 'package:modular_pos/features/branchV2/data/branch_mapper.dart';
import 'package:modular_pos/features/branchV2/data/branch_repository.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';

class RemoteBranchRepository implements BranchRepository {
  RemoteBranchRepository(this._api);

  final BranchApi _api;

  @override
  Future<List<BranchListItem>> loadAccessibleBranches() async {
    final dtos = await _api.loadAccessibleBranches();
    return BranchMapper.toBranchListItems(dtos);
  }

  @override
  Future<BranchListItem> getCurrentBranchProfile() async {
    final dto = await _api.getCurrentBranchProfile();
    return BranchMapper.toCurrentBranchProfile(dto);
  }

  @override
  Future<BranchListItem> updateCurrentBranchKhqrReceiver({
    required String khqrReceiverAccountId,
    required String khqrReceiverName,
  }) async {
    final dto = await _api.updateCurrentBranchKhqrReceiver(
      khqrReceiverAccountId: khqrReceiverAccountId,
      khqrReceiverName: khqrReceiverName,
    );
    return BranchMapper.toCurrentBranchProfile(dto);
  }

  @override
  Future<BranchActivationDraft> initiateBranchActivation({
    required String branchName,
    String? intentId,
  }) async {
    final dto = await _api.initiateBranchActivation(
      branchName: branchName,
      intentId: intentId,
    );
    return BranchMapper.toActivationDraft(dto);
  }

  @override
  Future<BranchActivationResult> confirmBranchActivation({
    required String draftId,
    required String paymentToken,
    String? intentId,
  }) async {
    final dto = await _api.confirmBranchActivation(
      draftId: draftId,
      paymentToken: paymentToken,
      intentId: intentId,
    );
    return BranchMapper.toActivationResult(dto);
  }

  @override
  Future<BranchContextTokens> selectBranchContext({
    required String branchId,
  }) async {
    final dto = await _api.selectBranchContext(branchId: branchId);
    return BranchMapper.toContextTokens(dto);
  }
}
