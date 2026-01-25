import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/portal_action.dart';
import 'package:modular_pos/core/widgets/navigation/portal_feature_card.dart';
import 'package:modular_pos/core/widgets/navigation/portal_shell.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

class CashierPortal extends ConsumerWidget {
  const CashierPortal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(loginControllerProvider).session;
    final user = session?.user;
    final activeBranch = ref.watch(authActiveBranchProvider);
    final tenantName = _resolveTenantName(session);
    final branchName = _resolveBranchName(activeBranch, user?.branches ?? const []);
    final actions = <PortalAction>[
      PortalAction(
        id: 'home',
        label: 'Home',
        icon: Icons.home_outlined,
        builder: (context) => const _CashierHomeContent(),
      ),
    ];

    return PortalShell(
      title: 'Cashier Portal',
      subtitle: 'Cashier role',
      tenantName: tenantName,
      branchName: branchName,
      tenantInitial: tenantName.isNotEmpty
          ? tenantName.characters.first.toUpperCase()
          : 'T',
      actions: actions,
      initialActionId: 'home',
      onProfileTap: () => context.push(AppRoute.account.path),
      onSettingsTap: () => context.push(AppRoute.settings.path),
    );
  }
}

String _resolveTenantName(AuthSession? session) {
  if (session == null) return 'Tenant name';
  if (session.memberships.isEmpty) return 'Tenant name';
  final activeId = session.activeTenantId;
  final membership = session.memberships.firstWhere(
    (m) => m.tenantId == activeId,
    orElse: () => session.memberships.first,
  );
  if (membership.tenantName.isNotEmpty) return membership.tenantName;
  return 'Tenant name';
}

String _resolveBranchName(UserBranch? active, List<UserBranch> branches) {
  final branch = active ??
      (branches.isNotEmpty
          ? branches.first
          : const UserBranch(id: '', name: '', role: '', active: false));
  if (branch.name.isNotEmpty) return branch.name;
  return 'Branch name';
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
        route: AppRoute.cashSession,
        icon: Icons.attach_money_outlined,
        onTap: () => context.push(AppRoute.cashSession.path),
      ),
      _FeatureEntry(
        title: 'Attendance',
        icon: Icons.access_time_outlined,
        onTap: () => context.push(AppRoute.attendance.path),
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
      _FeatureEntry(
        title: 'Account',
        icon: Icons.person_outline,
        onTap: () => context.push(AppRoute.account.path),
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
        itemBuilder: (context, index) {
          final entry = features[index];
          final onTap =
              entry.onTap ??
              (entry.route != null ? () => context.push(entry.route!.path) : null);
          return PortalFeatureCard(title: entry.title, icon: entry.icon, onTap: onTap);
        },
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
