import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/audit/ui/view/audit_log_page.dart';

List<RouteBase> buildAuditRoutes() {
  return [
    GoRoute(
      path: AppRoute.audit.path,
      name: AppRoute.audit.name,
      builder: (context, state) => const AuditLogPage(),
    ),
  ];
}
