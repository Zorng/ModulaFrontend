import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/ui/view/account/account_page.dart';
import 'package:modular_pos/features/common/ui/settings_page.dart';

List<RouteBase> buildAccountRoutes() {
  return [
    GoRoute(
      path: AppRoute.account.path,
      name: AppRoute.account.name,
      builder: (context, state) => const AccountPage(),
    ),
    GoRoute(
      path: AppRoute.settings.path,
      name: AppRoute.settings.name,
      builder: (context, state) => const SettingsPage(),
    ),
  ];
}
