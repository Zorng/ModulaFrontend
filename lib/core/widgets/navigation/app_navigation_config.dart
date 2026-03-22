import 'package:flutter/material.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/routing/workspace_route_guard.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';

enum AppNavigationScope { tenant, branch }

enum AppNavigationLayer { tenant, branch }

class AppNavigationDestination {
  const AppNavigationDestination({
    required this.label,
    required this.icon,
    required this.route,
    required this.scope,
  });

  final String label;
  final IconData icon;
  final AppRoute route;
  final AppNavigationScope scope;

  bool get requiresBranchContext => scope == AppNavigationScope.branch;
}

class AppNavigationSection {
  const AppNavigationSection({required this.label, required this.destinations});

  final String label;
  final List<AppNavigationDestination> destinations;
}

List<AppNavigationSection> buildAppNavigationSections({
  required AuthRole role,
  required AppNavigationLayer layer,
}) {
  switch ((role, layer)) {
    case (AuthRole.owner || AuthRole.admin, AppNavigationLayer.tenant):
      return const [
        AppNavigationSection(
          label: 'Tenant',
          destinations: [
            AppNavigationDestination(
              label: 'Branches',
              icon: Icons.store_mall_directory_outlined,
              route: AppRoute.branch,
              scope: AppNavigationScope.tenant,
            ),
            AppNavigationDestination(
              label: 'Menu',
              icon: Icons.fastfood_outlined,
              route: AppRoute.adminMenu,
              scope: AppNavigationScope.tenant,
            ),
            AppNavigationDestination(
              label: 'Inventory',
              icon: Icons.inventory_2_outlined,
              route: AppRoute.inventory,
              scope: AppNavigationScope.tenant,
            ),
            AppNavigationDestination(
              label: 'Staff',
              icon: Icons.group_outlined,
              route: AppRoute.staff,
              scope: AppNavigationScope.tenant,
            ),
            AppNavigationDestination(
              label: 'Discounts',
              icon: Icons.percent_outlined,
              route: AppRoute.discount,
              scope: AppNavigationScope.tenant,
            ),
            AppNavigationDestination(
              label: 'Reports',
              icon: Icons.analytics_outlined,
              route: AppRoute.reporting,
              scope: AppNavigationScope.tenant,
            ),
          ],
        ),
      ];
    case (AuthRole.owner || AuthRole.admin, AppNavigationLayer.branch):
      return const [
        AppNavigationSection(
          label: 'Branch',
          destinations: [
            AppNavigationDestination(
              label: 'Cash Sessions',
              icon: Icons.attach_money_outlined,
              route: AppRoute.cashSession,
              scope: AppNavigationScope.branch,
            ),
            AppNavigationDestination(
              label: 'Policy',
              icon: Icons.policy_outlined,
              route: AppRoute.policy,
              scope: AppNavigationScope.branch,
            ),
            AppNavigationDestination(
              label: 'Sale',
              icon: Icons.point_of_sale,
              route: AppRoute.sale,
              scope: AppNavigationScope.branch,
            ),
          ],
        ),
      ];
    case (AuthRole.manager, AppNavigationLayer.tenant):
      return const [
        AppNavigationSection(
          label: 'Tenant',
          destinations: [
            AppNavigationDestination(
              label: 'Reports',
              icon: Icons.analytics_outlined,
              route: AppRoute.reporting,
              scope: AppNavigationScope.tenant,
            ),
          ],
        ),
      ];
    case (_, AppNavigationLayer.branch):
      return [
        AppNavigationSection(
          label: 'Operations',
          destinations: [
            const AppNavigationDestination(
              label: 'Cash Sessions',
              icon: Icons.attach_money_outlined,
              route: AppRoute.cashSession,
              scope: AppNavigationScope.branch,
            ),
            const AppNavigationDestination(
              label: 'Sale',
              icon: Icons.point_of_sale,
              route: AppRoute.sale,
              scope: AppNavigationScope.branch,
            ),
            const AppNavigationDestination(
              label: 'Attendance',
              icon: Icons.access_time_outlined,
              route: AppRoute.attendance,
              scope: AppNavigationScope.branch,
            ),
            if (role == AuthRole.manager)
              const AppNavigationDestination(
                label: 'Attendance Management',
                icon: Icons.fact_check_outlined,
                route: AppRoute.attendanceManagement,
                scope: AppNavigationScope.branch,
              ),
          ],
        ),
      ];
    case (_, AppNavigationLayer.tenant):
      return const [];
  }
}

bool appNavigationDestinationMatchesPath(
  String path,
  AppNavigationDestination destination,
) {
  return isPathInGroup(path, destination.route.path);
}
