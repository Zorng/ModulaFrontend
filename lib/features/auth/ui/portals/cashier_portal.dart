import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/portal_action.dart';
import 'package:modular_pos/core/widgets/navigation/portal_shell.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/sale/ui/view/order/order_page.dart';
import 'package:modular_pos/features/cash_session/ui/view/cashier_cash_session.dart';
import 'package:modular_pos/features/cash_session/ui/view/x_report_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_list_view.dart';
import 'package:modular_pos/features/policy/ui/view/policy_page.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_page.dart';

class CashierPortal extends ConsumerWidget {
  const CashierPortal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(loginControllerProvider).user;
    void openSale() => context.push(AppRoute.sale.path);
    final actions = <PortalAction>[
      PortalAction(
        id: 'home',
        label: 'Home',
        icon: Icons.home_outlined,
        builder: (context) => const _CashierHomeContent(),
      ),
      PortalAction(
        id: 'pos',
        label: 'POS',
        icon: Icons.point_of_sale,
        onSelected: (_) => openSale(),
        builder: (context) => _SaleShortcutCard(onOpenSale: openSale),
      ),
      PortalAction(
        id: 'cash_sessions',
        label: 'Cash Sessions',
        icon: Icons.attach_money_outlined,
        builder: (context) => const CashSessionScreen(),
      ),
      PortalAction(
        id: 'orders',
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        builder: (context) => const OrderPage(),
      ),
      PortalAction(
        id: 'staff',
        label: 'Staff',
        icon: Icons.group_outlined,
        builder: (context) => const StaffListView(readOnly: true),
      ),
      PortalAction(
        id: 'attendance',
        label: 'Attendance',
        icon: Icons.access_time_outlined,
        builder: (context) => const AttendancePage(),
      ),
      PortalAction(
        id: 'x_report',
        label: 'X Report',
        icon: Icons.description_outlined,
        builder: (context) => const XReportPage(),
      ),
      PortalAction(
        id: 'policy',
        label: 'Policy',
        icon: Icons.policy_outlined,
        builder: (context) => const PolicyPage(),
      ),
    ];

    return PortalShell(
      title: 'Cashier Portal',
      subtitle: 'Cashier role',
      userName: user?.name ?? 'Cashier',
      userRole: user?.role ?? 'Cashier',
      userInitial: user?.name.isNotEmpty == true
          ? user!.name.characters.first.toUpperCase()
          : 'C',
      actions: actions,
      initialActionId: 'home',
      onProfileTap: () => context.push(AppRoute.account.path),
      onSettingsTap: () => context.push(AppRoute.settings.path),
    );
  }
}

class _CashierHomeContent extends ConsumerWidget {
  const _CashierHomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final features = [
      _FeatureEntry(
        title: 'POS / Sales',
        icon: Icons.point_of_sale,
        onTap: () {
          context.push(AppRoute.sale.path);
        },
      ),
      _FeatureEntry(
        title: 'Cash Sessions',
        route: AppRoute.cashierCashSession,
        icon: Icons.attach_money_outlined,
        onTap: () => context.push(AppRoute.cashierCashSession.path),
      ),
      _FeatureEntry(
        title: 'Orders',
        icon: Icons.receipt_long_outlined,
        onTap: () => context.push(AppRoute.orders.path),
      ),
      _FeatureEntry(
        title: 'Attendance',
        icon: Icons.access_time_outlined,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AttendancePage())),
      ),
      _FeatureEntry(
        title: 'X Report',
        icon: Icons.description_outlined,
        onTap: () => context.push(AppRoute.xReport.path),
      ),
      _FeatureEntry(
        title: 'Policy',
        icon: Icons.policy_outlined,
        onTap: () => context.push(AppRoute.policy.path),
      ),
    ];

    const crossAxisCount = 3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isWide ? 1.4 : 1.0,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) => _FeatureCard(entry: features[index]),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.entry});

  final _FeatureEntry entry;

  @override
  Widget build(BuildContext context) {
    final onTap =
        entry.onTap ??
        (entry.route != null ? () => context.push(entry.route!.path) : null);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  entry.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.title,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureEntry {
  const _FeatureEntry({
    required this.title,
    required this.icon,
    this.onTap,
    this.route,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final AppRoute? route;
}

class _SaleShortcutCard extends StatelessWidget {
  const _SaleShortcutCard({required this.onOpenSale});

  final VoidCallback onOpenSale;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('POS / Sale', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Start a draft by adding menu items, then pre-checkout and finalize.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onOpenSale,
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Open Sale'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
