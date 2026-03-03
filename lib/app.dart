import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/hydration/app_hydration_listener.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/routing/workspace_route_guard.dart';
import 'package:modular_pos/core/routing/routes/account_routes.dart';
import 'package:modular_pos/core/routing/routes/attendance_routes.dart';
import 'package:modular_pos/core/routing/routes/branch_routes.dart';
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
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/domain/workspace_context.dart';
import 'package:modular_pos/features/auth/domain/workspace_context_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerRefresh = ValueNotifier<int>(0);
  ref
    ..listen<LoginState>(loginControllerProvider, (_, __) {
      routerRefresh.value++;
    })
    ..onDispose(routerRefresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: routerRefresh,
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
      final isSignup = path == AppRoute.signup.path;
      final isOtpVerification = path == AppRoute.otpVerification.path;
      final isTenantSelection = path == AppRoute.tenantSelection.path;
      final isBranchSelection = path == AppRoute.branchSelection.path;
      final isPortal = path == AppRoute.portal.path;

      // Developer-only gallery should be reachable without auth.
      if (path == AppRoute.components.path) {
        return null;
      }

      // Not authenticated: only allow /login
      if (session == null) {
        if (isLoggingIn || isSignup || isOtpVerification) return null;
        return AppRoute.login.path;
      }

      // Authenticated, but tenant context not selected yet.
      if (session.requiresTenantSelection) {
        return isTenantSelection ? null : AppRoute.tenantSelection.path;
      }
      final role = resolveSessionAuthRole(session);
      final isAdminOrOwner = role == AuthRole.admin || role == AuthRole.owner;
      final isCashier = role == AuthRole.cashier;
      final isManager = role == AuthRole.manager;
      final workspaceContext = ref.read(workspaceContextProvider);
      final hasWorkspaceContext = workspaceContext != null;
      final activeBranchId = ref.read(activeBranchContextIdProvider) ?? '';
      final hasActiveBranchContext = activeBranchId.isNotEmpty;
      final isGlobalWorkspaceFeaturePath =
          isPathInGroup(path, AppRoute.adminMenu.path) ||
          isPathInGroup(path, AppRoute.inventory.path) ||
          isPathInGroup(path, AppRoute.staff.path);
      final isBranchWorkspaceFeaturePath =
          isPathInGroup(path, AppRoute.policy.path) ||
          isPathInGroup(path, AppRoute.branchSubscription.path) ||
          isPathInGroup(path, AppRoute.sale.path) ||
          isPathInGroup(path, AppRoute.cashSession.path) ||
          isPathInGroup(path, AppRoute.attendance.path) ||
          isPathInGroup(path, AppRoute.xReport.path) ||
          isPathInGroup(path, AppRoute.zReport.path);

      if (authState.requiresBranchSelection) {
        final canEnterGlobalWorkspace =
            isAdminOrOwner &&
            workspaceContext?.scope == WorkspaceScope.global &&
            (isPortal || isGlobalWorkspaceFeaturePath);
        final canEnterBranchWorkspace =
            hasActiveBranchContext && (isPortal || isBranchWorkspaceFeaturePath);
        if (canEnterGlobalWorkspace || canEnterBranchWorkspace) {
          // Admin/owner can continue to tenant-level global workspace
          // without branch selection.
        } else {
          return (isBranchSelection || isTenantSelection)
              ? null
              : AppRoute.branchSelection.path;
        }
      }

      final isWorkspaceManagedPath =
          isPortal ||
          isGlobalWorkspaceFeaturePath ||
          isBranchWorkspaceFeaturePath;
      final canRecoverWorkspaceFromContext =
          (isGlobalWorkspaceFeaturePath && isAdminOrOwner) ||
          (isBranchWorkspaceFeaturePath &&
              (hasActiveBranchContext || !authState.requiresBranchSelection)) ||
          (isPortal && (isAdminOrOwner || hasActiveBranchContext));

      if (isWorkspaceManagedPath &&
          !hasWorkspaceContext &&
          !canRecoverWorkspaceFromContext) {
        return buildBranchSelectionRedirect();
      }

      String homeForRole() {
        final context = workspaceContext;
        if (context == null) {
          if (isAdminOrOwner) return AppRoute.adminMenu.path;
          if (hasActiveBranchContext) return AppRoute.sale.path;
          return AppRoute.branchSelection.path;
        }
        if (context.scope == WorkspaceScope.global) {
          return AppRoute.adminMenu.path;
        }
        if (context.mode == WorkspaceMode.management) {
          return AppRoute.policy.path;
        }
        switch (role) {
          case AuthRole.owner:
          case AuthRole.admin:
          case AuthRole.cashier:
          case AuthRole.manager:
          case AuthRole.unknown:
            return AppRoute.sale.path;
        }
      }

      // Already authenticated: prevent going back to /login
      if (isLoggingIn || isSignup || isOtpVerification) {
        return homeForRole();
      }

      if (isPortal) {
        final mediaQuery = MediaQuery.maybeOf(context);
        if (mediaQuery != null &&
            AppBreakpoints.isLarge(mediaQuery.size.width)) {
          return homeForRole();
        }
      }

      if (isGlobalWorkspaceFeaturePath) {
        if (!isAdminOrOwner) return '/404';
        if (workspaceContext != null &&
            workspaceContext.scope != WorkspaceScope.global) {
          return '/404';
        }
      }

      if (isBranchWorkspaceFeaturePath) {
        final branchGuardRedirect = guardBranchWorkspaceAccess(
          workspaceContext: workspaceContext,
          activeBranchId: hasActiveBranchContext ? activeBranchId : null,
          allowWithoutWorkspaceContext: true,
          requireActiveBranchId:
              hasActiveBranchContext ||
              hasWorkspaceContext ||
              authState.requiresBranchSelection,
        );
        if (branchGuardRedirect != null) return branchGuardRedirect;
      }

      if (isPathInGroup(path, AppRoute.adminMenu.path) && !isAdminOrOwner) {
        return '/404';
      }

      // Authenticated but not allowed to access policy → 404
      if (isPathInGroup(path, AppRoute.policy.path) && !isAdminOrOwner) {
        return '/404';
      }
      if (isPathInGroup(path, AppRoute.inventory.path) && !isAdminOrOwner) {
        return '/404';
      }
      if (isPathInGroup(path, AppRoute.staff.path) && !isAdminOrOwner) {
        return '/404';
      }
      // Portal routes removed; role gating handled per feature.

      // Authenticated but not allowed to access cashier dashboard → 404
      if (isPathInGroup(path, AppRoute.cashSession.path) &&
          !isCashier &&
          !isManager &&
          !isAdminOrOwner) {
        return '/404';
      }
      if (isPathInGroup(path, AppRoute.attendance.path) &&
          !isCashier &&
          !isManager) {
        return '/404';
      }
      if (path == AppRoute.xReport.path && !isAdminOrOwner && !isCashier) {
        return '/404';
      }
      if (path == AppRoute.zReport.path && !isAdminOrOwner) {
        return '/404';
      }
      if (path == AppRoute.attendanceManagement.path && !isAdminOrOwner) {
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
        builder: (context, state, child) =>
            AppScaffoldShell(currentPath: state.uri.path, child: child),
        routes: [
          buildPortalRoute(ref),
          ...buildMenuRoutes(),
          ...buildPolicyRoutes(),
          ...buildAccountRoutes(),
          ...buildAttendanceRoutes(),
          ...buildBranchRoutes(),
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
