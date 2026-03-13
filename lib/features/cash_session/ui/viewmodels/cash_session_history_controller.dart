import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_history_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_history_entry.dart';

class CashSessionHistoryState {
  const CashSessionHistoryState({
    required this.date,
    required this.isDateFilterApplied,
    required this.sessions,
    required this.offset,
    required this.pageSize,
    required this.hasMoreSessions,
  });

  final DateTime date;
  final bool isDateFilterApplied;
  final AsyncValue<List<CashSessionHistoryEntry>> sessions;
  final int offset;
  final int pageSize;
  final bool hasMoreSessions;
  int get sessionCount => sessions.asData?.value.length ?? 0;
  bool get canGoToPreviousPage => offset > 0;
  bool get canGoToNextPage => hasMoreSessions;

  CashSessionHistoryState copyWith({
    DateTime? date,
    bool? isDateFilterApplied,
    AsyncValue<List<CashSessionHistoryEntry>>? sessions,
    int? offset,
    int? pageSize,
    bool? hasMoreSessions,
  }) {
    return CashSessionHistoryState(
      date: date ?? this.date,
      isDateFilterApplied: isDateFilterApplied ?? this.isDateFilterApplied,
      sessions: sessions ?? this.sessions,
      offset: offset ?? this.offset,
      pageSize: pageSize ?? this.pageSize,
      hasMoreSessions: hasMoreSessions ?? this.hasMoreSessions,
    );
  }
}

class CashSessionHistoryController extends Notifier<CashSessionHistoryState> {
  CashSessionHistoryRepository get _repo =>
      ref.read(cashSessionHistoryRepositoryProvider);

  @override
  CashSessionHistoryState build() {
    ref.watch(authActiveBranchIdProvider);
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    return CashSessionHistoryState(
      date: date,
      isDateFilterApplied: false,
      sessions: const AsyncData(<CashSessionHistoryEntry>[]),
      offset: 0,
      pageSize: 20,
      hasMoreSessions: false,
    );
  }

  Future<void> load() async {
    final branchId = ref.read(authActiveBranchIdProvider);
    if (branchId == null || branchId.isEmpty) {
      state = state.copyWith(
        sessions: const AsyncError<List<CashSessionHistoryEntry>>(
          'Select a branch to load session history.',
          StackTrace.empty,
        ),
        hasMoreSessions: false,
      );
      return;
    }

    state = state.copyWith(
      sessions: const AsyncLoading<List<CashSessionHistoryEntry>>(),
    );

    try {
      final range = state.isDateFilterApplied
          ? _buildDayRange(state.date)
          : null;
      final sessions = await _repo.listClosedSessions(
        from: range?.$1,
        to: range?.$2,
        limit: state.pageSize,
        offset: state.offset,
      );
      state = state.copyWith(
        sessions: AsyncData<List<CashSessionHistoryEntry>>(sessions),
        hasMoreSessions: sessions.length == state.pageSize,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        sessions: AsyncError<List<CashSessionHistoryEntry>>(error, stackTrace),
        hasMoreSessions: false,
      );
    }
  }

  Future<void> refresh() => load();

  Future<void> setDate(DateTime date) async {
    await setDateFilter(date);
  }

  Future<void> setDateFilter(DateTime date) async {
    state = state.copyWith(
      date: DateTime(date.year, date.month, date.day),
      isDateFilterApplied: true,
      offset: 0,
    );
    await load();
  }

  Future<void> clearDateFilter() async {
    state = state.copyWith(isDateFilterApplied: false, offset: 0);
    await load();
  }

  Future<void> nextPage() async {
    if (!state.canGoToNextPage) return;
    state = state.copyWith(offset: state.offset + state.pageSize);
    await load();
  }

  Future<void> previousPage() async {
    if (!state.canGoToPreviousPage) return;
    final nextOffset = state.offset - state.pageSize;
    state = state.copyWith(offset: nextOffset < 0 ? 0 : nextOffset);
    await load();
  }

  (DateTime, DateTime) _buildDayRange(DateTime date) {
    final startLocal = DateTime(date.year, date.month, date.day);
    final endLocal = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return (startLocal.toUtc(), endLocal.toUtc());
  }
}

final cashSessionHistoryControllerProvider =
    NotifierProvider<CashSessionHistoryController, CashSessionHistoryState>(
      CashSessionHistoryController.new,
    );
