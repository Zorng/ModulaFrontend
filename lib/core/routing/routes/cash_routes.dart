import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/cash_session/ui/view/cashier_cash_session.dart';
import 'package:modular_pos/features/cash_session/ui/view/x_report/x_report_page.dart';
import 'package:modular_pos/features/cash_session/ui/view/z_report/z_report_page.dart';

List<RouteBase> buildCashRoutes() {
  return [
    GoRoute(
      path: AppRoute.cashSession.path,
      name: AppRoute.cashSession.name,
      builder: (context, state) => const CashSessionScreen(),
    ),
    GoRoute(
      path: AppRoute.xReport.path,
      name: AppRoute.xReport.name,
      builder: (context, state) => const XReportPage(),
    ),
    GoRoute(
      path: AppRoute.zReport.path,
      name: AppRoute.zReport.name,
      builder: (context, state) => const ZReportPage(),
    ),
  ];
}
