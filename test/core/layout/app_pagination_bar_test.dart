import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/widgets/layout/app_pagination_bar.dart';

import '../../test_utils/pump_app.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders on wide layouts without layout exceptions', (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 800));
    addTearDown(() => _resetViewport(tester));

    await pumpApp(
      tester,
      const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: AppPaginationBar(
            rangeLabel: 'Showing 11-20 entries',
            canGoPrevious: true,
            canGoNext: true,
            isLoading: false,
            onPrevious: _noop,
            onNext: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Showing 11-20 entries'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('renders on narrow layouts without layout exceptions', (
    tester,
  ) async {
    _setViewport(tester, const Size(360, 800));
    addTearDown(() => _resetViewport(tester));

    await pumpApp(
      tester,
      const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: AppPaginationBar(
            rangeLabel:
                'Showing 111-120 entries with a longer range label for wrapping',
            canGoPrevious: true,
            canGoNext: true,
            isLoading: false,
            onPrevious: _noop,
            onNext: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}

void _noop() {}
