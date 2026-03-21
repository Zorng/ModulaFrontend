import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/staff/data/staff_shift_cache_store.dart';
import 'package:modular_pos/features/staff/data/repository/staff_shift_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_support_providers.dart';

class StaffShiftState {
  const StaffShiftState({
    required this.branches,
    required this.memberships,
    required this.selectedBranchId,
    required this.selectedMembershipId,
    required this.dateRange,
    required this.schedule,
    required this.pageSize,
    required this.patternOffset,
    required this.patternHasMore,
    required this.instanceOffset,
    required this.instanceHasMore,
    this.isRefreshing = false,
    this.isLoadingPatternMore = false,
    this.isLoadingInstanceMore = false,
    this.isSaving = false,
    this.inlineError,
  });

  final List<BranchListItem> branches;
  final List<StaffMembershipSummary> memberships;
  final String? selectedBranchId;
  final String? selectedMembershipId;
  final DateTimeRange dateRange;
  final StaffShiftSchedule schedule;
  final int pageSize;
  final int patternOffset;
  final bool patternHasMore;
  final int instanceOffset;
  final bool instanceHasMore;
  final bool isRefreshing;
  final bool isLoadingPatternMore;
  final bool isLoadingInstanceMore;
  final bool isSaving;
  final String? inlineError;

  StaffShiftState copyWith({
    List<BranchListItem>? branches,
    List<StaffMembershipSummary>? memberships,
    String? selectedBranchId,
    bool clearSelectedBranchId = false,
    String? selectedMembershipId,
    bool clearSelectedMembershipId = false,
    DateTimeRange? dateRange,
    StaffShiftSchedule? schedule,
    int? pageSize,
    int? patternOffset,
    bool? patternHasMore,
    int? instanceOffset,
    bool? instanceHasMore,
    bool? isRefreshing,
    bool? isLoadingPatternMore,
    bool? isLoadingInstanceMore,
    bool? isSaving,
    String? inlineError,
    bool clearInlineError = false,
  }) {
    return StaffShiftState(
      branches: branches ?? this.branches,
      memberships: memberships ?? this.memberships,
      selectedBranchId: clearSelectedBranchId
          ? null
          : (selectedBranchId ?? this.selectedBranchId),
      selectedMembershipId: clearSelectedMembershipId
          ? null
          : (selectedMembershipId ?? this.selectedMembershipId),
      dateRange: dateRange ?? this.dateRange,
      schedule: schedule ?? this.schedule,
      pageSize: pageSize ?? this.pageSize,
      patternOffset: patternOffset ?? this.patternOffset,
      patternHasMore: patternHasMore ?? this.patternHasMore,
      instanceOffset: instanceOffset ?? this.instanceOffset,
      instanceHasMore: instanceHasMore ?? this.instanceHasMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingPatternMore: isLoadingPatternMore ?? this.isLoadingPatternMore,
      isLoadingInstanceMore:
          isLoadingInstanceMore ?? this.isLoadingInstanceMore,
      isSaving: isSaving ?? this.isSaving,
      inlineError: clearInlineError ? null : inlineError ?? this.inlineError,
    );
  }
}

final staffShiftControllerProvider =
    AsyncNotifierProvider<StaffShiftController, StaffShiftState>(
      StaffShiftController.new,
    );

final staffShiftRequestTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 12),
);

final staffShiftTenantIdProvider = Provider<String>((ref) {
  return (ref.watch(authTenantIdProvider) ??
          ref.watch(loginControllerProvider).session?.activeTenantId ??
          ref.watch(loginControllerProvider).session?.user.tenantId ??
          '')
      .trim();
});

class StaffShiftController extends AsyncNotifier<StaffShiftState> {
  static const _defaultPageSize = 50;

  StaffShiftRepository get _repository =>
      ref.read(staffShiftRepositoryProvider);
  StaffShiftCacheStore get _cache => ref.read(staffShiftCacheStoreProvider);
  Duration get _requestTimeout => ref.read(staffShiftRequestTimeoutProvider);
  String get _tenantId => ref.read(staffShiftTenantIdProvider);

  StaffShiftState? get _currentState {
    final current = state;
    return current is AsyncData<StaffShiftState> ? current.value : null;
  }

  @override
  Future<StaffShiftState> build() async {
    final dateRange = _defaultDateRange();
    final tenantId = _tenantId;
    if (tenantId.isNotEmpty) {
      final cached = await _loadCachedInitialState(
        tenantId: tenantId,
        dateRange: dateRange,
      );
      if (cached != null) {
        unawaited(
          Future<void>.microtask(
            () => _refreshCachedBootstrap(
              tenantId: tenantId,
              expectedBranchId: cached.selectedBranchId,
              expectedMembershipId: cached.selectedMembershipId,
              dateRange: dateRange,
              pageSize: cached.pageSize,
            ),
          ),
        );
        return cached;
      }
    }
    return _loadRemoteInitialState(
      dateRange: dateRange,
      pageSize: _defaultPageSize,
    );
  }

  Future<void> setBranchId(String? value) async {
    final current = _currentState;
    if (current == null) return;
    await _reload(
      selectedBranchId: (value ?? '').trim().isEmpty ? null : value!.trim(),
      selectedMembershipId: current.selectedMembershipId,
      dateRange: current.dateRange,
    );
  }

  Future<void> setMembershipId(String? value) async {
    final current = _currentState;
    if (current == null) return;
    await _reload(
      selectedBranchId: current.selectedBranchId,
      selectedMembershipId: (value ?? '').trim().isEmpty ? null : value!.trim(),
      dateRange: current.dateRange,
    );
  }

  Future<void> setDateRange(DateTimeRange range) async {
    final current = _currentState;
    if (current == null) return;
    await _reload(
      selectedBranchId: current.selectedBranchId,
      selectedMembershipId: current.selectedMembershipId,
      dateRange: range,
    );
  }

  Future<void> clearFilters() async {
    final current = _currentState;
    if (current == null || current.selectedMembershipId == null) return;
    await _reload(
      selectedBranchId: current.selectedBranchId,
      selectedMembershipId: null,
      dateRange: current.dateRange,
    );
  }

  Future<void> setFilters({
    required String? branchId,
    required String? membershipId,
    required DateTimeRange dateRange,
  }) async {
    final current = _currentState;
    if (current == null) return;
    await _reload(
      selectedBranchId: branchId,
      selectedMembershipId: membershipId,
      dateRange: dateRange,
    );
  }

  Future<void> refresh() async {
    final current = _currentState;
    if (current == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(build);
      return;
    }
    await _reload(
      selectedBranchId: current.selectedBranchId,
      selectedMembershipId: current.selectedMembershipId,
      dateRange: current.dateRange,
    );
  }

  Future<void> loadMorePatterns() async {
    final current = _currentState;
    if (current == null ||
        current.isLoadingPatternMore ||
        !current.patternHasMore) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingPatternMore: true, clearInlineError: true),
    );
    try {
      final page = await _loadSchedulePage(
        selectedBranchId: current.selectedBranchId,
        selectedMembershipId: current.selectedMembershipId,
        dateRange: current.dateRange,
        limit: current.pageSize,
        offset: current.patternOffset,
      );
      final fetchedCount = page.patterns.length;
      state = AsyncData(
        current.copyWith(
          schedule: StaffShiftSchedule(
            membershipId: current.schedule.membershipId ?? page.membershipId,
            patternPage: OffsetPage<StaffShiftPattern>(
              items: [...current.schedule.patterns, ...page.patterns],
              limit: current.pageSize,
              offset: page.patternPage.offset,
              total: page.patternPage.total,
              hasMore: page.patternPage.hasMore,
            ),
            instancePage: current.schedule.instancePage,
          ),
          patternOffset: current.patternOffset + fetchedCount,
          patternHasMore: page.patternPage.hasMore,
          isLoadingPatternMore: false,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isLoadingPatternMore: false,
          inlineError: _formatError(error),
        ),
      );
    }
  }

  Future<void> loadMoreInstances() async {
    final current = _currentState;
    if (current == null ||
        current.isLoadingInstanceMore ||
        !current.instanceHasMore) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingInstanceMore: true, clearInlineError: true),
    );
    try {
      final page = await _loadSchedulePage(
        selectedBranchId: current.selectedBranchId,
        selectedMembershipId: current.selectedMembershipId,
        dateRange: current.dateRange,
        limit: current.pageSize,
        offset: current.instanceOffset,
      );
      final fetchedCount = page.instances.length;
      state = AsyncData(
        current.copyWith(
          schedule: StaffShiftSchedule(
            membershipId: current.schedule.membershipId ?? page.membershipId,
            patternPage: current.schedule.patternPage,
            instancePage: OffsetPage<StaffShiftInstance>(
              items: [...current.schedule.instances, ...page.instances],
              limit: current.pageSize,
              offset: page.instancePage.offset,
              total: page.instancePage.total,
              hasMore: page.instancePage.hasMore,
            ),
          ),
          instanceOffset: current.instanceOffset + fetchedCount,
          instanceHasMore: page.instancePage.hasMore,
          isLoadingInstanceMore: false,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isLoadingInstanceMore: false,
          inlineError: _formatError(error),
        ),
      );
    }
  }

  Future<void> createPattern({
    required String membershipId,
    required String branchId,
    required List<int> daysOfWeek,
    required String plannedStartTime,
    required String plannedEndTime,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? note,
  }) async {
    await _runCommand(() {
      return _repository.createPattern(
        membershipId: membershipId,
        branchId: branchId,
        daysOfWeek: daysOfWeek,
        plannedStartTime: plannedStartTime,
        plannedEndTime: plannedEndTime,
        effectiveFrom: effectiveFrom,
        effectiveTo: effectiveTo,
        note: note,
      );
    });
  }

  Future<void> updatePattern({
    required String patternId,
    List<int>? daysOfWeek,
    String? plannedStartTime,
    String? plannedEndTime,
    DateTime? effectiveTo,
    String? note,
  }) async {
    await _runCommand(() {
      return _repository.updatePattern(
        patternId: patternId,
        daysOfWeek: daysOfWeek,
        plannedStartTime: plannedStartTime,
        plannedEndTime: plannedEndTime,
        effectiveTo: effectiveTo,
        note: note,
      );
    });
  }

  Future<void> deactivatePattern({
    required String patternId,
    required String reason,
  }) async {
    await _runCommand(() {
      return _repository.deactivatePattern(
        patternId: patternId,
        reason: reason,
      );
    });
  }

  Future<void> createInstance({
    required String membershipId,
    required String branchId,
    required DateTime date,
    required String plannedStartTime,
    required String plannedEndTime,
    String? note,
  }) async {
    await _runCommand(() {
      return _repository.createInstance(
        membershipId: membershipId,
        branchId: branchId,
        date: date,
        plannedStartTime: plannedStartTime,
        plannedEndTime: plannedEndTime,
        note: note,
      );
    });
  }

  Future<void> updateInstance({
    required String instanceId,
    DateTime? date,
    String? plannedStartTime,
    String? plannedEndTime,
    String? note,
  }) async {
    await _runCommand(() {
      return _repository.updateInstance(
        instanceId: instanceId,
        date: date,
        plannedStartTime: plannedStartTime,
        plannedEndTime: plannedEndTime,
        note: note,
      );
    });
  }

  Future<void> cancelInstance({
    required String instanceId,
    required String reason,
  }) async {
    await _runCommand(() {
      return _repository.cancelInstance(instanceId: instanceId, reason: reason);
    });
  }

  Future<void> _runCommand(Future<Object> Function() action) async {
    final current = _currentState;
    if (current == null) return;
    state = AsyncData(current.copyWith(isSaving: true, clearInlineError: true));
    try {
      await _withTimeout(action());
      final refreshed = await _fetchState(
        branches: current.branches,
        memberships: current.memberships,
        selectedBranchId: current.selectedBranchId,
        selectedMembershipId: current.selectedMembershipId,
        dateRange: current.dateRange,
        pageSize: current.pageSize,
      );
      state = AsyncData(refreshed);
    } catch (error) {
      state = AsyncData(
        current.copyWith(isSaving: false, inlineError: _formatError(error)),
      );
    }
  }

  Future<void> _reload({
    required String? selectedBranchId,
    required String? selectedMembershipId,
    required DateTimeRange dateRange,
  }) async {
    final current = _currentState;
    if (current == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(build);
      return;
    }
    final requestedState = current.copyWith(
      selectedBranchId: selectedBranchId,
      clearSelectedBranchId: selectedBranchId == null,
      selectedMembershipId: selectedMembershipId,
      clearSelectedMembershipId: selectedMembershipId == null,
      dateRange: dateRange,
      schedule: _emptySchedule(current.pageSize),
      isRefreshing: true,
      clearInlineError: true,
    );

    var baseState = requestedState;
    final requestedScope = _resolveCacheScope(
      tenantId: _tenantId,
      selectedBranchId: selectedBranchId,
      selectedMembershipId: selectedMembershipId,
      dateRange: dateRange,
    );
    if (requestedScope != null) {
      final cached = await _cache.read(
        tenantId: requestedScope.tenantId,
        scope: requestedScope,
      );
      if (_sameSelection(
        baseState,
        selectedBranchId: selectedBranchId,
        selectedMembershipId: selectedMembershipId,
        dateRange: dateRange,
      )) {
        baseState = requestedState.copyWith(
          schedule: cached.schedule,
          patternOffset: cached.schedule.patterns.length,
          patternHasMore: cached.schedule.patternPage.hasMore,
          instanceOffset: cached.schedule.instances.length,
          instanceHasMore: cached.schedule.instancePage.hasMore,
        );
      }
    }
    state = AsyncData(baseState);
    try {
      final next = await _fetchState(
        branches: current.branches,
        memberships: current.memberships,
        selectedBranchId: selectedBranchId,
        selectedMembershipId: selectedMembershipId,
        dateRange: dateRange,
        pageSize: current.pageSize,
      );
      state = AsyncData(next);
    } catch (error) {
      state = AsyncData(
        baseState.copyWith(
          isRefreshing: false,
          inlineError: _formatError(error),
        ),
      );
    }
  }

  Future<StaffShiftState> _fetchState({
    required List<BranchListItem> branches,
    required List<StaffMembershipSummary> memberships,
    required String? selectedBranchId,
    required String? selectedMembershipId,
    required DateTimeRange dateRange,
    required int pageSize,
  }) async {
    final schedule = await _loadSchedulePage(
      selectedBranchId: selectedBranchId,
      selectedMembershipId: selectedMembershipId,
      dateRange: dateRange,
      limit: pageSize,
      offset: 0,
    );
    final scope = _resolveCacheScope(
      tenantId: _tenantId,
      selectedBranchId: selectedBranchId,
      selectedMembershipId: selectedMembershipId,
      dateRange: dateRange,
    );
    if (scope != null) {
      await _cache.writeSchedule(scope: scope, schedule: schedule);
    }
    if (_tenantId.isNotEmpty) {
      await _cache.writeOptions(
        tenantId: _tenantId,
        branches: branches,
        memberships: memberships,
      );
    }
    return StaffShiftState(
      branches: branches,
      memberships: memberships,
      selectedBranchId: selectedBranchId,
      selectedMembershipId: selectedMembershipId,
      dateRange: dateRange,
      schedule: schedule,
      pageSize: pageSize,
      patternOffset: schedule.patterns.length,
      patternHasMore: schedule.patternPage.hasMore,
      instanceOffset: schedule.instances.length,
      instanceHasMore: schedule.instancePage.hasMore,
    );
  }

  Future<StaffShiftSchedule> _loadSchedulePage({
    required String? selectedBranchId,
    required String? selectedMembershipId,
    required DateTimeRange dateRange,
    required int limit,
    required int offset,
  }) async {
    final branchId = (selectedBranchId ?? '').trim();
    final membershipId = (selectedMembershipId ?? '').trim();
    if (branchId.isEmpty && membershipId.isEmpty) {
      return _emptySchedule(limit);
    }
    return _withTimeout(
      _repository.fetchSchedule(
        branchId: branchId,
        from: _formatDate(dateRange.start),
        to: _formatDate(dateRange.end),
        membershipId: membershipId.isEmpty ? null : membershipId,
        limit: limit,
        offset: offset,
      ),
    );
  }

  StaffShiftSchedule _emptySchedule(int limit) {
    return StaffShiftSchedule(
      patternPage: OffsetPage.empty<StaffShiftPattern>(limit: limit),
      instancePage: OffsetPage.empty<StaffShiftInstance>(limit: limit),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    return localDate.toIso8601String().split('T').first;
  }

  DateTimeRange _defaultDateRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: start, end: start.add(const Duration(days: 6)));
  }

  Future<StaffShiftState?> _loadCachedInitialState({
    required String tenantId,
    required DateTimeRange dateRange,
  }) async {
    final bootstrap = await _cache.read(tenantId: tenantId);
    if (!bootstrap.hasAnyData) {
      return null;
    }

    final selectedBranchId = bootstrap.branches.isNotEmpty
        ? bootstrap.branches.first.branchId
        : null;
    if ((selectedBranchId ?? '').trim().isEmpty) {
      return StaffShiftState(
        branches: bootstrap.branches,
        memberships: bootstrap.memberships,
        selectedBranchId: null,
        selectedMembershipId: null,
        dateRange: dateRange,
        schedule: _emptySchedule(_defaultPageSize),
        pageSize: _defaultPageSize,
        patternOffset: 0,
        patternHasMore: false,
        instanceOffset: 0,
        instanceHasMore: false,
      );
    }

    final scoped = await _cache.read(
      tenantId: tenantId,
      scope: StaffShiftCacheScope(
        tenantId: tenantId,
        branchId: selectedBranchId!.trim(),
        fromDate: _formatDate(dateRange.start),
        toDate: _formatDate(dateRange.end),
      ),
    );
    final resolvedPageSize = scoped.schedule.patternPage.limit > 0
        ? scoped.schedule.patternPage.limit
        : (scoped.schedule.instancePage.limit > 0
              ? scoped.schedule.instancePage.limit
              : _defaultPageSize);
    return StaffShiftState(
      branches: bootstrap.branches,
      memberships: bootstrap.memberships,
      selectedBranchId: selectedBranchId,
      selectedMembershipId: null,
      dateRange: dateRange,
      schedule: scoped.schedule,
      pageSize: resolvedPageSize,
      patternOffset: scoped.schedule.patterns.length,
      patternHasMore: scoped.schedule.patternPage.hasMore,
      instanceOffset: scoped.schedule.instances.length,
      instanceHasMore: scoped.schedule.instancePage.hasMore,
    );
  }

  Future<StaffShiftState> _loadRemoteInitialState({
    required DateTimeRange dateRange,
    required int pageSize,
  }) async {
    final (branches, memberships) = await _loadRemoteOptions();
    final selectedBranchId = branches.isNotEmpty
        ? branches.first.branchId
        : null;
    return _fetchState(
      branches: branches,
      memberships: memberships,
      selectedBranchId: selectedBranchId,
      selectedMembershipId: null,
      dateRange: dateRange,
      pageSize: pageSize,
    );
  }

  Future<void> _refreshCachedBootstrap({
    required String tenantId,
    required String? expectedBranchId,
    required String? expectedMembershipId,
    required DateTimeRange dateRange,
    required int pageSize,
  }) async {
    try {
      final next = await _loadRemoteInitialState(
        dateRange: dateRange,
        pageSize: pageSize,
      );
      if (_sameSelection(
        next,
        selectedBranchId: expectedBranchId,
        selectedMembershipId: expectedMembershipId,
        dateRange: dateRange,
      )) {
        state = AsyncData(next);
      }
    } catch (error) {
      final current = _currentState;
      if (current == null) return;
      if (_tenantId != tenantId) return;
      if (!_sameSelection(
        current,
        selectedBranchId: expectedBranchId,
        selectedMembershipId: expectedMembershipId,
        dateRange: dateRange,
      )) {
        return;
      }
      state = AsyncData(
        current.copyWith(isRefreshing: false, inlineError: _formatError(error)),
      );
    }
  }

  Future<(List<BranchListItem>, List<StaffMembershipSummary>)>
  _loadRemoteOptions() async {
    final branches = await _withTimeout(
      ref.read(staffTenantBranchesProvider.future),
    );
    final memberships = await _withTimeout(
      ref.read(staffMembershipOptionsProvider.future),
    );
    return (branches, memberships);
  }

  StaffShiftCacheScope? _resolveCacheScope({
    required String tenantId,
    required String? selectedBranchId,
    required String? selectedMembershipId,
    required DateTimeRange dateRange,
  }) {
    final normalizedTenantId = tenantId.trim();
    final normalizedBranchId = (selectedBranchId ?? '').trim();
    if (normalizedTenantId.isEmpty || normalizedBranchId.isEmpty) return null;
    final normalizedMembershipId = (selectedMembershipId ?? '').trim();
    return StaffShiftCacheScope(
      tenantId: normalizedTenantId,
      branchId: normalizedBranchId,
      membershipId: normalizedMembershipId.isEmpty
          ? null
          : normalizedMembershipId,
      fromDate: _formatDate(dateRange.start),
      toDate: _formatDate(dateRange.end),
    );
  }

  bool _sameSelection(
    StaffShiftState state, {
    required String? selectedBranchId,
    required String? selectedMembershipId,
    required DateTimeRange dateRange,
  }) {
    return (state.selectedBranchId ?? '') == (selectedBranchId ?? '') &&
        (state.selectedMembershipId ?? '') == (selectedMembershipId ?? '') &&
        state.dateRange.start == dateRange.start &&
        state.dateRange.end == dateRange.end;
  }

  Future<T> _withTimeout<T>(Future<T> future) {
    return future.timeout(_requestTimeout);
  }

  String _formatError(Object error) {
    if (error is TimeoutException) {
      return 'Shift request timed out. Check your connection and try again.';
    }
    if (error is ApiClientException) {
      return error.message;
    }
    return error.toString();
  }
}
