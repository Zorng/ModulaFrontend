import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/widget_gallery_page.dart';
import 'package:modular_pos/features/auth/ui/view/login_view.dart';
import 'package:modular_pos/features/auth/ui/view/tenant_selection/tenant_selection_page.dart';

List<RouteBase> buildCoreRoutes() {
  return [
    GoRoute(
      path: AppRoute.login.path,
      name: AppRoute.login.name,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoute.tenantSelection.path,
      name: AppRoute.tenantSelection.name,
      builder: (context, state) => const TenantSelectionPage(),
    ),
    GoRoute(
      path: AppRoute.components.path,
      name: AppRoute.components.name,
      builder: (context, state) => const WidgetGalleryPage(),
    ),
  ];
}
