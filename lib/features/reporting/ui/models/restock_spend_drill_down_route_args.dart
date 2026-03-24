import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/ui/models/report_scope_route_query.dart';

class RestockSpendDrillDownRouteArgs {
  const RestockSpendDrillDownRouteArgs({required this.scope});

  final ReportScopeQuery scope;

  Map<String, String> toQueryParameters() {
    return reportScopeQueryToRouteParameters(scope);
  }

  static RestockSpendDrillDownRouteArgs? fromQueryParameters(
    Map<String, String> queryParameters,
  ) {
    final scope = reportScopeQueryFromRouteParameters(queryParameters);
    if (scope == null) {
      return null;
    }
    return RestockSpendDrillDownRouteArgs(scope: scope);
  }
}
