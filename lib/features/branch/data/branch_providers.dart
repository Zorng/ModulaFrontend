import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branch/data/branch_api.dart';
import 'package:modular_pos/features/branch/data/branch_repository.dart';
import 'package:modular_pos/features/branch/data/branch_mock_repository.dart';

/// Branch API provider
final branchApiProvider = Provider<BranchApi>((ref) {
  final dio = ref.watch(dioProvider);
  return BranchApi(dio);
});

/// Mock branch repository provider
final branchMockRepositoryProvider = Provider<BranchMockRepository>((ref) {
  return BranchMockRepository();
});

/// Branch repository provider - uses mock repository for phone +1234567890, real API for others
final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  // Check if logged-in user is +1234567890
  final loginState = ref.watch(loginControllerProvider);
  final userPhone = loginState.session?.user.phone ?? '';
  
  final useMock = userPhone == '+1234567890';
  
  if (useMock) {
    final mockRepo = ref.watch(branchMockRepositoryProvider);
    return BranchRepository.mock(mockRepo);
  }
  
  final api = ref.watch(branchApiProvider);
  return BranchRepository(api);
});
