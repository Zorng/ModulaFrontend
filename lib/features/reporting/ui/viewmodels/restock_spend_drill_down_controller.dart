import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/restock_spend_reporting.dart';
import 'package:modular_pos/features/reporting/ui/models/restock_spend_drill_down_route_args.dart';

class RestockSpendDrillDownState {
  static const _unset = Object();

  const RestockSpendDrillDownState({
    required this.isLoading,
    required this.isLoadingMore,
    required this.report,
    required this.errorMessage,
    required this.errorCode,
    required this.scope,
    required this.costFilter,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final RestockSpendDrillDownReport? report;
  final String? errorMessage;
  final String? errorCode;
  final ReportScopeQuery? scope;
  final RestockSpendCostFilter costFilter;

  bool get isInitialized => scope != null;

  RestockSpendDrillDownState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    Object? report = _unset,
    Object? errorMessage = _unset,
    Object? errorCode = _unset,
    Object? scope = _unset,
    RestockSpendCostFilter? costFilter,
  }) {
    return RestockSpendDrillDownState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      report: identical(report, _unset)
          ? this.report
          : report as RestockSpendDrillDownReport?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      scope: identical(scope, _unset) ? this.scope : scope as ReportScopeQuery?,
      costFilter: costFilter ?? this.costFilter,
    );
  }
}

final restockSpendDrillDownControllerProvider =
    NotifierProvider<
      RestockSpendDrillDownController,
      RestockSpendDrillDownState
    >(RestockSpendDrillDownController.new);

class RestockSpendDrillDownController
    extends Notifier<RestockSpendDrillDownState> {
  ManagementReportingRepository get _repository =>
      ref.read(managementReportingRepositoryProvider);

  @override
  RestockSpendDrillDownState build() {
    return const RestockSpendDrillDownState(
      isLoading: false,
      isLoadingMore: false,
      report: null,
      errorMessage: null,
      errorCode: null,
      scope: null,
      costFilter: RestockSpendCostFilter.all,
    );
  }

  Future<void> initialize(RestockSpendDrillDownRouteArgs args) async {
    if (_sameScope(state.scope, args.scope) && state.report != null) return;
    state = state.copyWith(
      scope: args.scope,
      report: null,
      errorMessage: null,
      errorCode: null,
      costFilter: RestockSpendCostFilter.all,
    );
    await _load();
  }

  Future<void> refresh() => _load();

  Future<void> setCostFilter(RestockSpendCostFilter value) async {
    if (state.costFilter == value) return;
    state = state.copyWith(costFilter: value);
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
      final next = await _repository.getRestockSpendDrillDown(
        RestockSpendDrillDownReportQuery(
          scope: state.scope!,
          costFilter: state.costFilter,
          limit: report.limit,
          offset: report.items.length,
        ),
      );
      state = state.copyWith(
        isLoadingMore: false,
        report: RestockSpendDrillDownReport(
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
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      errorCode: null,
    );

    try {
      final report = await _repository.getRestockSpendDrillDown(
        RestockSpendDrillDownReportQuery(
          scope: state.scope!,
          costFilter: state.costFilter,
        ),
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
