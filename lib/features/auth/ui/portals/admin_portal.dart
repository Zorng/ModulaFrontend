import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/portal_action.dart';
import 'package:modular_pos/core/widgets/navigation/portal_shell.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/auth/ui/portals/admin/widgets/admin_home_content.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

class AdminPortal extends ConsumerWidget {
  const AdminPortal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(loginControllerProvider).session;
    final user = session?.user;
    final activeBranch = ref.watch(authActiveBranchProvider);
    final tenantName = _resolveTenantName(session);
    final branchName = _resolveBranchName(activeBranch, user?.branches ?? const []);
    void openSale() => context.push(AppRoute.sale.path);
    final actions = <PortalAction>[
      PortalAction(
        id: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        builder: (context) =>
            AdminHomeContent(user: user, onOpenSale: openSale),
      ),
    ];

    return PortalShell(
      title: 'Admin Portal',
      subtitle: 'Full access',
      tenantName: tenantName,
      branchName: branchName,
      tenantInitial: tenantName.isNotEmpty
          ? tenantName.characters.first.toUpperCase()
          : 'T',
      actions: actions,
      initialActionId: 'dashboard',
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
