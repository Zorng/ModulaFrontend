import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/portal_action.dart';
import 'package:modular_pos/core/widgets/portal_shell.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class CashierPortal extends ConsumerWidget {
  const CashierPortal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(loginControllerProvider).user;
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
        builder: (context) => const _PlaceholderCard(
          title: 'POS',
          content: 'Sales entry for cashier.',
        ),
      ),
      PortalAction(
        id: 'cash_sessions',
        label: 'Cash Sessions',
        icon: Icons.attach_money_outlined,
        builder: (context) => const _PlaceholderCard(
          title: 'Cash Sessions',
          content: 'Open/close sessions, paid-in/out, reconciliation.',
        ),
      ),
      PortalAction(
        id: 'orders',
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        builder: (context) => const _PlaceholderCard(
          title: 'Orders',
          content: 'Order history and status.',
        ),
      ),
      PortalAction(
        id: 'x_report',
        label: 'X Report',
        icon: Icons.description_outlined,
        builder: (context) => const _PlaceholderCard(
          title: 'X Report',
          content: 'Current shift summary.',
        ),
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

class _CashierHomeContent extends StatelessWidget {
  const _CashierHomeContent();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    const features = [
      _FeatureEntry(title: 'POS / Sales', icon: Icons.point_of_sale),
      _FeatureEntry(
        title: 'Cash Sessions',
        icon: Icons.attach_money_outlined,
      ),
      _FeatureEntry(
        title: 'Orders',
        icon: Icons.receipt_long_outlined,
      ),
      _FeatureEntry(
        title: 'X Report',
        icon: Icons.description_outlined,
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Wire navigation to the specific feature.
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
  });

  final String title;
  final IconData icon;
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
