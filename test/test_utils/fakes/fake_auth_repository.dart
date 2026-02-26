import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';

/// Minimal fake used for tests that don't exercise auth flows.
class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthRegisterAccountResult> registerAccount({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? dateOfBirth,
  }) {
    throw UnimplementedError(
      'FakeAuthRepository.registerAccount is not implemented',
    );
  }

  @override
  Future<AuthSendOtpResult> sendRegistrationOtp({required String phone}) {
    throw UnimplementedError(
      'FakeAuthRepository.sendRegistrationOtp is not implemented',
    );
  }

  @override
  Future<AuthVerifyOtpResult> verifyRegistrationOtp({
    required String phone,
    required String otp,
  }) {
    throw UnimplementedError(
      'FakeAuthRepository.verifyRegistrationOtp is not implemented',
    );
  }

  @override
  Future<AuthSession> login(String username, String password) {
    throw UnimplementedError('FakeAuthRepository.login is not implemented');
  }

  @override
  Future<AuthSession> selectTenant({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  }) {
    throw UnimplementedError(
      'FakeAuthRepository.selectTenant is not implemented',
    );
  }

  @override
  Future<AuthBranchContextOptions> listBranchContexts({
    required AuthSession currentSession,
  }) {
    throw UnimplementedError(
      'FakeAuthRepository.listBranchContexts is not implemented',
    );
  }

  @override
  Future<AuthSession> selectBranch({
    required AuthSession currentSession,
    required String branchId,
    bool verifyCurrentBranchProfile = true,
  }) {
    throw UnimplementedError(
      'FakeAuthRepository.selectBranch is not implemented',
    );
  }

  @override
  Future<AuthSession> refreshSession({required AuthSession currentSession}) {
    throw UnimplementedError(
      'FakeAuthRepository.refreshSession is not implemented',
    );
  }

  @override
  Future<void> logout({String? refreshToken}) {
    throw UnimplementedError('FakeAuthRepository.logout is not implemented');
  }
}
