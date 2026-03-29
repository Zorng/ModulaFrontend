import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/ui/models/report_scope_route_query.dart';

class RestockSpendDrillDownRouteArgs {
  RestockSpendDrillDownRouteArgs({
    required ReportScopeQuery scope,
    this.branchName,
  }) : scope = _normalizedScope(scope);

  final ReportScopeQuery scope;
  final String? branchName;

  Map<String, String> toQueryParameters() {
    return {
      ...reportScopeQueryToRouteParameters(scope),
      if (branchName case final branchName?) 'branchName': branchName,
    };
  }

  static RestockSpendDrillDownRouteArgs? fromQueryParameters(
    Map<String, String> queryParameters,
  ) {
    final scope = reportScopeQueryFromRouteParameters(queryParameters);
    if (scope == null) {
      return null;
    }
    return RestockSpendDrillDownRouteArgs(
      scope: scope,
      branchName: _normalized(queryParameters['branchName']),
    );
  }
}

ReportScopeQuery _normalizedScope(ReportScopeQuery scope) {
  final normalizedFrom = _normalized(scope.from);
  final normalizedTo = _normalized(scope.to);
  final usesCustomWindow =
      scope.window == ReportTimeWindow.custom &&
      normalizedFrom != null &&
      normalizedTo != null;

  return ReportScopeQuery(
    window: usesCustomWindow ? ReportTimeWindow.custom : ReportTimeWindow.month,
    from: usesCustomWindow ? normalizedFrom : null,
    to: usesCustomWindow ? normalizedTo : null,
    branchScope: scope.branchScope,
    branchId: scope.branchScope == ReportBranchScope.branch
        ? _normalized(scope.branchId)
        : null,
  );
}

String? _normalized(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
