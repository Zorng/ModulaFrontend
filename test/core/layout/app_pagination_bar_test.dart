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
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
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

  testWidgets('renders near-start window as 1 2 3 4 5 ... last', (
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
            rangeLabel: 'Showing 1-10 entries',
            canGoPrevious: false,
            canGoNext: true,
            isLoading: false,
            currentPage: 2,
            totalPages: 20,
            onPrevious: _noop,
            onPageSelected: _noopPage,
            onNext: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '1'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '2'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '3'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '4'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '5'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '20'), findsOneWidget);
    expect(find.text('...'), findsOneWidget);
  });

  testWidgets('renders near-end window as first ... last four pages', (
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
            rangeLabel: 'Showing 171-180 entries',
            canGoPrevious: true,
            canGoNext: true,
            isLoading: false,
            currentPage: 18,
            totalPages: 20,
            onPrevious: _noop,
            onPageSelected: _noopPage,
            onNext: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '1'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '17'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '18'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '19'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '20'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '16'), findsNothing);
    expect(find.text('...'), findsOneWidget);
  });

  testWidgets(
    'keeps numeric pagination on narrow layouts when total pages exist',
    (tester) async {
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
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '1'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '8'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '20'), findsOneWidget);
      expect(find.text('...'), findsNWidgets(2));
    },
  );

  testWidgets('falls back to previous next only when total pages are unknown', (
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

    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.text('...'), findsNothing);
    expect(find.widgetWithText(FilledButton, '1'), findsNothing);
  });

  testWidgets('hides pagination when total pages is 1', (tester) async {
    _setViewport(tester, const Size(1280, 800));
    addTearDown(() => _resetViewport(tester));

    await pumpApp(
      tester,
      const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: AppPaginationBar(
            rangeLabel: 'Showing 1-8 entries',
            canGoPrevious: false,
            canGoNext: false,
            isLoading: false,
            currentPage: 1,
            totalPages: 1,
            onPrevious: _noop,
            onPageSelected: _noopPage,
            onNext: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppPaginationBar), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.text('1'), findsNothing);
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
      find.ancestor(
        of: find.byIcon(Icons.chevron_left),
        matching: find.byType(FilledButton),
      ),
    );
    final nextButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right),
        matching: find.byType(FilledButton),
      ),
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
