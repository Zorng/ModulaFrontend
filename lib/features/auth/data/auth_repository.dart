import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/features/auth/data/auth_api.dart';
import 'package:modular_pos/features/auth/data/mock_auth_repository.dart';
import 'package:modular_pos/features/auth/data/remote_auth_repository.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';

class AuthRegisterAccountResult {
  const AuthRegisterAccountResult({
    required this.accountId,
    required this.phone,
    required this.phoneVerified,
    required this.completedExistingInviteAccount,
  });

  final String accountId;
  final String phone;
  final bool phoneVerified;
  final bool completedExistingInviteAccount;
}

class AuthSendOtpResult {
  const AuthSendOtpResult({required this.expiresInMinutes});

  final int expiresInMinutes;
}

class AuthVerifyOtpResult {
  const AuthVerifyOtpResult({required this.verified});

  final bool verified;
}

class AuthBranchContextOption {
  const AuthBranchContextOption({
    required this.branchId,
    required this.branchName,
  });

  final String branchId;
  final String branchName;
}

class AuthBranchContextOptions {
  const AuthBranchContextOptions({
    required this.state,
    required this.tenantId,
    required this.selectedBranchId,
    required this.branches,
  });

  final String state;
  final String? tenantId;
  final String? selectedBranchId;
  final List<AuthBranchContextOption> branches;

  bool get requiresSelection =>
      state == 'BRANCH_SELECTION_REQUIRED' || state == 'NO_BRANCH_ASSIGNED';
}

abstract class AuthRepository {
  Future<AuthRegisterAccountResult> registerAccount({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? dateOfBirth,
  });

  Future<AuthSendOtpResult> sendRegistrationOtp({required String phone});

  Future<AuthVerifyOtpResult> verifyRegistrationOtp({
    required String phone,
    required String otp,
  });

  Future<AuthSession> login(String username, String password);

  Future<AuthSession> selectTenant({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  });

  Future<AuthBranchContextOptions> listBranchContexts({
    required AuthSession currentSession,
  });

  Future<AuthSession> selectBranch({
    required AuthSession currentSession,
    required String branchId,
    bool verifyCurrentBranchProfile = true,
  });

  Future<AuthSession> refreshSession({required AuthSession currentSession});

  Future<void> logout({String? refreshToken});
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final useMock = ref.watch(useMockAuthRepositoryProvider);
  if (useMock) return MockAuthRepository();
  final api = ref.read(authApiProvider);
  return RemoteAuthRepository(api);
});

final useMockAuthRepositoryProvider = Provider<bool>(
  (ref) => AppEnv.useMockAuthRepository,
);
