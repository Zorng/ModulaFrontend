import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
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
    this.isRefreshing = false,
    this.isSaving = false,
    this.inlineError,
  });

  final List<BranchListItem> branches;
  final List<StaffMembershipSummary> memberships;
  final String? selectedBranchId;
  final String? selectedMembershipId;
  final DateTimeRange dateRange;
  final StaffShiftSchedule schedule;
  final bool isRefreshing;
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
    bool? isRefreshing,
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
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSaving: isSaving ?? this.isSaving,
      inlineError: clearInlineError ? null : inlineError ?? this.inlineError,
    );
  }
}

final staffShiftControllerProvider =
    AsyncNotifierProvider<StaffShiftController, StaffShiftState>(
      StaffShiftController.new,
    );

class StaffShiftController extends AsyncNotifier<StaffShiftState> {
  StaffShiftRepository get _repository =>
      ref.read(staffShiftRepositoryProvider);

  StaffShiftState? get _currentState {
    final current = state;
    return current is AsyncData<StaffShiftState> ? current.value : null;
  }

  @override
  Future<StaffShiftState> build() async {
    final branches = await ref.read(staffTenantBranchesProvider.future);
    final memberships = await ref.read(staffMembershipOptionsProvider.future);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 6));
    final selectedBranchId = branches.isNotEmpty
        ? branches.first.branchId
        : null;
    final schedule = selectedBranchId == null
        ? const StaffShiftSchedule(patterns: [], instances: [])
        : await _repository.fetchSchedule(
            branchId: selectedBranchId,
            from: _formatDate(start),
            to: _formatDate(end),
          );

    return StaffShiftState(
      branches: branches,
      memberships: memberships,
      selectedBranchId: selectedBranchId,
      selectedMembershipId: null,
      dateRange: DateTimeRange(start: start, end: end),
      schedule: schedule,
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
      await action();
      final refreshed = await _fetchState(
        branches: current.branches,
        memberships: current.memberships,
        selectedBranchId: current.selectedBranchId,
        selectedMembershipId: current.selectedMembershipId,
        dateRange: current.dateRange,
      );
      state = AsyncData(refreshed);
    } catch (error) {
      state = AsyncData(
        current.copyWith(isSaving: false, inlineError: error.toString()),
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
    state = AsyncData(
      current.copyWith(isRefreshing: true, clearInlineError: true),
    );
    try {
      final next = await _fetchState(
        branches: current.branches,
        memberships: current.memberships,
        selectedBranchId: selectedBranchId,
        selectedMembershipId: selectedMembershipId,
        dateRange: dateRange,
      );
      state = AsyncData(next);
    } catch (error) {
      state = AsyncData(
        current.copyWith(isRefreshing: false, inlineError: error.toString()),
      );
    }
  }

  Future<StaffShiftState> _fetchState({
    required List<BranchListItem> branches,
    required List<StaffMembershipSummary> memberships,
    required String? selectedBranchId,
    required String? selectedMembershipId,
    required DateTimeRange dateRange,
  }) async {
    StaffShiftSchedule schedule = const StaffShiftSchedule(
      patterns: [],
      instances: [],
    );
    if ((selectedBranchId ?? '').trim().isNotEmpty) {
      schedule = await _repository.fetchSchedule(
        branchId: selectedBranchId!.trim(),
        from: _formatDate(dateRange.start),
        to: _formatDate(dateRange.end),
        membershipId: selectedMembershipId,
      );
    }
    return StaffShiftState(
      branches: branches,
      memberships: memberships,
      selectedBranchId: selectedBranchId,
      selectedMembershipId: selectedMembershipId,
      dateRange: dateRange,
      schedule: schedule,
    );
  }

  String _formatDate(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    return localDate.toIso8601String().split('T').first;
  }
}
