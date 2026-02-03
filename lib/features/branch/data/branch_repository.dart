import 'package:modular_pos/features/branch/domain/models/branch.dart';
import 'package:modular_pos/features/branch/data/branch_api.dart';
import 'package:modular_pos/features/branch/data/branch_mapper.dart';

/// Branch repository - maps DTO to domain models
class BranchRepository {
  final BranchApi _api;

  const BranchRepository(this._api);

  /// List all accessible branches
  Future<List<Branch>> listBranches() async {
    final dtos = await _api.listBranches();
    return BranchMapper.toDomainList(dtos);
  }

  /// Get a single branch by ID
  Future<Branch> getBranch(String branchId) async {
    final dto = await _api.getBranch(branchId);
    return BranchMapper.toDomain(dto);
  }

  /// Update branch profile (Admin only)
  Future<Branch> updateBranch({
    required String branchId,
    String? name,
    String? address,
    String? contactPhone,
    String? contactEmail,
  }) async {
    final dto = await _api.updateBranch(
      branchId: branchId,
      name: name,
      address: address,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
    );
    return BranchMapper.toDomain(dto);
  }

  /// Freeze a branch (Admin only)
  Future<Branch> freezeBranch(String branchId) async {
    final dto = await _api.freezeBranch(branchId);
    return BranchMapper.toDomain(dto);
  }

  /// Unfreeze a branch (Admin only)
  Future<Branch> unfreezeBranch(String branchId) async {
    final dto = await _api.unfreezeBranch(branchId);
    return BranchMapper.toDomain(dto);
  }
}
