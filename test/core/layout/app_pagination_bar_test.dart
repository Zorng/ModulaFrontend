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

  testWidgets('renders numeric pagination on wide layouts', (tester) async {
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
            currentPage: 8,
            totalPages: 20,
            onPrevious: _noop,
            onPageSelected: _noopPage,
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
    expect(find.widgetWithText(FilledButton, '1'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '6'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '7'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '8'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '9'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '10'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '20'), findsOneWidget);
    expect(find.text('...'), findsNWidgets(2));

    final activeButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '8'),
    );
    final inactiveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '7'),
    );
    expect(
      activeButton.style?.backgroundColor?.resolve({}),
      isNot(equals(inactiveButton.style?.backgroundColor?.resolve({}))),
    );
  });

  testWidgets('uses simple previous next mode on narrow layouts', (
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
            currentPage: 8,
            totalPages: 20,
            onPrevious: _noop,
            onPageSelected: _noopPage,
            onNext: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '8'), findsNothing);
    expect(find.text('...'), findsNothing);
  });

  testWidgets('page numbers are clickable and edge buttons disable correctly', (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 800));
    addTearDown(() => _resetViewport(tester));

    var selectedPage = 0;

    await pumpApp(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AppPaginationBar(
            rangeLabel: 'Showing 1-10 entries',
            canGoPrevious: false,
            canGoNext: true,
            isLoading: false,
            currentPage: 1,
            totalPages: 3,
            onPrevious: _noop,
            onPageSelected: (page) => selectedPage = page,
            onNext: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final previousButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Previous'),
    );
    final nextButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Next'),
    );
    expect(previousButton.onPressed, isNull);
    expect(nextButton.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, '3'));
    await tester.pumpAndSettle();
    expect(selectedPage, 3);
  });
}

void _noop() {}
void _noopPage(int _) {}
