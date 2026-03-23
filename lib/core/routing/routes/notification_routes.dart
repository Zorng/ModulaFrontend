import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/notification/ui/view/operational_notification_inbox/operational_notification_inbox_page.dart';

List<RouteBase> buildNotificationRoutes() {
  return [
    GoRoute(
      path: AppRoute.notifications.path,
      name: AppRoute.notifications.name,
      builder: (context, state) => const OperationalNotificationInboxPage(),
    ),
  ];
}
