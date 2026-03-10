import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/ui/view/signup/signup_page.dart';

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
}
