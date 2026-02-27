import 'package:flutter/material.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/domain/workspace_context.dart';

enum WorkspaceNavItemType { route, enterPosMode }

class WorkspaceNavItem {
  const WorkspaceNavItem.route({
    required this.label,
    required this.icon,
    required this.route,
  }) : type = WorkspaceNavItemType.route;

  const WorkspaceNavItem.enterPosMode({
    required this.label,
    required this.icon,
  }) : type = WorkspaceNavItemType.enterPosMode,
       route = null;

  final String label;
  final IconData icon;
  final WorkspaceNavItemType type;
  final AppRoute? route;
}

class WorkspaceNavSection {
  const WorkspaceNavSection({required this.label, required this.items});

  final String label;
  final List<WorkspaceNavItem> items;
}

List<WorkspaceNavSection> buildWorkspaceNavSections({
  required AuthRole role,
  required WorkspaceContext? workspaceContext,
}) {
  final isAdminOrOwner = role == AuthRole.admin || role == AuthRole.owner;
  final effectiveContext = _resolveEffectiveContext(
    role: role,
    workspaceContext: workspaceContext,
  );

  if (effectiveContext.isGlobal) {
    return const [
      WorkspaceNavSection(
        label: 'Global Workspace',
        items: [
          WorkspaceNavItem.route(
            label: 'Menu',
            icon: Icons.fastfood_outlined,
            route: AppRoute.adminMenu,
          ),
          WorkspaceNavItem.route(
            label: 'Inventory',
            icon: Icons.inventory_2_outlined,
            route: AppRoute.inventory,
          ),
          WorkspaceNavItem.route(
            label: 'Staff',
            icon: Icons.group_outlined,
            route: AppRoute.staff,
          ),
        ],
      ),
    ];
  }

  if (effectiveContext.isManagement) {
    return const [
      WorkspaceNavSection(
        label: 'Branch Workspace',
        items: [
          WorkspaceNavItem.route(
            label: 'Policy',
            icon: Icons.policy_outlined,
            route: AppRoute.policy,
          ),
          WorkspaceNavItem.route(
            label: 'Branch Subscription',
            icon: Icons.subscriptions_outlined,
            route: AppRoute.branchSubscription,
          ),
          WorkspaceNavItem.enterPosMode(
            label: 'POS Mode',
            icon: Icons.point_of_sale,
          ),
        ],
      ),
    ];
  }

  final posItems = isAdminOrOwner
      ? const [
          WorkspaceNavItem.route(
            label: 'Sale',
            icon: Icons.point_of_sale,
            route: AppRoute.sale,
          ),
          WorkspaceNavItem.route(
            label: 'Cash Sessions',
            icon: Icons.attach_money_outlined,
            route: AppRoute.cashSession,
          ),
        ]
      : const [
          WorkspaceNavItem.route(
            label: 'Sale',
            icon: Icons.point_of_sale,
            route: AppRoute.sale,
          ),
          WorkspaceNavItem.route(
            label: 'Cash Sessions',
            icon: Icons.attach_money_outlined,
            route: AppRoute.cashSession,
          ),
          WorkspaceNavItem.route(
            label: 'Attendance',
            icon: Icons.access_time_outlined,
            route: AppRoute.attendance,
          ),
        ];

  return [WorkspaceNavSection(label: 'POS Workspace', items: posItems)];
}

bool workspaceNavItemMatchesPath(String path, WorkspaceNavItem item) {
  final route = item.route;
  if (route == null) return false;
  final routePath = route.path;
  return path == routePath || path.startsWith('$routePath/');
}

WorkspaceContext _resolveEffectiveContext({
  required AuthRole role,
  required WorkspaceContext? workspaceContext,
}) {
  if (workspaceContext != null) return workspaceContext;
  final isAdminOrOwner = role == AuthRole.admin || role == AuthRole.owner;
  if (isAdminOrOwner) return WorkspaceContext.globalManagement;
  return const WorkspaceContext(
    scope: WorkspaceScope.branch,
    mode: WorkspaceMode.pos,
    activeBranchId: null,
  );
}
