import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_profile_header.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/domain/workspace_context_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/core/widgets/navigation/workspace_nav_config.dart';

class AppScaffoldShell extends ConsumerWidget {
  const AppScaffoldShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  final Widget child;
  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = AppBreakpoints.isLarge(constraints.maxWidth);
        if (!isWide) return child;

        final session = ref.watch(loginControllerProvider).session;
        final role = resolveSessionAuthRole(session);
        final workspaceContext = ref.watch(workspaceContextProvider);
        final tenantName = _resolveTenantName(session);
        final branchName = workspaceContext?.isGlobal == true
            ? 'Global Management'
            : _resolveBranchName(
                ref.watch(authActiveBranchProvider),
                session?.user.branches ?? const <UserBranch>[],
              );
        final tenantInitial = tenantName.isNotEmpty
            ? tenantName.characters.first.toUpperCase()
            : '?';
        final sections = buildWorkspaceNavSections(
          role: role,
          workspaceContext: workspaceContext,
        );
        final hasMatch = _hasMatch(currentPath, sections);

        return SafeArea(
          child: Row(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: SizedBox(
                  width: 260,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _RailHeader(
                        tenantName: tenantName,
                        branchName: branchName,
                        tenantInitial: tenantInitial,
                      ),
                      const SizedBox(height: 16),
                      for (final section in sections) ...[
                        if (section.items.isNotEmpty)
                          _RailSectionHeader(label: section.label),
                        for (final item in section.items)
                          _RailDestinationTile(
                            item: item,
                            selected:
                                workspaceNavItemMatchesPath(
                                  currentPath,
                                  item,
                                ) ||
                                (!hasMatch && item.route == AppRoute.sale),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

bool _hasMatch(String path, List<WorkspaceNavSection> sections) {
  for (final section in sections) {
    for (final item in section.items) {
      if (workspaceNavItemMatchesPath(path, item)) return true;
    }
  }
  return false;
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
  final branch =
      active ??
      (branches.isNotEmpty
          ? branches.first
          : const UserBranch(id: '', name: '', role: '', active: false));
  if (branch.name.isNotEmpty) return branch.name;
  return 'Branch name';
}

class _RailHeader extends ConsumerWidget {
  const _RailHeader({
    required this.tenantName,
    required this.branchName,
    required this.tenantInitial,
  });

  final String tenantName;
  final String branchName;
  final String tenantInitial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TenantProfileHeader(
          tenantName: tenantName,
          branchName: branchName,
          initial: tenantInitial,
        ),
      ],
    );
  }
}

class _RailSectionHeader extends StatelessWidget {
  const _RailSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _RailDestinationTile extends ConsumerWidget {
  const _RailDestinationTile({required this.item, required this.selected});

  final WorkspaceNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : theme.iconTheme.color;
    final onTap = switch (item.type) {
      WorkspaceNavItemType.route =>
        selected || item.route == null
            ? null
            : () => context.go(item.route!.path),
      WorkspaceNavItemType.enterPosMode => () {
        final branchId = ref.read(activeBranchContextIdProvider);
        if (branchId == null || branchId.trim().isEmpty) return;
        ref
            .read(workspaceContextProvider.notifier)
            .setBranchPos(activeBranchId: branchId);
        context.go(AppRoute.sale.path);
      },
    };
    return ListTile(
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      leading: Icon(item.icon, color: color),
      title: Text(item.label),
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
