import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_history_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_history_entry.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_history_controller.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';

import '../test_utils/riverpod_test_utils.dart';

class _MockCashSessionHistoryRepository extends Mock
    implements CashSessionHistoryRepository {}

void main() {
  CashSessionHistoryEntry buildEntry({
    required String id,
    required String status,
    required int closedHour,
  }) {
    return CashSessionHistoryEntry(
      id: id,
      status: status,
      openedByName: 'John Smith',
      openedAt: DateTime.utc(2026, 3, 10, 1),
      closedAt: DateTime.utc(2026, 3, 10, closedHour),
    );
  }

  test(
    'load fetches recent closed sessions when no date filter is applied',
    () async {
      final repo = _MockCashSessionHistoryRepository();
      when(
        () => repo.listClosedSessions(
          from: any(named: 'from'),
          to: any(named: 'to'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) async => [
          buildEntry(id: 'session-2', status: 'FORCE_CLOSED', closedHour: 10),
          buildEntry(id: 'session-1', status: 'CLOSED', closedHour: 9),
        ],
      );

      final container = createTestContainer(
        overrides: [
          cashSessionHistoryRepositoryProvider.overrideWithValue(repo),
          authActiveBranchIdProvider.overrideWithValue('branch-1'),
        ],
      );

      final notifier = container.read(
        cashSessionHistoryControllerProvider.notifier,
      );
      await notifier.load();

      final state = container.read(cashSessionHistoryControllerProvider);
      expect(state.sessionCount, 2);
      expect(state.isDateFilterApplied, isFalse);
      expect(state.offset, 0);
      expect(state.pageSize, 20);
      expect(state.sessions, isA<AsyncData<List<CashSessionHistoryEntry>>>());
      expect(state.sessions.requireValue.first.id, 'session-2');
      verify(
        () =>
            repo.listClosedSessions(from: null, to: null, limit: 20, offset: 0),
      ).called(1);
    },
  );

  test('setDateFilter applies filter and reloads history', () async {
    final repo = _MockCashSessionHistoryRepository();
    when(
      () => repo.listClosedSessions(
        from: any(named: 'from'),
        to: any(named: 'to'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => [
        buildEntry(id: 'session-1', status: 'CLOSED', closedHour: 9),
      ],
    );

    final container = createTestContainer(
      overrides: [
        cashSessionHistoryRepositoryProvider.overrideWithValue(repo),
        authActiveBranchIdProvider.overrideWithValue('branch-1'),
      ],
    );

    final notifier = container.read(
      cashSessionHistoryControllerProvider.notifier,
    );
    await notifier.load();
    await notifier.setDateFilter(DateTime.utc(2026, 3, 11));

    final state = container.read(cashSessionHistoryControllerProvider);
    expect(state.isDateFilterApplied, isTrue);
    verify(
      () => repo.listClosedSessions(
        from: any(named: 'from'),
        to: any(named: 'to'),
        limit: 20,
        offset: 0,
      ),
    ).called(2);
  });

  test('clearDateFilter resets back to recent-first history', () async {
    final repo = _MockCashSessionHistoryRepository();
    when(
      () => repo.listClosedSessions(
        from: any(named: 'from'),
        to: any(named: 'to'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => [
        buildEntry(id: 'session-1', status: 'CLOSED', closedHour: 9),
      ],
    );

    final container = createTestContainer(
      overrides: [
        cashSessionHistoryRepositoryProvider.overrideWithValue(repo),
        authActiveBranchIdProvider.overrideWithValue('branch-1'),
      ],
    );

    final notifier = container.read(
      cashSessionHistoryControllerProvider.notifier,
    );
    await notifier.setDateFilter(DateTime.utc(2026, 3, 11));
    await notifier.clearDateFilter();

    final state = container.read(cashSessionHistoryControllerProvider);
    expect(state.isDateFilterApplied, isFalse);
    verify(
      () => repo.listClosedSessions(from: null, to: null, limit: 20, offset: 0),
    ).called(1);
  });

  test('nextPage and previousPage update offset and reload history', () async {
    final repo = _MockCashSessionHistoryRepository();
    when(
      () => repo.listClosedSessions(
        from: any(named: 'from'),
        to: any(named: 'to'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((invocation) async {
      final offset = invocation.namedArguments[#offset] as int;
      if (offset == 0) {
        return List.generate(
          20,
          (index) => buildEntry(
            id: 'session-$index',
            status: 'CLOSED',
            closedHour: 10,
          ),
        );
      }
      return [buildEntry(id: 'session-next', status: 'CLOSED', closedHour: 8)];
    });

    final container = createTestContainer(
      overrides: [
        cashSessionHistoryRepositoryProvider.overrideWithValue(repo),
        authActiveBranchIdProvider.overrideWithValue('branch-1'),
      ],
    );

    final notifier = container.read(
      cashSessionHistoryControllerProvider.notifier,
    );
    await notifier.load();
    await notifier.nextPage();

    var state = container.read(cashSessionHistoryControllerProvider);
    expect(state.offset, 20);

    await notifier.previousPage();
    state = container.read(cashSessionHistoryControllerProvider);
    expect(state.offset, 0);

    verify(
      () =>
          repo.listClosedSessions(from: null, to: null, limit: 20, offset: 20),
    ).called(1);
  });

  test(
    'load shows branch-required error without active branch context',
    () async {
      final repo = _MockCashSessionHistoryRepository();
      final container = createTestContainer(
        overrides: [
          cashSessionHistoryRepositoryProvider.overrideWithValue(repo),
          authActiveBranchIdProvider.overrideWithValue(null),
        ],
      );

      final notifier = container.read(
        cashSessionHistoryControllerProvider.notifier,
      );
      await notifier.load();

      final state = container.read(cashSessionHistoryControllerProvider);
      expect(state.sessions, isA<AsyncError<List<CashSessionHistoryEntry>>>());
      final errorState =
          state.sessions as AsyncError<List<CashSessionHistoryEntry>>;
      expect(errorState.error, 'Select a branch to load session history.');
      verifyNever(
        () => repo.listClosedSessions(
          from: any(named: 'from'),
          to: any(named: 'to'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      );
    },
  );
}
