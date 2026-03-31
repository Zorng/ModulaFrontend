import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/hydration/app_hydration_listener.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/routing/workspace_route_guard.dart';
import 'package:modular_pos/core/routing/routes/account_routes.dart';
import 'package:modular_pos/core/routing/routes/audit_routes.dart';
import 'package:modular_pos/core/routing/routes/attendance_routes.dart';
import 'package:modular_pos/core/routing/routes/branch_routes.dart';
import 'package:modular_pos/core/routing/routes/cash_routes.dart';
import 'package:modular_pos/core/routing/routes/core_routes.dart';
import 'package:modular_pos/core/routing/routes/inventory_routes.dart';
import 'package:modular_pos/core/routing/routes/menu_routes.dart';
import 'package:modular_pos/core/routing/routes/notification_routes.dart';
import 'package:modular_pos/core/routing/routes/policy_routes.dart';
import 'package:modular_pos/core/routing/routes/discount_routes.dart';
import 'package:modular_pos/core/routing/routes/portal_routes.dart';
import 'package:modular_pos/core/routing/routes/reporting_routes.dart';
import 'package:modular_pos/core/routing/routes/sale_routes.dart';
import 'package:modular_pos/core/routing/routes/staff_routes.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_wide_navigation_rail_shell.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
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
      final path = state.uri.path;
      final isWide = _isWide(context);

      final isLoggingIn = path == AppRoute.login.path;
      final isSignup = path == AppRoute.signup.path;
      final isOtpVerification = path == AppRoute.otpVerification.path;
      final isForgotPassword = path == AppRoute.forgotPassword.path;
      final isForgotPasswordConfirm =
          path == AppRoute.forgotPasswordConfirm.path;
      final isTenantSelection = path == AppRoute.tenantSelection.path;
      final isInvitationInbox = path == AppRoute.invitationInbox.path;
      final isNotifications = path == AppRoute.notifications.path;
      final isAudit = path == AppRoute.audit.path;
      final isAccount = path == AppRoute.account.path;
      final isSettings = path == AppRoute.settings.path;
      final isBranchSelection = path == AppRoute.branchSelection.path;
      final isPortal = path == AppRoute.portal.path;
      final isBranchPortal = path == AppRoute.branchPortal.path;
      final isExplicitTenantSwitch = state.uri.queryParameters['switch'] == '1';
      final isExplicitBranchSwitch = state.uri.queryParameters['switch'] == '1';

      if (path == AppRoute.components.path) {
        return null;
      }

      if (session == null) {
        if (isLoggingIn ||
            isSignup ||
            isOtpVerification ||
            isForgotPassword ||
            isForgotPasswordConfirm) {
          return null;
        }
        return AppRoute.login.path;
      }

      if (session.requiresTenantSelection) {
        return (isTenantSelection ||
                isInvitationInbox ||
                isNotifications ||
                isAudit ||
                isAccount ||
                isSettings)
            ? null
            : AppRoute.tenantSelection.path;
      }

      final role = resolveSessionAuthRole(session);
      final isAdminOrOwner = role == AuthRole.admin || role == AuthRole.owner;
      final isCashier = role == AuthRole.cashier;
      final isManager = role == AuthRole.manager;
      final canReadDiscount = isAdminOrOwner || isCashier || isManager;
      final activeBranchId = ref.read(activeBranchContextIdProvider) ?? '';
      final hasActiveBranchContext = activeBranchId.isNotEmpty;
      final currentTarget = state.uri.toString();

      if (authState.requiresBranchSelection) {
        return (isBranchSelection || isTenantSelection)
            ? null
            : AppRoute.branchSelection.path;
      }

      final homePath = _homeForRole(
        role: role,
        isWide: isWide,
        hasActiveBranchContext: hasActiveBranchContext,
      );

      if (isLoggingIn ||
          isSignup ||
          isOtpVerification ||
          isForgotPassword ||
          isForgotPasswordConfirm) {
        return homePath;
      }

      if (isTenantSelection) {
        if (isExplicitTenantSwitch) return null;
        return homePath;
      }

      if (isBranchSelection) {
        if (isAdminOrOwner) {
          return isWide ? AppRoute.branch.path : AppRoute.portal.path;
        }
        if (isExplicitBranchSwitch) return null;
        return hasActiveBranchContext ? AppRoute.cashSession.path : null;
      }

      if (isPortal) {
        if (isWide) return homePath;
        if (!isAdminOrOwner) return homePath;
        return null;
      }

      if (isWide && path == AppRoute.saleCart.path) {
        return AppRoute.sale.path;
      }

      if (isBranchPortal) {
        if (!hasActiveBranchContext) {
          return buildBranchScopedRedirectForRole(
            role: role,
            continuePath: currentTarget,
            reasonCode: branchContextRequiredReasonCode,
          );
        }
        return AppRoute.cashSession.path;
      }

      if (_isTenantAdminRoute(path) && !isAdminOrOwner) {
        return '/404';
      }

      if (_isBranchScopedRoute(path) && !hasActiveBranchContext) {
        return buildBranchScopedRedirectForRole(
          role: role,
          continuePath: currentTarget,
          reasonCode: branchContextRequiredReasonCode,
        );
      }

      if (isPathInGroup(path, AppRoute.policy.path) && !isAdminOrOwner) {
        return '/404';
      }
      if (_isDiscountReadRoute(path) && !canReadDiscount) {
        return '/404';
      }
      if (_isDiscountManageRoute(path) && !isAdminOrOwner) {
        return '/404';
      }
      if (isPathInGroup(path, AppRoute.branchSubscription.path) &&
          !isAdminOrOwner) {
        return '/404';
      }
      if ((isPathInGroup(path, AppRoute.cashSession.path) ||
              isPathInGroup(path, AppRoute.cashHistory.path)) &&
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
      if (isPathInGroup(path, AppRoute.reporting.path) &&
          !isManager &&
          !isAdminOrOwner) {
        return '/404';
      }
      if (path == AppRoute.xReport.path && !isAdminOrOwner && !isCashier) {
        return '/404';
      }
      if (path == AppRoute.zReport.path && !isAdminOrOwner) {
        return '/404';
      }
      if (path == AppRoute.attendanceManagement.path &&
          !isAdminOrOwner &&
          !isManager) {
        return '/404';
      }

      return null;
    },
    initialLocation: AppRoute.login.path,
    routes: [
      ...buildCoreRoutes(),
      ShellRoute(
        builder: (context, state, child) =>
            AppScaffoldShell(currentPath: state.uri.path, child: child),
        routes: [
          ...buildPortalRoutes(ref),
          ...buildNotificationRoutes(),
          ...buildAuditRoutes(),
          ...buildMenuRoutes(),
          ...buildPolicyRoutes(),
          ...buildDiscountRoutes(),
          ...buildAccountRoutes(),
          ...buildAttendanceRoutes(),
          ...buildBranchRoutes(),
          ...buildInventoryRoutes(),
          ...buildSaleRoutes(),
          ...buildReportingRoutes(),
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

bool _isWide(BuildContext context) {
  final mediaQuery = MediaQuery.maybeOf(context);
  if (mediaQuery == null) return false;
  return AppBreakpoints.isLarge(mediaQuery.size.width);
}

String _homeForRole({
  required AuthRole role,
  required bool isWide,
  required bool hasActiveBranchContext,
}) {
  if (role == AuthRole.admin || role == AuthRole.owner) {
    if (isWide) {
      return hasActiveBranchContext
          ? AppRoute.cashSession.path
          : AppRoute.branch.path;
    }
    return AppRoute.portal.path;
  }
  if (!hasActiveBranchContext) {
    return AppRoute.branchSelection.path;
  }
  return AppRoute.cashSession.path;
}

bool _isTenantAdminRoute(String path) {
  if (isPathInGroup(path, AppRoute.attendanceManagement.path)) return false;
  return isPathInGroup(path, AppRoute.branch.path) ||
      isPathInGroup(path, AppRoute.audit.path) ||
      isPathInGroup(path, AppRoute.adminMenu.path) ||
      isPathInGroup(path, AppRoute.inventory.path) ||
      isPathInGroup(path, AppRoute.staff.path);
}

bool _isBranchScopedRoute(String path) {
  return path == AppRoute.branchPortal.path ||
      isPathInGroup(path, AppRoute.branchSubscription.path) ||
      isPathInGroup(path, AppRoute.cashSession.path) ||
      isPathInGroup(path, AppRoute.cashHistory.path) ||
      isPathInGroup(path, AppRoute.policy.path) ||
      isPathInGroup(path, AppRoute.sale.path) ||
      isPathInGroup(path, AppRoute.branchDiscount.path) ||
      isPathInGroup(path, AppRoute.attendance.path) ||
      isPathInGroup(path, AppRoute.xReport.path) ||
      isPathInGroup(path, AppRoute.zReport.path) ||
      path == AppRoute.attendanceManagement.path;
}

bool _isDiscountReadRoute(String path) {
  return isPathInGroup(path, AppRoute.discount.path) &&
      !_isDiscountManageRoute(path);
}

bool _isDiscountManageRoute(String path) {
  return isPathInGroup(path, AppRoute.discountRuleForm.path);
}
