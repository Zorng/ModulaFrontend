import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/ui/view/otp/otp_verification_page.dart';
import 'package:modular_pos/features/auth/ui/view/signup/signup_page.dart';

class _SignupFlowAuthRepository implements AuthRepository {
  _SignupFlowAuthRepository({
    required this.onRegisterAccount,
    required this.onSendRegistrationOtp,
  });

  final Future<AuthRegisterAccountResult> Function({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? dateOfBirth,
  })
  onRegisterAccount;
  final Future<AuthSendOtpResult> Function({required String phone})
  onSendRegistrationOtp;

  @override
  Future<AuthRegisterAccountResult> registerAccount({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? dateOfBirth,
  }) {
    return onRegisterAccount(
      phone: phone,
      password: password,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      dateOfBirth: dateOfBirth,
    );
  }

  @override
  Future<AuthSendOtpResult> sendRegistrationOtp({required String phone}) {
    return onSendRegistrationOtp(phone: phone);
  }

  @override
  Future<AuthVerifyOtpResult> verifyRegistrationOtp({
    required String phone,
    required String otp,
  }) => throw UnimplementedError();

  @override
  Future<AuthPasswordResetRequestResult> requestPasswordReset({
    required String phone,
  }) => throw UnimplementedError();

  @override
  Future<AuthPasswordResetConfirmResult> confirmPasswordReset({
    required String phone,
    required String otp,
    required String newPassword,
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

void main() {
  testWidgets('mobile signup keeps app bar layout', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignupPage())),
    );
    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Date of birth'), findsOneWidget);
    expect(find.text('Back to login'), findsOneWidget);
  });

  testWidgets('wide signup renders centered card on gradient background', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignupPage())),
    );
    await tester.pump();

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(Card), findsOneWidget);
    expect(
      find.text('Set up your account to continue with Modula.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Create account and send OTP'),
      findsOneWidget,
    );
    expect(find.text('select gender'), findsOneWidget);
    expect(find.text('YYYY-MM-DD'), findsOneWidget);
    expect(find.text('Back to login'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Card),
        matching: find.text('Back to login'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('signup still routes to otp page when initial otp send fails', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _SignupFlowAuthRepository(
      onRegisterAccount:
          ({
            required phone,
            required password,
            required firstName,
            required lastName,
            String? gender,
            String? dateOfBirth,
          }) async => AuthRegisterAccountResult(
            accountId: 'account-1',
            phone: phone,
            phoneVerified: false,
            completedExistingInviteAccount: false,
          ),
      onSendRegistrationOtp: ({required phone}) async {
        throw const ApiClientException(
          message: 'Too many OTP requests',
          code: 'OTP_RATE_LIMIT',
          statusCode: 429,
        );
      },
    );

    final router = GoRouter(
      initialLocation: AppRoute.signup.path,
      routes: [
        GoRoute(
          path: AppRoute.signup.path,
          builder: (context, state) => const SignupPage(),
        ),
        GoRoute(
          path: AppRoute.otpVerification.path,
          builder: (context, state) => OtpVerificationPage(
            initialPhone: state.uri.queryParameters['phone'],
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '+85512345678');
    await tester.enterText(find.byType(TextField).at(1), 'StrongPass123!');
    await tester.enterText(find.byType(TextField).at(2), 'Test');
    await tester.enterText(find.byType(TextField).at(3), 'User');

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).at(4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FilledButton, 'Create account and send OTP'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verify phone'), findsOneWidget);
    expect(find.text('Too many OTP requests'), findsOneWidget);
    expect(find.text('Resend OTP'), findsOneWidget);
  });
}
