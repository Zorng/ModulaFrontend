import 'package:dio/dio.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/features/branch/data/dto/branch_dto.dart';

/// Branch API client
class BranchApi {
  final Dio _dio;
  final String _prefix;

  BranchApi(this._dio) : _prefix = AppEnv.branchApiPrefix;

  /// List all accessible branches for the authenticated user
  Future<List<BranchDto>> listBranches() async {
    final response = await _dio.get(_prefix);

    final data = response.data;
    if (data == null || data['branches'] == null) {
      return [];
    }

    final branches = data['branches'] as List<dynamic>;
    return branches
        .map((json) => BranchDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single branch by ID
  Future<BranchDto> getBranch(String branchId) async {
    final response = await _dio.get('$_prefix/$branchId');

    final data = response.data;
    if (data == null || data['branch'] == null) {
      throw Exception('Branch not found');
    }

    return BranchDto.fromJson(data['branch'] as Map<String, dynamic>);
  }

  /// Update branch profile (Admin only)
  Future<BranchDto> updateBranch({
    required String branchId,
    String? name,
    String? address,
    String? contactPhone,
    String? contactEmail,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (contactPhone != null) body['contact_phone'] = contactPhone;
    if (contactEmail != null) body['contact_email'] = contactEmail;

    final response = await _dio.patch('$_prefix/$branchId', data: body);

    final data = response.data;
    if (data == null || data['branch'] == null) {
      throw Exception('Failed to update branch');
    }

    return BranchDto.fromJson(data['branch'] as Map<String, dynamic>);
  }

  /// Freeze a branch (Admin only)
  Future<BranchDto> freezeBranch(String branchId) async {
    final response = await _dio.post('$_prefix/$branchId/freeze');

    final data = response.data;
    if (data == null || data['branch'] == null) {
      throw Exception('Failed to freeze branch');
    }

    return BranchDto.fromJson(data['branch'] as Map<String, dynamic>);
  }

  /// Unfreeze a branch (Admin only)
  Future<BranchDto> unfreezeBranch(String branchId) async {
    final response = await _dio.post('$_prefix/$branchId/unfreeze');

    final data = response.data;
    if (data == null || data['branch'] == null) {
      throw Exception('Failed to unfreeze branch');
    }

    return BranchDto.fromJson(data['branch'] as Map<String, dynamic>);
  }
}
