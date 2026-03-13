import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/data/repository/staff_membership_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_support_providers.dart';

enum StaffListStatusFilter { all, active, invited, revoked }

String _statusFilterToApiValue(StaffListStatusFilter value) {
  switch (value) {
    case StaffListStatusFilter.all:
      return 'ALL';
    case StaffListStatusFilter.active:
      return 'ACTIVE';
    case StaffListStatusFilter.invited:
      return 'INVITED';
    case StaffListStatusFilter.revoked:
      return 'REVOKED';
  }
}

class StaffMembershipListState {
  const StaffMembershipListState({
    required this.memberships,
    required this.searchQuery,
    required this.statusFilter,
    required this.limit,
    required this.offset,
    required this.canLoadMore,
    required this.branchNameById,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.inlineError,
  });

  final List<StaffMembershipSummary> memberships;
  final String searchQuery;
  final StaffListStatusFilter statusFilter;
  final int limit;
  final int offset;
  final bool canLoadMore;
  final Map<String, String> branchNameById;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? inlineError;

  StaffMembershipListState copyWith({
    List<StaffMembershipSummary>? memberships,
    String? searchQuery,
    StaffListStatusFilter? statusFilter,
    int? limit,
    int? offset,
    bool? canLoadMore,
    Map<String, String>? branchNameById,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? inlineError,
    bool clearInlineError = false,
  }) {
    return StaffMembershipListState(
      memberships: memberships ?? this.memberships,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      canLoadMore: canLoadMore ?? this.canLoadMore,
      branchNameById: branchNameById ?? this.branchNameById,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      inlineError: clearInlineError ? null : inlineError ?? this.inlineError,
    );
  }
}

final staffMembershipListControllerProvider = AsyncNotifierProvider<
  StaffMembershipListController,
  StaffMembershipListState
>(StaffMembershipListController.new);

class StaffMembershipListController
    extends AsyncNotifier<StaffMembershipListState> {
  static const _defaultLimit = 50;

  StaffMembershipRepository get _repository =>
      ref.read(staffMembershipRepositoryProvider);

  StaffMembershipListState? get _currentState {
    final current = state;
    return current is AsyncData<StaffMembershipListState> ? current.value : null;
  }

  @override
  Future<StaffMembershipListState> build() async {
    return _load(
      searchQuery: '',
      statusFilter: StaffListStatusFilter.all,
      limit: _defaultLimit,
      offset: 0,
    );
  }

  Future<void> setSearchQuery(String value) async {
    final current = _currentState;
    final trimmed = value.trim();
    if (current != null && current.searchQuery == trimmed) return;
    await _reload(
      searchQuery: trimmed,
      statusFilter: current?.statusFilter ?? StaffListStatusFilter.all,
      keepDataWhileLoading: true,
    );
  }

  Future<void> setStatusFilter(StaffListStatusFilter value) async {
    final current = _currentState;
    if (current != null && current.statusFilter == value) return;
    await _reload(
      searchQuery: current?.searchQuery ?? '',
      statusFilter: value,
      keepDataWhileLoading: true,
    );
  }

  Future<void> refresh() async {
    final current = _currentState;
    if (current == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(
        () => _load(
          searchQuery: '',
          statusFilter: StaffListStatusFilter.all,
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
      final refreshed = await _load(
        searchQuery: current.searchQuery,
        statusFilter: current.statusFilter,
        limit: current.limit,
        offset: 0,
      );
      state = AsyncData(refreshed);
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isRefreshing: false,
          inlineError: error.toString(),
        ),
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
      final nextOffset = current.offset + current.memberships.length;
      final more = await _repository.fetchMemberships(
        status: _statusFilterToApiValue(current.statusFilter),
        search: current.searchQuery,
        limit: current.limit,
        offset: nextOffset,
      );
      state = AsyncData(
        current.copyWith(
          memberships: [...current.memberships, ...more],
          offset: nextOffset,
          canLoadMore: more.length >= current.limit,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          inlineError: error.toString(),
        ),
      );
    }
  }

  Future<void> reconcileAfterMutation() async {
    await refresh();
    ref.invalidate(staffMembershipOptionsProvider);
  }

  Future<void> _reload({
    required String searchQuery,
    required StaffListStatusFilter statusFilter,
    required bool keepDataWhileLoading,
  }) async {
    final current = _currentState;
    if (keepDataWhileLoading && current != null) {
      state = AsyncData(
        current.copyWith(isRefreshing: true, clearInlineError: true),
      );
      try {
        final next = await _load(
          searchQuery: searchQuery,
          statusFilter: statusFilter,
          limit: current.limit,
          offset: 0,
        );
        state = AsyncData(next);
      } catch (error) {
        state = AsyncData(
          current.copyWith(
            isRefreshing: false,
            inlineError: error.toString(),
          ),
        );
      }
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _load(
        searchQuery: searchQuery,
        statusFilter: statusFilter,
        limit: _defaultLimit,
        offset: 0,
      ),
    );
  }

  Future<StaffMembershipListState> _load({
    required String searchQuery,
    required StaffListStatusFilter statusFilter,
    required int limit,
    required int offset,
  }) async {
    final branches = await ref.read(staffTenantBranchesProvider.future);
    final branchNameById = {
      for (final branch in branches) branch.branchId: branch.branchName,
    };
    final memberships = await _repository.fetchMemberships(
      status: _statusFilterToApiValue(statusFilter),
      search: searchQuery,
      limit: limit,
      offset: offset,
    );
    return StaffMembershipListState(
      memberships: memberships,
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      limit: limit,
      offset: offset,
      canLoadMore: memberships.length >= limit,
      branchNameById: branchNameById,
    );
  }
}
