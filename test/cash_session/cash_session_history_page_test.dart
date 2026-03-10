import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_history_entry.dart';
import 'package:modular_pos/features/cash_session/ui/view/cash_history/cash_session_history_page.dart';
import 'package:modular_pos/features/cash_session/ui/view/cash_history/cash_session_history_detail_page.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_history_controller.dart';
import 'package:modular_pos/features/reporting/data/reporting_api.dart';
import 'package:modular_pos/features/reporting/data/reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/z_report.dart';

class _HistoryControllerStub extends CashSessionHistoryController {
  _HistoryControllerStub(this._state);

  final CashSessionHistoryState _state;

  @override
  CashSessionHistoryState build() => _state;

  @override
  Future<void> load() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> setDate(DateTime date) async {}

  @override
  Future<void> setDateFilter(DateTime date) async {}

  @override
  Future<void> clearDateFilter() async {}

  @override
  Future<void> nextPage() async {}

  @override
  Future<void> previousPage() async {}
}

class _FakeReportingRepository extends ReportingRepository {
  _FakeReportingRepository() : super(_StubReportingApi());

  @override
  Future<ZReportDetail> fetchZReportDetail({required String sessionId}) async {
    return ZReportDetail(
      sessionId: sessionId,
      status: 'CLOSED',
      openedByName: 'John Smith',
      openedAt: DateTime(2026, 3, 10, 8),
      closedAt: DateTime(2026, 3, 10, 16),
      openingFloatUsd: 20,
      openingFloatKhr: 50000,
      totalSalesKhqrUsd: 7.5,
      totalSalesKhqrKhr: 0,
      totalSalesCashUsd: 15,
      totalSalesCashKhr: 0,
      totalPaidInUsd: 5,
      totalPaidInKhr: 0,
      totalPaidOutUsd: 2,
      totalPaidOutKhr: 0,
      expectedCashUsd: 37,
      expectedCashKhr: 50000,
      countedCashUsd: 37,
      countedCashKhr: 50000,
      varianceUsd: 0,
      varianceKhr: 0,
      closedByName: 'Jane Doe',
      closeReason: 'NORMAL_CLOSE',
    );
  }
}

class _StubReportingApi extends ReportingApi {
  _StubReportingApi() : super(Dio());
}

void _setWideViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 800);
}

void _setMobileViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 844);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Future<void> _pumpHistoryPage(
  WidgetTester tester, {
  required CashSessionHistoryState historyState,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const CashSessionHistoryPage()),
      GoRoute(
        path: AppRoute.cashHistoryDetail.path,
        name: AppRoute.cashHistoryDetail.name,
        builder: (_, state) => CashSessionHistoryDetailPage(
          sessionId: state.pathParameters['sessionId'] ?? '',
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cashSessionHistoryControllerProvider.overrideWith(
          () => _HistoryControllerStub(historyState),
        ),
        reportingRepositoryProvider.overrideWithValue(
          _FakeReportingRepository(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('wide history shows full-width table and opens detail dialog', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await _pumpHistoryPage(
      tester,
      historyState: CashSessionHistoryState(
        date: DateTime(2026, 3, 10),
        isDateFilterApplied: false,
        sessions: AsyncValue.data([
          CashSessionHistoryEntry(
            id: 'session-1',
            status: 'CLOSED',
            openedByName: 'John Smith',
            openedAt: DateTime(2026, 3, 10, 8),
            closedAt: DateTime(2026, 3, 10, 16),
          ),
        ]),
        offset: 0,
        pageSize: 20,
        hasMoreSessions: false,
      ),
    );

    expect(find.text('Closed Sessions'), findsOneWidget);
    expect(find.text('Filter by date'), findsOneWidget);
    expect(find.text('Any date'), findsOneWidget);
    expect(find.text('John Smith'), findsOneWidget);
    expect(find.text('1 sessions'), findsOneWidget);

    await tester.tap(find.text('John Smith'));
    await tester.pumpAndSettle();

    expect(find.text('Closed Session Summary'), findsOneWidget);
    expect(find.text('Selected session: session-1'), findsOneWidget);
    expect(find.text('Counted Cash'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('mobile history pushes a full-page detail screen', (
    tester,
  ) async {
    _setMobileViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await _pumpHistoryPage(
      tester,
      historyState: CashSessionHistoryState(
        date: DateTime(2026, 3, 10),
        isDateFilterApplied: false,
        sessions: AsyncValue.data([
          CashSessionHistoryEntry(
            id: 'session-1',
            status: 'CLOSED',
            openedByName: 'John Smith',
            openedAt: DateTime(2026, 3, 10, 8),
            closedAt: DateTime(2026, 3, 10, 16),
          ),
        ]),
        offset: 0,
        pageSize: 20,
        hasMoreSessions: false,
      ),
    );

    expect(find.text('1 sessions'), findsOneWidget);
    expect(find.text('Filter by date'), findsOneWidget);
    expect(find.text('Any date'), findsOneWidget);
    expect(find.text('Opened by'), findsOneWidget);
    expect(find.text('John Smith'), findsOneWidget);

    await tester.tap(find.text('John Smith'));
    await tester.pumpAndSettle();

    expect(find.text('Closed Session Summary'), findsOneWidget);
    expect(find.text('Selected session: session-1'), findsOneWidget);
    expect(find.text('Counted Cash'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}
