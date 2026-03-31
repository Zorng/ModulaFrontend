import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/audit/data/audit_repository.dart';
import 'package:modular_pos/features/audit/domain/models/audit_event.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class AuditLogState {
  static const Object _unset = Object();
  static const int defaultPageSize = 50;

  const AuditLogState({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
    this.selectedBranchId,
    this.actionKeyQuery,
    this.selectedOutcome,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.inlineError,
  });

  const AuditLogState.empty()
    : this(
        items: const <AuditEvent>[],
        limit: defaultPageSize,
        offset: 0,
        total: 0,
        hasMore: false,
      );

  final List<AuditEvent> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;
  final String? selectedBranchId;
  final String? actionKeyQuery;
  final AuditOutcome? selectedOutcome;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? inlineError;

  AuditLogState copyWith({
    List<AuditEvent>? items,
    int? limit,
    int? offset,
    int? total,
    bool? hasMore,
    Object? selectedBranchId = _unset,
    Object? actionKeyQuery = _unset,
    Object? selectedOutcome = _unset,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? inlineError,
    bool clearInlineError = false,
  }) {
    return AuditLogState(
      items: items ?? this.items,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      selectedBranchId: identical(selectedBranchId, _unset)
          ? this.selectedBranchId
          : selectedBranchId as String?,
      actionKeyQuery: identical(actionKeyQuery, _unset)
          ? this.actionKeyQuery
          : actionKeyQuery as String?,
      selectedOutcome: identical(selectedOutcome, _unset)
          ? this.selectedOutcome
          : selectedOutcome as AuditOutcome?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      inlineError: clearInlineError ? null : inlineError ?? this.inlineError,
    );
  }
}

final auditLogControllerProvider =
    AsyncNotifierProvider<AuditLogController, AuditLogState>(
      AuditLogController.new,
    );

class AuditLogController extends AsyncNotifier<AuditLogState> {
  AuditRepository get _repository => ref.read(auditRepositoryProvider);

  AuditLogState? get _currentState {
    final current = state;
    return current is AsyncData<AuditLogState> ? current.value : null;
  }

  @override
  Future<AuditLogState> build() async {
    final session = ref.watch(loginControllerProvider.select((s) => s.session));
    final role = resolveSessionAuthRole(session);
    if (session == null || (role != AuthRole.owner && role != AuthRole.admin)) {
      return const AuditLogState.empty();
    }

    return _load(baseState: const AuditLogState.empty(), offset: 0);
  }

  Future<void> refresh() async {
    final current = _currentState;
    final session = ref.read(loginControllerProvider).session;
    final role = resolveSessionAuthRole(session);
    if (session == null || (role != AuthRole.owner && role != AuthRole.admin)) {
      state = const AsyncData(AuditLogState.empty());
      return;
    }

    final baseState = current ?? const AuditLogState.empty();
    if (current == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(
        () => _load(baseState: baseState, offset: 0),
      );
      return;
    }

    state = AsyncData(
      current.copyWith(isRefreshing: true, clearInlineError: true),
    );
    try {
      state = AsyncData(await _load(baseState: current, offset: 0));
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isRefreshing: false,
          inlineError: _errorMessage(
            error,
            fallbackMessage: 'Failed to refresh audit events.',
          ),
        ),
      );
    }
  }

  Future<void> applyFilters({
    String? branchId,
    String? actionKey,
    Object? outcome = AuditLogState._unset,
  }) async {
    final current = _currentState ?? const AuditLogState.empty();
    final session = ref.read(loginControllerProvider).session;
    final role = resolveSessionAuthRole(session);
    final normalizedBranchId = _normalizeNullable(branchId);
    final normalizedActionKey = _normalizeNullable(actionKey);
    final nextState = current.copyWith(
      selectedBranchId: normalizedBranchId,
      actionKeyQuery: normalizedActionKey,
      selectedOutcome: identical(outcome, AuditLogState._unset)
          ? current.selectedOutcome
          : outcome as AuditOutcome?,
      isRefreshing: true,
      clearInlineError: true,
    );

    if (session == null || (role != AuthRole.owner && role != AuthRole.admin)) {
      state = const AsyncData(AuditLogState.empty());
      return;
    }

    state = AsyncData(nextState);
    try {
      state = AsyncData(await _load(baseState: nextState, offset: 0));
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          inlineError: _errorMessage(
            error,
            fallbackMessage: 'Failed to apply audit filters.',
          ),
        ),
      );
    }
  }

  Future<void> clearFilters() async {
    await applyFilters(branchId: '', actionKey: '', outcome: null);
  }

  Future<void> loadMore() async {
    final current = _currentState;
    final session = ref.read(loginControllerProvider).session;
    final role = resolveSessionAuthRole(session);
    if (current == null ||
        session == null ||
        (role != AuthRole.owner && role != AuthRole.admin)) {
      return;
    }
    if (!current.hasMore || current.isLoadingMore || current.isRefreshing) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearInlineError: true),
    );
    try {
      final page = await _repository.listEvents(
        branchId: current.selectedBranchId,
        actionKey: current.actionKeyQuery,
        outcome: current.selectedOutcome,
        limit: current.limit,
        offset: current.items.length,
      );
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          limit: page.limit,
          offset: page.offset,
          total: page.total,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          inlineError: _errorMessage(
            error,
            fallbackMessage: 'Failed to load more audit events.',
          ),
        ),
      );
    }
  }

  Future<void> goToPage(int page) async {
    final current = _currentState;
    final session = ref.read(loginControllerProvider).session;
    final role = resolveSessionAuthRole(session);
    if (current == null ||
        session == null ||
        (role != AuthRole.owner && role != AuthRole.admin)) {
      return;
    }
    if (current.isRefreshing || current.isLoadingMore) {
      return;
    }

    final limit = current.limit <= 0
        ? AuditLogState.defaultPageSize
        : current.limit;
    final totalPages = current.total <= 0
        ? 1
        : ((current.total - 1) ~/ limit) + 1;
    final safePage = page.clamp(1, totalPages);
    final nextOffset = (safePage - 1) * limit;
    if (nextOffset == current.offset && current.items.length <= limit) {
      return;
    }

    final nextState = current.copyWith(
      offset: nextOffset,
      isRefreshing: true,
      clearInlineError: true,
    );
    state = AsyncData(nextState);
    try {
      state = AsyncData(await _load(baseState: nextState, offset: nextOffset));
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          inlineError: _errorMessage(
            error,
            fallbackMessage: 'Failed to load audit page.',
          ),
        ),
      );
    }
  }

  Future<void> goToNextPage() async {
    final current = _currentState;
    if (current == null) return;
    final limit = current.limit <= 0
        ? AuditLogState.defaultPageSize
        : current.limit;
    final currentPage = (current.offset ~/ limit) + 1;
    await goToPage(currentPage + 1);
  }

  Future<void> goToPreviousPage() async {
    final current = _currentState;
    if (current == null) return;
    final limit = current.limit <= 0
        ? AuditLogState.defaultPageSize
        : current.limit;
    final currentPage = (current.offset ~/ limit) + 1;
    await goToPage(currentPage - 1);
  }

  Future<AuditLogState> _load({
    required AuditLogState baseState,
    required int offset,
  }) async {
    final page = await _repository.listEvents(
      branchId: baseState.selectedBranchId,
      actionKey: baseState.actionKeyQuery,
      outcome: baseState.selectedOutcome,
      limit: baseState.limit,
      offset: offset,
    );
    return baseState.copyWith(
      items: page.items,
      limit: page.limit,
      offset: page.offset,
      total: page.total,
      hasMore: page.hasMore,
      isRefreshing: false,
      isLoadingMore: false,
      clearInlineError: true,
    );
  }

  String? _normalizeNullable(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  String _errorMessage(Object error, {required String fallbackMessage}) {
    if (error is ApiClientException) return error.message;
    return fallbackMessage;
  }
}
