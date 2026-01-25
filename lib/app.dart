import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/hydration/app_hydration_listener.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/routing/routes/account_routes.dart';
import 'package:modular_pos/core/routing/routes/attendance_routes.dart';
import 'package:modular_pos/core/routing/routes/cash_routes.dart';
import 'package:modular_pos/core/routing/routes/core_routes.dart';
import 'package:modular_pos/core/routing/routes/inventory_routes.dart';
import 'package:modular_pos/core/routing/routes/menu_routes.dart';
import 'package:modular_pos/core/routing/routes/policy_routes.dart';
import 'package:modular_pos/core/routing/routes/portal_routes.dart';
import 'package:modular_pos/core/routing/routes/sale_routes.dart';
import 'package:modular_pos/core/routing/routes/staff_routes.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_wide_navigation_rail_shell.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    errorBuilder: (context, state) => const Scaffold(
      body: Center(
        child: Text(
          'Page not found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    redirect: (context, state) {
      final authState = ref.read(loginControllerProvider);
      final session = authState.session;
      final path = state.uri.path; // current path

      final isLoggingIn = path == AppRoute.login.path;
      final isTenantSelection = path == AppRoute.tenantSelection.path;
      final isPortal = path == AppRoute.portal.path;

      // Developer-only gallery should be reachable without auth.
      if (path == AppRoute.components.path) {
        return null;
      }

      // Not authenticated: only allow /login
      if (session == null) {
        return isLoggingIn ? null : AppRoute.login.path;
      }

      // Authenticated, but tenant context not selected yet.
      if (session.requiresTenantSelection) {
        return isTenantSelection ? null : AppRoute.tenantSelection.path;
      }

      final role = session.user.role.trim().toLowerCase();

      String homeForRole() {
        switch (role) {
          case 'admin':
          case 'cashier':
          case 'manager':
          default:
            return AppRoute.sale.path;
        }
      }

      // Already authenticated: prevent going back to /login
      if (isLoggingIn) {
        return homeForRole();
      }

      if (isPortal) {
        final mediaQuery = MediaQuery.maybeOf(context);
        if (mediaQuery != null &&
            AppBreakpoints.isLarge(mediaQuery.size.width)) {
          return homeForRole();
        }
      }

      // Authenticated but not allowed to access admin portal/menu → 404
      bool isInPathGroup(String root) {
        return path == root || path.startsWith('$root/');
      }

      if (isInPathGroup(AppRoute.adminMenu.path) && role != 'admin') {
        return '/404';
      }

      // Authenticated but not allowed to access policy → 404
      if (isInPathGroup(AppRoute.policy.path) &&
          role != 'admin' &&
          role != 'cashier') {
        return '/404';
      }
      if (isInPathGroup(AppRoute.inventory.path) && role != 'admin') {
        return '/404';
      }
      if (isInPathGroup(AppRoute.staff.path) && role != 'admin') {
        return '/404';
      }
      // Portal routes removed; role gating handled per feature.

      // Authenticated but not allowed to access cashier dashboard → 404
      if (isInPathGroup(AppRoute.cashSession.path) &&
          role != 'cashier' &&
          role != 'admin') {
        return '/404';
      }
      if (isInPathGroup(AppRoute.attendance.path) &&
          role != 'cashier' &&
          role != 'manager') {
        return '/404';
      }
      if (path == AppRoute.xReport.path &&
          role != 'admin' &&
          role != 'cashier') {
        return '/404';
      }
      if (path == AppRoute.zReport.path && role != 'admin') {
        return '/404';
      }
      if (path == AppRoute.attendanceManagement.path && role != 'admin') {
        return '/404';
      }

      // For other paths (including unknown ones), don't redirect here.
      // If no route matches, errorBuilder will show "Page not found".
      return null;
    },
    initialLocation: AppRoute.login.path,
    routes: [
      ...buildCoreRoutes(),
      ShellRoute(
        builder: (context, state, child) => AppScaffoldShell(
          currentPath: state.uri.path,
          child: child,
        ),
        routes: [
          buildPortalRoute(ref),
          ...buildMenuRoutes(),
          ...buildPolicyRoutes(),
          ...buildAccountRoutes(),
          ...buildAttendanceRoutes(),
          ...buildInventoryRoutes(),
          ...buildSaleRoutes(),
          ...buildCashRoutes(),
          ...buildStaffRoutes(),
        ],
      ),
    ],
  );
});

class ModulaApp extends ConsumerWidget {
  const ModulaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return AppHydrationListener(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Modula POS',
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
