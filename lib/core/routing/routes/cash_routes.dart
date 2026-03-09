import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/cash_session/ui/view/cash_history/cash_session_history_page.dart';
import 'package:modular_pos/features/cash_session/ui/view/cash_session/cashier_cash_session.dart';
import 'package:modular_pos/features/cash_session/ui/view/cash_movement/cash_movement_page.dart';
import 'package:modular_pos/features/cash_session/ui/view/cash_shell/cash_bottom_nav_shell_page.dart';
import 'package:modular_pos/features/cash_session/ui/view/x_report/x_report_page.dart';

List<RouteBase> buildCashRoutes() {
  return [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return CashBottomNavShellPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.cashSession.path,
              name: AppRoute.cashSession.name,
              builder: (context, state) =>
                  const CashSessionScreen(showAppBar: false),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.cashMovement.path,
              name: AppRoute.cashMovement.name,
              builder: (context, state) => const CashMovementPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.zReport.path,
              name: AppRoute.zReport.name,
              builder: (context, state) => const CashSessionHistoryPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoute.xReport.path,
      name: AppRoute.xReport.name,
      builder: (context, state) => const XReportPage(showAppBar: true),
    ),
  ];
}
