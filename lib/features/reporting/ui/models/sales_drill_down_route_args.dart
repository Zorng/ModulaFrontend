import 'package:modular_pos/features/reporting/domain/models/report_query.dart';

class SalesDrillDownRouteArgs {
  const SalesDrillDownRouteArgs({required this.scope});

  final ReportScopeQuery scope;
}
