import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/branch/data/branch_api.dart';
import 'package:modular_pos/features/branch/data/branch_repository.dart';

/// Branch API provider
final branchApiProvider = Provider<BranchApi>((ref) {
  final dio = ref.watch(dioProvider);
  return BranchApi(dio);
});

/// Branch repository provider
final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  final api = ref.watch(branchApiProvider);
  return BranchRepository(api);
});
