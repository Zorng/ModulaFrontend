import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/domain/models/restock_spend_reporting.dart';
import 'package:modular_pos/features/reporting/ui/models/reporting_branch_option.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';

class RestockSpendSummaryState {
  static const _unset = Object();

  const RestockSpendSummaryState({
    required this.isLoading,
    required this.report,
    required this.errorMessage,
    required this.errorCode,
    required this.window,
    required this.selectedDateRange,
    required this.branchScope,
    required this.branchId,
    required this.branches,
    required this.canUseAllBranches,
  });

  final bool isLoading;
  final RestockSpendSummaryReport? report;
  final String? errorMessage;
  final String? errorCode;
  final ReportTimeWindow window;
  final DateTimeRange selectedDateRange;
  final ReportBranchScope branchScope;
  final String? branchId;
  final List<ReportingBranchOption> branches;
  final bool canUseAllBranches;

  bool get usesCustomWindow => window == ReportTimeWindow.custom;

  RestockSpendSummaryState copyWith({
    bool? isLoading,
    Object? report = _unset,
    Object? errorMessage = _unset,
    Object? errorCode = _unset,
    ReportTimeWindow? window,
    DateTimeRange? selectedDateRange,
    ReportBranchScope? branchScope,
    Object? branchId = _unset,
    List<ReportingBranchOption>? branches,
    bool? canUseAllBranches,
  }) {
    return RestockSpendSummaryState(
      isLoading: isLoading ?? this.isLoading,
      report: identical(report, _unset)
          ? this.report
          : report as RestockSpendSummaryReport?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      window: window ?? this.window,
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      branchScope: branchScope ?? this.branchScope,
      branchId: identical(branchId, _unset)
          ? this.branchId
          : branchId as String?,
      branches: branches ?? this.branches,
      canUseAllBranches: canUseAllBranches ?? this.canUseAllBranches,
    );
  }

  ReportScopeQuery toScopeQuery({required String? fallbackBranchId}) {
    final effectiveBranchId = branchScope == ReportBranchScope.branch
        ? ((branchId ?? '').trim().isNotEmpty
              ? branchId!.trim()
              : (fallbackBranchId ?? '').trim())
        : null;

    return ReportScopeQuery(
      window: window,
      from: usesCustomWindow
          ? formatReportQueryDate(selectedDateRange.start)
          : null,
      to: usesCustomWindow
          ? formatReportQueryDate(selectedDateRange.end)
          : null,
      branchScope: branchScope,
      branchId: effectiveBranchId?.isEmpty == true ? null : effectiveBranchId,
    );
  }
}

final restockSpendSummaryControllerProvider =
    NotifierProvider<RestockSpendSummaryController, RestockSpendSummaryState>(
      RestockSpendSummaryController.new,
    );

class RestockSpendSummaryController extends Notifier<RestockSpendSummaryState> {
  ManagementReportingRepository get _repository =>
      ref.read(managementReportingRepositoryProvider);

  @override
  RestockSpendSummaryState build() {
    final access = ref.watch(reportingAccessContextProvider);
    final today = DateTime.now();
    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 0);
    final defaultBranchScope = access?.canUseAllBranches == true
        ? ReportBranchScope.allBranches
        : ReportBranchScope.branch;

    return RestockSpendSummaryState(
      isLoading: false,
      report: null,
      errorMessage: null,
      errorCode: null,
      window: ReportTimeWindow.month,
      selectedDateRange: DateTimeRange(start: monthStart, end: monthEnd),
      branchScope: defaultBranchScope,
      branchId: defaultBranchScope == ReportBranchScope.branch
          ? access?.fallbackBranchId
          : null,
      branches: access?.branches ?? const [],
      canUseAllBranches: access?.canUseAllBranches ?? false,
    );
  }

  Future<void> load({bool showLoading = true}) async {
    final access = ref.read(reportingAccessContextProvider);
    if (access == null || !access.canViewReporting || access.tenantId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Reporting access is not available for the current session.',
        errorCode: 'REPORTING_ACCESS_UNAVAILABLE',
      );
      return;
    }

    final query = state.toScopeQuery(fallbackBranchId: access.fallbackBranchId);
    if (query.branchScope == ReportBranchScope.branch &&
        (query.branchId ?? '').trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'A branch must be selected before loading this report.',
        errorCode: 'REPORT_BRANCH_REQUIRED',
      );
      return;
    }

    if (showLoading) {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        errorCode: null,
      );
    }

    try {
      final report = await _repository.getRestockSpendSummary(
        RestockSpendSummaryReportQuery(scope: query),
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

  Future<void> refresh() => load(showLoading: false);

  Future<void> setWindow(ReportTimeWindow value) async {
    if (state.window == value) return;
    state = state.copyWith(window: value);
    await load();
  }

  Future<void> setDateRange(DateTimeRange value) async {
    state = state.copyWith(
      window: ReportTimeWindow.custom,
      selectedDateRange: value,
    );
    await load();
  }

  Future<void> setBranchScope(ReportBranchScope value) async {
    if (!state.canUseAllBranches && value == ReportBranchScope.allBranches) {
      return;
    }
    final access = ref.read(reportingAccessContextProvider);
    state = state.copyWith(
      branchScope: value,
      branchId: value == ReportBranchScope.allBranches
          ? null
          : ((state.branchId ?? '').trim().isNotEmpty
                ? state.branchId
                : access?.fallbackBranchId),
    );
    await load();
  }

  Future<void> setBranchId(String? value) async {
    if (state.branchId == value) return;
    state = state.copyWith(branchId: value);
    await load();
  }
}

({String message, String? code}) _mapError(Object error) {
  if (error is ApiClientException) {
    return (message: error.message, code: error.code);
  }
  return (message: error.toString(), code: null);
}
