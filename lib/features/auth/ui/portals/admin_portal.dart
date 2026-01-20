import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/portal_action.dart';
import 'package:modular_pos/core/widgets/navigation/portal_shell.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/ui/view/cashier_cash_session.dart';
import 'package:modular_pos/features/cash_session/ui/view/x_report/x_report_page.dart';
import 'package:modular_pos/features/cash_session/ui/view/z_report/z_report_page.dart';
import 'package:modular_pos/features/menu/ui/view/menu/menu_page.dart';
import 'package:modular_pos/features/sale/ui/view/order/order_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_list_view.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_management/attendance_management_page.dart';
import 'package:modular_pos/features/auth/ui/portals/admin/widgets/admin_home_content.dart';
import 'package:modular_pos/features/auth/ui/portals/admin/widgets/portal_placeholder_card.dart';
import 'package:modular_pos/features/auth/ui/portals/admin/widgets/sale_shortcut_card.dart';

class AdminPortal extends ConsumerWidget {
  const AdminPortal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(loginControllerProvider).session;
    final user = session?.user;
    void openSale() => context.push(AppRoute.sale.path);
    final actions = <PortalAction>[
      PortalAction(
        id: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        builder: (context) =>
            AdminHomeContent(user: user, onOpenSale: openSale),
      ),
      PortalAction(
        id: 'menu',
        label: 'Menu',
        icon: Icons.fastfood_outlined,
        builder: (context) => const MenuPage(),
      ),
      PortalAction(
        id: 'inventory',
        label: 'Inventory',
        icon: Icons.inventory_2_outlined,
        builder: (context) => const PortalPlaceholderCard(
          title: 'Inventory',
          content: 'Stock levels, restock, ingredient mapping.',
        ),
      ),
      PortalAction(
        id: 'staff',
        label: 'Staff',
        icon: Icons.group_outlined,
        builder: (context) => const StaffListView(),
      ),
      PortalAction(
        id: 'attendance_management',
        label: 'Attendance Management',
        icon: Icons.access_time_outlined,
        builder: (context) => const AttendanceManagementPage(),
      ),
      PortalAction(
        id: 'sales',
        label: 'POS',
        icon: Icons.point_of_sale,
        onSelected: (_) => openSale(),
        builder: (context) => SaleShortcutCard(onOpenSale: openSale),
      ),
      PortalAction(
        id: 'orders',
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        builder: (context) => const OrderPage(),
      ),
      PortalAction(
        id: 'cash_sessions',
        label: 'Cash Sessions',
        icon: Icons.attach_money_outlined,
        builder: (context) => const CashSessionScreen(),
      ),
      PortalAction(
        id: 'x_report',
        label: 'X Report',
        icon: Icons.description_outlined,
        builder: (context) => const XReportPage(),
      ),
      PortalAction(
        id: 'z_report',
        label: 'Z Report',
        icon: Icons.summarize_outlined,
        builder: (context) => const ZReportPage(),
      ),
      PortalAction(
        id: 'reports',
        label: 'Reports',
        icon: Icons.bar_chart_outlined,
        builder: (context) => const PortalPlaceholderCard(
          title: 'Reports',
          content: 'Sales, inventory, cash, activity logs.',
        ),
      ),
      PortalAction(
        id: 'settings',
        label: 'Settings',
        icon: Icons.settings_outlined,
        builder: (context) => const PortalPlaceholderCard(
          title: 'Settings',
          content: 'Store policies, branches, capabilities.',
        ),
      ),
    ];

    return PortalShell(
      title: 'Admin Portal',
      subtitle: 'Full access',
      userName: user?.name ?? 'Admin',
      userRole: user?.role ?? 'Admin',
      userInitial: user?.name.isNotEmpty == true
          ? user!.name.characters.first.toUpperCase()
          : 'A',
      actions: actions,
      initialActionId: 'dashboard',
      onProfileTap: () => context.push(AppRoute.account.path),
      onSettingsTap: () => context.push(AppRoute.settings.path),
    );
  }
}
