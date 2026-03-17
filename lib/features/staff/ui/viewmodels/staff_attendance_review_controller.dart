import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/staff/data/repository/staff_attendance_review_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_attendance_review_models.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_support_providers.dart';

class StaffAttendanceReviewState {
  const StaffAttendanceReviewState({
    required this.records,
    required this.branches,
    required this.accounts,
    required this.selectedBranchId,
    required this.selectedAccountId,
    required this.selectedDateRange,
    required this.limit,
    required this.offset,
    required this.canLoadMore,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.inlineError,
  });

  final List<StaffAttendanceReviewRecord> records;
  final List<BranchListItem> branches;
  final List<StaffMembershipSummary> accounts;
  final String? selectedBranchId;
  final String? selectedAccountId;
  final DateTimeRange selectedDateRange;
  final int limit;
  final int offset;
  final bool canLoadMore;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? inlineError;

  StaffAttendanceReviewState copyWith({
    List<StaffAttendanceReviewRecord>? records,
    List<BranchListItem>? branches,
    List<StaffMembershipSummary>? accounts,
    String? selectedBranchId,
    bool clearSelectedBranchId = false,
    String? selectedAccountId,
    bool clearSelectedAccountId = false,
    DateTimeRange? selectedDateRange,
    int? limit,
    int? offset,
    bool? canLoadMore,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? inlineError,
    bool clearInlineError = false,
  }) {
    return StaffAttendanceReviewState(
      records: records ?? this.records,
      branches: branches ?? this.branches,
      accounts: accounts ?? this.accounts,
      selectedBranchId: clearSelectedBranchId
          ? null
          : (selectedBranchId ?? this.selectedBranchId),
      selectedAccountId: clearSelectedAccountId
          ? null
          : (selectedAccountId ?? this.selectedAccountId),
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      canLoadMore: canLoadMore ?? this.canLoadMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      inlineError: clearInlineError ? null : inlineError ?? this.inlineError,
    );
  }
}

final staffAttendanceReviewControllerProvider =
    AsyncNotifierProvider<
      StaffAttendanceReviewController,
      StaffAttendanceReviewState
    >(StaffAttendanceReviewController.new);

class StaffAttendanceReviewController
    extends AsyncNotifier<StaffAttendanceReviewState> {
  static const _defaultLimit = 50;

  StaffAttendanceReviewRepository get _repository =>
      ref.read(staffAttendanceReviewRepositoryProvider);

  StaffAttendanceReviewState? get _currentState {
    final current = state;
    return current is AsyncData<StaffAttendanceReviewState>
        ? current.value
        : null;
  }

  @override
  Future<StaffAttendanceReviewState> build() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _load(
      selectedBranchId: null,
      selectedAccountId: null,
      dateRange: DateTimeRange(start: start, end: end),
      limit: _defaultLimit,
      offset: 0,
    );
  }

  Future<void> setBranchId(String? value) async {
    final current = _currentState;
    if (current == null) return;
    await _reload(
      selectedBranchId: (value ?? '').trim().isEmpty ? null : value!.trim(),
      selectedAccountId: current.selectedAccountId,
      dateRange: current.selectedDateRange,
    );
  }

  Future<void> setAccountId(String? value) async {
    final current = _currentState;
    if (current == null) return;
    await _reload(
      selectedBranchId: current.selectedBranchId,
      selectedAccountId: (value ?? '').trim().isEmpty ? null : value!.trim(),
      dateRange: current.selectedDateRange,
    );
  }

  Future<void> setDateRange(DateTimeRange range) async {
    final current = _currentState;
    if (current == null) return;
    await _reload(
      selectedBranchId: current.selectedBranchId,
      selectedAccountId: current.selectedAccountId,
      dateRange: range,
    );
  }

  Future<void> setFilters({
    required String? branchId,
    required String? accountId,
    required DateTimeRange dateRange,
  }) async {
    await _reload(
      selectedBranchId: branchId,
      selectedAccountId: accountId,
      dateRange: dateRange,
    );
  }

  Future<void> clearFilters() async {
    final current = _currentState;
    if (current == null) return;
    if (current.selectedBranchId == null && current.selectedAccountId == null) {
      return;
    }
    await _reload(
      selectedBranchId: null,
      selectedAccountId: null,
      dateRange: current.selectedDateRange,
    );
  }

  Future<void> refresh() async {
    final current = _currentState;
    if (current == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(build);
      return;
    }
    state = AsyncData(
      current.copyWith(isRefreshing: true, clearInlineError: true),
    );
    try {
      final next = await _load(
        selectedBranchId: current.selectedBranchId,
        selectedAccountId: current.selectedAccountId,
        dateRange: current.selectedDateRange,
        limit: current.limit,
        offset: 0,
      );
      state = AsyncData(next);
    } catch (error) {
      state = AsyncData(
        current.copyWith(isRefreshing: false, inlineError: error.toString()),
      );
    }
  }

  Future<void> loadMore() async {
    final current = _currentState;
    if (current == null || current.isLoadingMore || !current.canLoadMore) {
      return;
    }
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearInlineError: true),
    );
    try {
      final range = _toUtcRange(current.selectedDateRange);
      final nextOffset = current.offset + current.records.length;
      final more = await _repository.fetchTenantAttendance(
        branchId: current.selectedBranchId,
        accountId: current.selectedAccountId,
        occurredFrom: range.$1,
        occurredTo: range.$2,
        limit: current.limit,
        offset: nextOffset,
      );
      state = AsyncData(
        current.copyWith(
          records: [...current.records, ...more],
          offset: nextOffset,
          canLoadMore: more.length >= current.limit,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, inlineError: error.toString()),
      );
    }
  }

  Future<void> _reload({
    required String? selectedBranchId,
    required String? selectedAccountId,
    required DateTimeRange dateRange,
  }) async {
    final current = _currentState;
    if (current == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(
        () => _load(
          selectedBranchId: selectedBranchId,
          selectedAccountId: selectedAccountId,
          dateRange: dateRange,
          limit: _defaultLimit,
          offset: 0,
        ),
      );
      return;
    }
    state = AsyncData(
      current.copyWith(isRefreshing: true, clearInlineError: true),
    );
    try {
      final next = await _load(
        selectedBranchId: selectedBranchId,
        selectedAccountId: selectedAccountId,
        dateRange: dateRange,
        limit: current.limit,
        offset: 0,
      );
      state = AsyncData(next);
    } catch (error) {
      state = AsyncData(
        current.copyWith(isRefreshing: false, inlineError: error.toString()),
      );
    }
  }

  Future<StaffAttendanceReviewState> _load({
    required String? selectedBranchId,
    required String? selectedAccountId,
    required DateTimeRange dateRange,
    required int limit,
    required int offset,
  }) async {
    final branches = await ref.read(staffTenantBranchesProvider.future);
    final accounts = await ref.read(staffMembershipOptionsProvider.future);
    final range = _toUtcRange(dateRange);
    final records = await _repository.fetchTenantAttendance(
      branchId: selectedBranchId,
      accountId: selectedAccountId,
      occurredFrom: range.$1,
      occurredTo: range.$2,
      limit: limit,
      offset: offset,
    );
    return StaffAttendanceReviewState(
      records: records,
      branches: branches,
      accounts: accounts,
      selectedBranchId: selectedBranchId,
      selectedAccountId: selectedAccountId,
      selectedDateRange: dateRange,
      limit: limit,
      offset: offset,
      canLoadMore: records.length >= limit,
    );
  }

  (String, String) _toUtcRange(DateTimeRange range) {
    final from = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
      0,
      0,
      0,
    );
    final to = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );
    return (from.toUtc().toIso8601String(), to.toUtc().toIso8601String());
  }
}
