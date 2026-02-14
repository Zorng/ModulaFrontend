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
/// Provider to check if mock data is being used
final useMockBranchRepositoryProvider = Provider<bool>((ref) {
  final loginState = ref.watch(loginControllerProvider);
  final userPhone = loginState.session?.user.phone ?? '';
  return userPhone == '+1234567890';
});

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  // Check if logged-in user is +1234567890
  final useMock = ref.watch(useMockBranchRepositoryProvider);
  
  if (useMock) {
    final mockRepo = ref.watch(branchMockRepositoryProvider);
    return BranchRepository.mock(mockRepo);
  }
  
  final api = ref.watch(branchApiProvider);
  return BranchRepository(api);
});
