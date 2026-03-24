import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/reporting/ui/models/restock_spend_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/models/sales_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/view/attendance_summary/attendance_reporting_summary_page.dart';
import 'package:modular_pos/features/reporting/ui/view/inventory_summary/inventory_reporting_summary_page.dart';
import 'package:modular_pos/features/reporting/ui/view/reporting_shell/reporting_bottom_nav_shell_page.dart';
import 'package:modular_pos/features/reporting/ui/view/restock_spend_drill_down/restock_spend_drill_down_page.dart';
import 'package:modular_pos/features/reporting/ui/view/sales_drill_down/sales_drill_down_page.dart';
import 'package:modular_pos/features/reporting/ui/view/sales_summary/sales_summary_page.dart';

List<RouteBase> buildReportingRoutes() {
  return [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ReportingBottomNavShellPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.reporting.path,
              name: AppRoute.reporting.name,
              builder: (context, state) => const SalesSummaryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.reportingInventory.path,
              name: AppRoute.reportingInventory.name,
              builder: (context, state) =>
                  const InventoryReportingSummaryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.reportingAttendance.path,
              name: AppRoute.reportingAttendance.name,
              builder: (context, state) =>
                  const AttendanceReportingSummaryPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoute.reportingSalesDrillDown.path,
      name: AppRoute.reportingSalesDrillDown.name,
      builder: (context, state) {
        final extra = state.extra;
        final args = extra is SalesDrillDownRouteArgs
            ? extra
            : SalesDrillDownRouteArgs.fromQueryParameters(
                state.uri.queryParameters,
              );
        if (args == null) {
          throw ArgumentError('Missing sales drill-down route args');
        }
        return SalesDrillDownPage(args: args);
      },
    ),
    GoRoute(
      path: AppRoute.reportingInventoryDrillDown.path,
      name: AppRoute.reportingInventoryDrillDown.name,
      builder: (context, state) {
        final extra = state.extra;
        final args = extra is RestockSpendDrillDownRouteArgs
            ? extra
            : RestockSpendDrillDownRouteArgs.fromQueryParameters(
                state.uri.queryParameters,
              );
        if (args == null) {
          throw ArgumentError('Missing restock spend drill-down route args');
        }
        return RestockSpendDrillDownPage(args: args);
      },
    ),
  ];
}
