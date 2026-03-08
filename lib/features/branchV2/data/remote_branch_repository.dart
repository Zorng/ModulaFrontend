import 'package:modular_pos/features/branchV2/data/branch_api.dart';
import 'package:modular_pos/features/branchV2/data/branch_mapper.dart';
import 'package:modular_pos/features/branchV2/data/branch_repository.dart';
import 'package:modular_pos/features/branchV2/data/dto/branch_dto.dart';
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
  Future<BranchListItem> getCurrentBranchProfile({
    String? accessTokenOverride,
  }) async {
    final dto = await _api.getCurrentBranchProfile(
      accessTokenOverride: accessTokenOverride,
    );
    return BranchMapper.toBranchListItem(dto);
  }

  @override
  Future<BranchListItem> updateCurrentBranchKhqrReceiver({
    required String khqrReceiverAccountId,
    required String khqrReceiverName,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    final dto = await _api.updateCurrentBranchKhqrReceiver(
      khqrReceiverAccountId: khqrReceiverAccountId,
      khqrReceiverName: khqrReceiverName,
      intentId: intentId,
      accessTokenOverride: accessTokenOverride,
    );
    return BranchMapper.toBranchListItem(dto);
  }

  @override
  Future<BranchListItem> updateCurrentBranchAttendanceLocation({
    required String attendanceLocationVerificationMode,
    BranchWorkplaceLocation? workplaceLocation,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    final dto = await _api.updateCurrentBranchAttendanceLocation(
      attendanceLocationVerificationMode: attendanceLocationVerificationMode,
      workplaceLocation: workplaceLocation == null
          ? null
          : BranchWorkplaceLocationDto(
              latitude: workplaceLocation.latitude,
              longitude: workplaceLocation.longitude,
              radiusMeters: workplaceLocation.radiusMeters,
            ),
      intentId: intentId,
      accessTokenOverride: accessTokenOverride,
    );
    return BranchMapper.toBranchListItem(dto);
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
