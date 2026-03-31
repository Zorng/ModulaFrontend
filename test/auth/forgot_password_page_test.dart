import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/ui/view/forgot_password/forgot_password_confirm_page.dart';
import 'package:modular_pos/features/auth/ui/view/forgot_password/forgot_password_request_page.dart';
import 'package:modular_pos/features/auth/ui/view/login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ForgotPasswordPageAuthRepository implements AuthRepository {
  _ForgotPasswordPageAuthRepository({
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
    throw UnimplementedError();
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
    throw UnimplementedError();
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

Future<Widget> _routerHarness(AuthRepository repository) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final store = AuthSessionStore(prefs);
  final router = GoRouter(
    initialLocation: AppRoute.forgotPassword.path,
    routes: [
      GoRoute(
        path: AppRoute.forgotPassword.path,
        builder: (context, state) => ForgotPasswordRequestPage(
          initialPhone: state.uri.queryParameters['phone'],
        ),
      ),
      GoRoute(
        path: AppRoute.forgotPasswordConfirm.path,
        builder: (context, state) => ForgotPasswordConfirmPage(
          initialPhone: state.uri.queryParameters['phone'],
        ),
      ),
      GoRoute(
        path: AppRoute.login.path,
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      authSessionStoreProvider.overrideWithValue(store),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('forgot password request page keeps mobile auth layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      await _routerHarness(_ForgotPasswordPageAuthRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Forgot password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Send OTP'), findsOneWidget);
    expect(find.text('Back to login'), findsOneWidget);
  });

  testWidgets('request flow routes to confirm page with same phone', (
    tester,
  ) async {
    await tester.pumpWidget(
      await _routerHarness(
        _ForgotPasswordPageAuthRepository(
          onRequestPasswordReset: ({required phone}) async =>
              const AuthPasswordResetRequestResult(expiresInMinutes: 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '+85512345678');
    await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Reset password'), findsOneWidget);
    expect(find.text('OTP expires in 10 minutes.'), findsOneWidget);
    expect(find.text('+85512345678'), findsOneWidget);
  });

  testWidgets('confirm flow returns to login after successful reset', (
    tester,
  ) async {
    await tester.pumpWidget(
      await _routerHarness(
        _ForgotPasswordPageAuthRepository(
          onRequestPasswordReset: ({required phone}) async =>
              const AuthPasswordResetRequestResult(expiresInMinutes: 10),
          onConfirmPasswordReset:
              ({required phone, required otp, required newPassword}) async =>
                  const AuthPasswordResetConfirmResult(reset: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '+85512345678');
    await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.enterText(find.byType(TextField).at(2), 'NewPass123!');
    await tester.enterText(find.byType(TextField).at(3), 'NewPass123!');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Reset password'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });
}
