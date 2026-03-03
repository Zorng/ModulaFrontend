import 'package:flutter/material.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}

class NavSection {
  const NavSection({required this.label, required this.destinations});

  final String label;
  final List<NavDestination> destinations;
}

List<NavSection> navSectionsForRole(String role) {
  if (isAdminOrOwnerRole(role)) {
    return [
      NavSection(
        label: 'Global',
        destinations: [
          NavDestination(
            label: 'Branches',
            icon: Icons.store_mall_directory_outlined,
            path: AppRoute.branch.path,
          ),
          NavDestination(
            label: 'Menu',
            icon: Icons.fastfood_outlined,
            path: AppRoute.adminMenu.path,
          ),
          NavDestination(
            label: 'Inventory',
            icon: Icons.inventory_2_outlined,
            path: AppRoute.inventory.path,
          ),
          NavDestination(
            label: 'Staff',
            icon: Icons.group_outlined,
            path: AppRoute.staff.path,
          ),
          NavDestination(
            label: 'Policy',
            icon: Icons.policy_outlined,
            path: AppRoute.policy.path,
          ),
        ],
      ),
      NavSection(
        label: 'Branch',
        destinations: [
          NavDestination(
            label: 'Sale',
            icon: Icons.point_of_sale,
            path: AppRoute.sale.path,
          ),
          NavDestination(
            label: 'Cash Sessions',
            icon: Icons.attach_money_outlined,
            path: AppRoute.cashSession.path,
          ),
          NavDestination(
            label: 'X Report',
            icon: Icons.description_outlined,
            path: AppRoute.xReport.path,
          ),
          NavDestination(
            label: 'Z Report',
            icon: Icons.summarize_outlined,
            path: AppRoute.zReport.path,
          ),
        ],
      ),
      NavSection(
        label: 'User',
        destinations: [
          NavDestination(
            label: 'Account',
            icon: Icons.person_outline,
            path: AppRoute.account.path,
          ),
          NavDestination(
            label: 'Settings',
            icon: Icons.settings_outlined,
            path: AppRoute.settings.path,
          ),
        ],
      ),
    ];
  }

  return [
    NavSection(
      label: 'Global',
      destinations: [
        NavDestination(
          label: 'Policy',
          icon: Icons.policy_outlined,
          path: AppRoute.policy.path,
        ),
      ],
    ),
    NavSection(
      label: 'Branch',
      destinations: [
        NavDestination(
          label: 'Sale',
          icon: Icons.point_of_sale,
          path: AppRoute.sale.path,
        ),
        NavDestination(
          label: 'Cash Sessions',
          icon: Icons.attach_money_outlined,
          path: AppRoute.cashSession.path,
        ),
        NavDestination(
          label: 'Attendance',
          icon: Icons.access_time_outlined,
          path: AppRoute.attendance.path,
        ),
        NavDestination(
          label: 'X Report',
          icon: Icons.description_outlined,
          path: AppRoute.xReport.path,
        ),
      ],
    ),
    NavSection(
      label: 'User',
      destinations: [
        NavDestination(
          label: 'Account',
          icon: Icons.person_outline,
          path: AppRoute.account.path,
        ),
        NavDestination(
          label: 'Settings',
          icon: Icons.settings_outlined,
          path: AppRoute.settings.path,
        ),
      ],
    ),
  ];
}
