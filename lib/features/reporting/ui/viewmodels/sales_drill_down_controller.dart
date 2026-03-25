import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/models/sales_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';

class SalesDrillDownState {
  static const _unset = Object();

  const SalesDrillDownState({
    required this.isLoading,
    required this.isLoadingMore,
    required this.report,
    required this.errorMessage,
    required this.errorCode,
    required this.scope,
    required this.statusFilter,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final SalesDrillDownReport? report;
  final String? errorMessage;
  final String? errorCode;
  final ReportScopeQuery? scope;
  final SalesDrillDownStatusFilter statusFilter;

  bool get isInitialized => scope != null;
  bool get usesCustomWindow => window == ReportTimeWindow.custom;
  ReportTimeWindow get window => scope?.window ?? ReportTimeWindow.day;
  ReportBranchScope get branchScope =>
      scope?.branchScope ?? ReportBranchScope.branch;
  String? get branchId => scope?.branchId;
  DateTimeRange get selectedDateRange => _dateRangeForScope(scope);

  SalesDrillDownState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    Object? report = _unset,
    Object? errorMessage = _unset,
    Object? errorCode = _unset,
    Object? scope = _unset,
    SalesDrillDownStatusFilter? statusFilter,
  }) {
    return SalesDrillDownState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      report: identical(report, _unset)
          ? this.report
          : report as SalesDrillDownReport?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      scope: identical(scope, _unset) ? this.scope : scope as ReportScopeQuery?,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

final salesDrillDownControllerProvider =
    NotifierProvider<SalesDrillDownController, SalesDrillDownState>(
      SalesDrillDownController.new,
    );

class SalesDrillDownController extends Notifier<SalesDrillDownState> {
  ManagementReportingRepository get _repository =>
      ref.read(managementReportingRepositoryProvider);

  @override
  SalesDrillDownState build() {
    return const SalesDrillDownState(
      isLoading: false,
      isLoadingMore: false,
      report: null,
      errorMessage: null,
      errorCode: null,
      scope: null,
      statusFilter: SalesDrillDownStatusFilter.all,
    );
  }

  Future<void> initialize(SalesDrillDownRouteArgs args) async {
    final scope = _normalizeScope(args.scope);
    if (_sameScope(state.scope, scope) && state.report != null) return;
    state = state.copyWith(
      scope: scope,
      report: null,
      errorMessage: null,
      errorCode: null,
      statusFilter: SalesDrillDownStatusFilter.all,
    );
    await _load();
  }

  Future<void> refresh() => _load();

  Future<void> setStatusFilter(SalesDrillDownStatusFilter value) async {
    if (state.statusFilter == value) return;
    state = state.copyWith(statusFilter: value);
    await _load();
  }

  Future<void> applyFilters({
    required ReportTimeWindow window,
    required DateTimeRange selectedDateRange,
    required ReportBranchScope branchScope,
    required String? branchId,
    required SalesDrillDownStatusFilter statusFilter,
  }) async {
    if (state.scope == null) return;

    final access = ref.read(reportingAccessContextProvider);
    final effectiveBranchScope =
        branchScope == ReportBranchScope.allBranches &&
            access?.canUseAllBranches != true
        ? ReportBranchScope.branch
        : branchScope;
    final nextScope = _normalizeScope(
      ReportScopeQuery(
        window: window,
        from: window == ReportTimeWindow.custom
            ? formatReportQueryDate(selectedDateRange.start)
            : null,
        to: window == ReportTimeWindow.custom
            ? formatReportQueryDate(selectedDateRange.end)
            : null,
        branchScope: effectiveBranchScope,
        branchId: effectiveBranchScope == ReportBranchScope.allBranches
            ? null
            : branchId,
      ),
    );

    if (_sameScope(state.scope, nextScope) &&
        state.statusFilter == statusFilter) {
      return;
    }

    state = state.copyWith(scope: nextScope, statusFilter: statusFilter);
    await _load();
  }

  Future<void> setWindow(ReportTimeWindow value) async {
    if (state.scope == null || state.window == value) return;
    if (value == ReportTimeWindow.custom) return;

    state = state.copyWith(
      scope: _normalizeScope(
        ReportScopeQuery(
          window: value,
          branchScope: state.branchScope,
          branchId: state.branchId,
        ),
      ),
    );
    await _load();
  }

  Future<void> setDateRange(DateTimeRange value) async {
    if (state.scope == null) return;
    state = state.copyWith(
      scope: _normalizeScope(
        ReportScopeQuery(
          window: ReportTimeWindow.custom,
          from: formatReportQueryDate(value.start),
          to: formatReportQueryDate(value.end),
          branchScope: state.branchScope,
          branchId: state.branchId,
        ),
      ),
    );
    await _load();
  }

  Future<void> setBranchScope(ReportBranchScope value) async {
    if (state.scope == null) return;
    final access = ref.read(reportingAccessContextProvider);
    if (access?.canUseAllBranches != true &&
        value == ReportBranchScope.allBranches) {
      return;
    }

    state = state.copyWith(
      scope: _normalizeScope(
        ReportScopeQuery(
          window: state.window,
          from: state.usesCustomWindow ? state.scope?.from : null,
          to: state.usesCustomWindow ? state.scope?.to : null,
          branchScope: value,
          branchId: value == ReportBranchScope.allBranches
              ? null
              : ((state.branchId ?? '').trim().isNotEmpty
                    ? state.branchId
                    : access?.fallbackBranchId),
        ),
      ),
    );
    await _load();
  }

  Future<void> setBranchId(String? value) async {
    if (state.scope == null || state.branchId == value) return;
    state = state.copyWith(
      scope: _normalizeScope(
        ReportScopeQuery(
          window: state.window,
          from: state.usesCustomWindow ? state.scope?.from : null,
          to: state.usesCustomWindow ? state.scope?.to : null,
          branchScope: ReportBranchScope.branch,
          branchId: value,
        ),
      ),
    );
    await _load();
  }

  Future<void> loadMore() async {
    final report = state.report;
    if (report == null ||
        state.scope == null ||
        state.isLoadingMore ||
        !report.hasMore) {
      return;
    }

    state = state.copyWith(
      isLoadingMore: true,
      errorMessage: null,
      errorCode: null,
    );
    try {
      final next = await _repository.getSalesDrillDown(
        SalesDrillDownReportQuery(
          scope: state.scope!,
          status: state.statusFilter,
          limit: report.limit,
          offset: report.items.length,
        ),
      );
      state = state.copyWith(
        isLoadingMore: false,
        report: SalesDrillDownReport(
          scope: next.scope,
          items: [...report.items, ...next.items],
          limit: next.limit,
          offset: next.offset,
          total: next.total,
          hasMore: next.hasMore,
        ),
      );
    } catch (error) {
      final mapped = _mapError(error);
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  Future<void> _load() async {
    if (state.scope == null) return;
    final scope = _normalizeScope(state.scope!);
    if (!_sameScope(state.scope, scope)) {
      state = state.copyWith(scope: scope);
    }
    if (scope.branchScope == ReportBranchScope.branch &&
        (scope.branchId ?? '').trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'A branch must be selected before loading this report.',
        errorCode: 'REPORT_BRANCH_REQUIRED',
      );
      return;
    }
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      errorCode: null,
    );

    try {
      final report = await _repository.getSalesDrillDown(
        SalesDrillDownReportQuery(scope: scope, status: state.statusFilter),
      );
      state = state.copyWith(
        isLoading: false,
        report: report,
        errorMessage: null,
        errorCode: null,
      );
    } catch (error) {
      final mapped = _mapError(error);
      state = state.copyWith(
        isLoading: false,
        errorMessage: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  ReportScopeQuery _normalizeScope(ReportScopeQuery scope) {
    final access = ref.read(reportingAccessContextProvider);
    final effectiveBranchId = scope.branchScope == ReportBranchScope.branch
        ? ((scope.branchId ?? '').trim().isNotEmpty
              ? scope.branchId!.trim()
              : (access?.fallbackBranchId ?? '').trim())
        : null;

    return ReportScopeQuery(
      window: scope.window,
      from: scope.window == ReportTimeWindow.custom
          ? _normalizedQueryDate(scope.from)
          : null,
      to: scope.window == ReportTimeWindow.custom
          ? _normalizedQueryDate(scope.to)
          : null,
      branchScope: scope.branchScope,
      branchId: effectiveBranchId?.isEmpty == true ? null : effectiveBranchId,
    );
  }
}

bool _sameScope(ReportScopeQuery? left, ReportScopeQuery? right) {
  if (left == null || right == null) return false;
  return left.window == right.window &&
      left.from == right.from &&
      left.to == right.to &&
      left.branchScope == right.branchScope &&
      left.branchId == right.branchId;
}

({String message, String? code}) _mapError(Object error) {
  if (error is ApiClientException) {
    return (message: error.message, code: error.code);
  }
  return (message: error.toString(), code: null);
}

DateTimeRange _dateRangeForScope(ReportScopeQuery? scope) {
  if (scope != null && scope.window == ReportTimeWindow.custom) {
    final start = _parseQueryDate(scope.from);
    final end = _parseQueryDate(scope.to);
    if (start != null && end != null) {
      return DateTimeRange(start: start, end: end);
    }
  }

  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  return DateTimeRange(start: normalizedToday, end: normalizedToday);
}

DateTime? _parseQueryDate(String? value) {
  final normalized = _normalizedQueryDate(value);
  if (normalized == null) return null;
  return DateTime.tryParse(normalized);
}

String? _normalizedQueryDate(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
