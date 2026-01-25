import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Pumps a widget wrapped in a minimal app + ProviderScope.
///
/// Use for widget tests that need:
/// - Material theme/scaffold
/// - Riverpod provider overrides
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  NavigatorObserver? navigatorObserver,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
        navigatorObservers: navigatorObserver == null
            ? const []
            : [navigatorObserver],
      ),
    ),
  );
  await tester.pump();
}
