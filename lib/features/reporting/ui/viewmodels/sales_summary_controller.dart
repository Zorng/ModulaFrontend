import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/models/reporting_branch_option.dart';
import 'package:modular_pos/features/reporting/ui/models/sales_summary_kpi_item.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';

class SalesSummaryState {
  static const _unset = Object();

  const SalesSummaryState({
    required this.isLoading,
    required this.report,
    required this.errorMessage,
    required this.errorCode,
    required this.window,
    required this.selectedDateRange,
    required this.branchScope,
    required this.branchId,
    required this.topN,
    required this.branches,
    required this.canUseAllBranches,
  });

  final bool isLoading;
  final SalesSummaryReport? report;
  final String? errorMessage;
  final String? errorCode;
  final ReportTimeWindow window;
  final DateTimeRange selectedDateRange;
  final ReportBranchScope branchScope;
  final String? branchId;
  final int topN;
  final List<ReportingBranchOption> branches;
  final bool canUseAllBranches;

  bool get usesCustomWindow => window == ReportTimeWindow.custom;

  List<SalesSummaryKpiItem> get kpis {
    final currentReport = report;
    return [
      SalesSummaryKpiItem(
        title: 'Revenue',
        value: currentReport == null
            ? '--'
            : formatUsdAmount(currentReport.confirmed.totalGrandUsd),
        secondaryValue: currentReport == null
            ? null
            : formatKhrAmountLabel(currentReport.confirmed.totalGrandKhr),
        icon: Icons.payments_outlined,
      ),
      SalesSummaryKpiItem(
        title: 'Transactions',
        value: currentReport == null
            ? '--'
            : formatInteger(currentReport.confirmed.transactionCount),
        icon: Icons.receipt_long_outlined,
        accentColor: const Color(0xFF2563EB),
      ),
      SalesSummaryKpiItem(
        title: 'Average Order',
        value: _averageTicketValue(currentReport),
        secondaryValue: _averageTicketSecondaryValue(currentReport),
        icon: Icons.shopping_bag_outlined,
        accentColor: const Color(0xFFF59E0B),
      ),
      SalesSummaryKpiItem(
        title: 'Items sold',
        value: currentReport == null
            ? '--'
            : formatInteger(currentReport.confirmed.totalItemsSold),
        icon: Icons.inventory_2_outlined,
        accentColor: const Color(0xFF6B7280),
      ),
    ];
  }

  SalesSummaryState copyWith({
    bool? isLoading,
    Object? report = _unset,
    Object? errorMessage = _unset,
    Object? errorCode = _unset,
    ReportTimeWindow? window,
    DateTimeRange? selectedDateRange,
    ReportBranchScope? branchScope,
    Object? branchId = _unset,
    int? topN,
    List<ReportingBranchOption>? branches,
    bool? canUseAllBranches,
  }) {
    return SalesSummaryState(
      isLoading: isLoading ?? this.isLoading,
      report: identical(report, _unset)
          ? this.report
          : report as SalesSummaryReport?,
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
      topN: topN ?? this.topN,
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

final salesSummaryControllerProvider =
    NotifierProvider<SalesSummaryController, SalesSummaryState>(
      SalesSummaryController.new,
    );

class SalesSummaryController extends Notifier<SalesSummaryState> {
  ManagementReportingRepository get _repository =>
      ref.read(managementReportingRepositoryProvider);

  @override
  SalesSummaryState build() {
    final access = ref.watch(reportingAccessContextProvider);
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final defaultBranchScope = access?.canUseAllBranches == true
        ? ReportBranchScope.allBranches
        : ReportBranchScope.branch;

    return SalesSummaryState(
      isLoading: false,
      report: null,
      errorMessage: null,
      errorCode: null,
      window: ReportTimeWindow.day,
      selectedDateRange: DateTimeRange(
        start: normalizedToday,
        end: normalizedToday,
      ),
      branchScope: defaultBranchScope,
      branchId: defaultBranchScope == ReportBranchScope.branch
          ? access?.fallbackBranchId
          : null,
      topN: 10,
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
      final report = await _repository.getSalesSummary(
        SalesSummaryReportQuery(scope: query, topN: state.topN),
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

String _averageTicketValue(SalesSummaryReport? report) {
  final averageTicketUsd = report?.confirmed.averageTicketUsd;
  if (averageTicketUsd == null) return formatUsdAmount(0);
  return formatUsdAmount(averageTicketUsd);
}

String? _averageTicketSecondaryValue(SalesSummaryReport? report) {
  final averageTicketKhr = report?.confirmed.averageTicketKhr;
  if (averageTicketKhr == null) return formatKhrAmountLabel(0);
  return formatKhrAmountLabel(averageTicketKhr);
}
