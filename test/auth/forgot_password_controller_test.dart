import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/forgot_password_controller.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/riverpod_test_utils.dart';

class _ForgotPasswordAuthRepository implements AuthRepository {
  _ForgotPasswordAuthRepository({
    this.onRequestPasswordReset,
    this.onConfirmPasswordReset,
  });

  final Future<AuthPasswordResetRequestResult> Function({
    required String phone,
  })?
  onRequestPasswordReset;
  final Future<AuthPasswordResetConfirmResult> Function({
    required String phone,
    required String otp,
    required String newPassword,
  })?
  onConfirmPasswordReset;

  @override
  Future<AuthPasswordResetRequestResult> requestPasswordReset({
    required String phone,
  }) {
    if (onRequestPasswordReset != null) {
      return onRequestPasswordReset!(phone: phone);
    }
    throw UnimplementedError('requestPasswordReset not configured');
  }

  @override
  Future<AuthPasswordResetConfirmResult> confirmPasswordReset({
    required String phone,
    required String otp,
    required String newPassword,
  }) {
    if (onConfirmPasswordReset != null) {
      return onConfirmPasswordReset!(
        phone: phone,
        otp: otp,
        newPassword: newPassword,
      );
    }
    throw UnimplementedError('confirmPasswordReset not configured');
  }

  @override
  Future<AuthRegisterAccountResult> registerAccount({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? dateOfBirth,
  }) => throw UnimplementedError();

  @override
  Future<AuthSendOtpResult> sendRegistrationOtp({required String phone}) =>
      throw UnimplementedError();

  @override
  Future<AuthVerifyOtpResult> verifyRegistrationOtp({
    required String phone,
    required String otp,
  }) => throw UnimplementedError();

  @override
  Future<AuthSession> login(String username, String password) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> selectTenant({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  }) => throw UnimplementedError();

  @override
  Future<AuthBranchContextOptions> listBranchContexts({
    required AuthSession currentSession,
  }) => throw UnimplementedError();

  @override
  Future<AuthSession> selectBranch({
    required AuthSession currentSession,
    required String branchId,
    bool verifyCurrentBranchProfile = true,
  }) => throw UnimplementedError();

  @override
  Future<AuthSession> refreshSession({required AuthSession currentSession}) =>
      throw UnimplementedError();

  @override
  Future<void> logout({String? refreshToken}) async {}
}

AuthSession _session() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: 'ADMIN',
      tenantId: 'tenant-1',
      phone: '+85512345678',
      status: 'ACTIVE',
    ),
    memberships: const [],
    activeTenantId: 'tenant-1',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('requestResetOtp stores phone and expiry on success', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);

    final container = createTestContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _ForgotPasswordAuthRepository(
            onRequestPasswordReset: ({required phone}) async =>
                const AuthPasswordResetRequestResult(expiresInMinutes: 10),
          ),
        ),
        authSessionStoreProvider.overrideWithValue(store),
      ],
    );

    final success = await container
        .read(forgotPasswordControllerProvider.notifier)
        .requestResetOtp(phone: '+85512345678');

    final state = container.read(forgotPasswordControllerProvider);
    expect(success, isTrue);
    expect(state.phone, '+85512345678');
    expect(state.otpExpiresInMinutes, 10);
    expect(state.error, isNull);
  });

  test('confirmReset clears current auth session after success', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);
    final initialSession = _session();
    await store.save(initialSession);

    final container = createTestContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _ForgotPasswordAuthRepository(
            onConfirmPasswordReset:
                ({required phone, required otp, required newPassword}) async =>
                    const AuthPasswordResetConfirmResult(reset: true),
          ),
        ),
        authSessionStoreProvider.overrideWithValue(store),
        initialAuthSessionProvider.overrideWithValue(initialSession),
      ],
    );

    final success = await container
        .read(forgotPasswordControllerProvider.notifier)
        .confirmReset(
          phone: '+85512345678',
          otp: '123456',
          newPassword: 'NewPass123!',
        );

    expect(success, isTrue);
    expect(container.read(loginControllerProvider).session, isNull);
    expect(await store.load(), isNull);
  });
}
