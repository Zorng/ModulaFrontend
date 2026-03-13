import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/app_navigation_config.dart';
import 'package:modular_pos/core/widgets/navigation/app_navigation_portal_content.dart';
import 'package:modular_pos/core/widgets/navigation/portal_shell.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class AdminPortal extends ConsumerWidget {
  const AdminPortal({super.key, this.layer = AppNavigationLayer.tenant});

  final AppNavigationLayer layer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(loginControllerProvider).session;
    final user = session?.user;
    final activeBranch = ref.watch(authActiveBranchProvider);
    final tenantName = _resolveTenantName(session);
    final branchName = _resolveBranchName(
      activeBranch,
      user?.branches ?? const [],
    );

    return PortalShell(
      title: 'Admin Portal',
      subtitle: 'Full access',
      body: AppNavigationPortalContent(layer: layer),
      tenantName: tenantName,
      branchName: branchName,
      tenantInitial: tenantName.isNotEmpty
          ? tenantName.characters.first.toUpperCase()
          : 'T',
      onTenantBackPressed: layer == AppNavigationLayer.branch
          ? () => context.go(AppRoute.branch.path)
          : () => context.go('${AppRoute.tenantSelection.path}?switch=1'),
      tenantBackTooltip: layer == AppNavigationLayer.branch
          ? 'Back to tenant'
          : 'Back to tenant selection',
      onProfileTap: layer == AppNavigationLayer.branch
          ? () => context.go(AppRoute.account.path)
          : null,
      onSettingsTap: layer == AppNavigationLayer.branch
          ? () => context.go(AppRoute.settings.path)
          : null,
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
  if ((active?.name ?? '').trim().isNotEmpty) return active!.name.trim();
  return 'No branch selected';
}
