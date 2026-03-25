import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/ui/models/report_scope_route_query.dart';

class SalesDrillDownRouteArgs {
  const SalesDrillDownRouteArgs({required this.scope, this.branchName});

  final ReportScopeQuery scope;
  final String? branchName;

  Map<String, String> toQueryParameters() {
    return {
      ...reportScopeQueryToRouteParameters(scope),
      if (branchName case final branchName?) 'branchName': branchName,
    };
  }

  static SalesDrillDownRouteArgs? fromQueryParameters(
    Map<String, String> queryParameters,
  ) {
    final scope = reportScopeQueryFromRouteParameters(queryParameters);
    if (scope == null) {
      return null;
    }
    return SalesDrillDownRouteArgs(
      scope: scope,
      branchName: _normalized(queryParameters['branchName']),
    );
  }
}

String? _normalized(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
