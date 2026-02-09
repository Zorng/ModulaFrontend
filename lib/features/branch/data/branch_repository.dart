import 'package:modular_pos/features/branch/domain/models/branch.dart';
import 'package:modular_pos/features/branch/data/branch_api.dart';
import 'package:modular_pos/features/branch/data/branch_mapper.dart';
import 'package:modular_pos/features/branch/data/branch_mock_repository.dart';

/// Branch repository - maps DTO to domain models
class BranchRepository {
  final BranchApi? _api;
  final BranchMockRepository? _mockRepo;

  const BranchRepository(BranchApi api)
      : _api = api,
        _mockRepo = null;

  const BranchRepository.mock(BranchMockRepository mockRepo)
      : _mockRepo = mockRepo,
        _api = null;

  bool get _isMock => _mockRepo != null;

  /// List all accessible branches
  Future<List<Branch>> listBranches() async {
    if (_isMock) {
      return _mockRepo!.listBranches();
    }
    final dtos = await _api!.listBranches();
    return BranchMapper.toDomainList(dtos);
  }

  /// Get a single branch by ID
  Future<Branch> getBranch(String branchId) async {
    if (_isMock) {
      return _mockRepo!.getBranch(branchId);
    }
    final dto = await _api!.getBranch(branchId);
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
    if (_isMock) {
      return _mockRepo!.updateBranch(
        branchId: branchId,
        name: name,
        address: address,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
      );
    }
    final dto = await _api!.updateBranch(
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
    if (_isMock) {
      return _mockRepo!.freezeBranch(branchId);
    }
    final dto = await _api!.freezeBranch(branchId);
    return BranchMapper.toDomain(dto);
  }

  /// Unfreeze a branch (Admin only)
  Future<Branch> unfreezeBranch(String branchId) async {
    if (_isMock) {
      return _mockRepo!.unfreezeBranch(branchId);
    }
    final dto = await _api!.unfreezeBranch(branchId);
    return BranchMapper.toDomain(dto);
  }
}
