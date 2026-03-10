import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:modular_pos/features/auth/ui/view/login/widgets/login_form_content.dart';
import 'package:modular_pos/features/auth/ui/view/login_view.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

void main() {
  testWidgets('triggers login and signup actions when enabled', (tester) async {
    var loginTapped = 0;
    var signupTapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginFormContent(
            state: const LoginState(),
            phoneCtrl: TextEditingController(),
            passwordCtrl: TextEditingController(),
            obscurePassword: true,
            onToggleObscure: () {},
            onLogin: () => loginTapped += 1,
            onSignup: () => signupTapped += 1,
            footerText: 'login to continue',
          ),
        ),
      ),
    );

    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(loginTapped, 1);
    expect(signupTapped, 1);
    expect(find.text('login to continue'), findsOneWidget);
  });

  testWidgets('shows loading spinner and disables actions when loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginFormContent(
            state: const LoginState(isLoading: true),
            phoneCtrl: TextEditingController(),
            passwordCtrl: TextEditingController(),
            obscurePassword: true,
            onToggleObscure: () {},
            onLogin: () {},
            onSignup: () {},
          ),
        ),
      ),
    );

    final filledButton = tester.widget<FilledButton>(find.byType(FilledButton));
    final textButton = tester.widget<TextButton>(find.byType(TextButton));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(filledButton.onPressed, isNull);
    expect(textButton.onPressed, isNull);
  });

  testWidgets('wide login renders desktop split layout', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );
    await tester.pump();

    expect(find.text('Log into Modula'), findsOneWidget);
    expect(find.text('Modula'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('mobile login keeps the compact mobile layout', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );
    await tester.pump();

    expect(find.text('Login to Modula'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Don’t have an account ?'), findsOneWidget);
    expect(find.text('Forgot password?'), findsNothing);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });
}
