import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/account_shell_action.dart';
import 'package:modular_pos/core/widgets/navigation/app_navigation_config.dart';
import 'package:modular_pos/core/widgets/sync/global_sync_status_indicator.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/notification/ui/components/operational_notification_inbox_action.dart';

class BranchWorkspaceScaffold extends ConsumerWidget {
  const BranchWorkspaceScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentPath,
    this.actions,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final String? currentPath;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedCurrentPath = currentPath ?? _readCurrentPath(context);

    return Scaffold(
      drawer: BranchWorkspaceDrawer(currentPath: resolvedCurrentPath),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Open workspace drawer',
            onPressed: Scaffold.of(context).openDrawer,
            icon: const Icon(Icons.menu),
          ),
        ),
        title: Text(title),
        actions: <Widget>[
          ...(actions ?? const <Widget>[]),
          if ((actions ?? const <Widget>[]).isNotEmpty)
            const SizedBox(width: 4),
          const OperationalNotificationInboxAction(compact: true),
          const GlobalSyncStatusIndicator(compact: true),
          const AccountShellAction(),
          const SizedBox(width: 4),
        ],
      ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class BranchWorkspaceDrawer extends ConsumerWidget {
  const BranchWorkspaceDrawer({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(loginControllerProvider).session;
    final role = resolveSessionAuthRole(session);
    final sections = buildAppNavigationSections(
      role: role,
      layer: AppNavigationLayer.branch,
    );
    final tenantName = _resolveTenantName(session);
    final activeBranchId = ref.watch(activeBranchContextIdProvider);
    final activeBranchNameOverride = ref.watch(
      authActiveBranchNameOverrideProvider,
    );
    final branchName = _resolveBranchName(
      ref.watch(authActiveBranchProvider),
      session?.user.branches ?? const <UserBranch>[],
      activeBranchId: activeBranchId,
      activeBranchNameOverride: activeBranchNameOverride,
    );

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _DrawerWorkspaceCard(
              tenantName: tenantName,
              branchName: branchName,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(_toTenantTarget(role));
                },
                icon: const Icon(Icons.arrow_back_outlined),
                label: const Text('To tenant'),
              ),
            ),
            const SizedBox(height: 8),
            for (final section in sections) ...[
              if (section.destinations.isNotEmpty) ...[
                _DrawerSectionHeader(label: section.label),
                const SizedBox(height: 4),
              ],
              for (final destination in section.destinations)
                _DrawerDestinationTile(
                  destination: destination,
                  selected: appNavigationDestinationMatchesPath(
                    currentPath,
                    destination,
                  ),
                ),
              const SizedBox(height: 12),
            ],
            const _DrawerSectionHeader(label: 'Devices'),
            const SizedBox(height: 8),
            const _DrawerDevicePlaceholder(),
          ],
        ),
      ),
    );
  }
}

class _DrawerWorkspaceCard extends StatelessWidget {
  const _DrawerWorkspaceCard({
    required this.tenantName,
    required this.branchName,
  });

  final String tenantName;
  final String branchName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workspace',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tenantName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            branchName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  const _DrawerSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DrawerDestinationTile extends StatelessWidget {
  const _DrawerDestinationTile({
    required this.destination,
    required this.selected,
  });

  final AppNavigationDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(destination.icon),
      title: Text(destination.label),
      onTap: () {
        Navigator.of(context).pop();
        if (!selected) {
          context.go(destination.route.path);
        }
      },
    );
  }
}

class _DrawerDevicePlaceholder extends StatelessWidget {
  const _DrawerDevicePlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.print_outlined, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device tools',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Printer/device management is the next branch-scope slice. Printer status stays available in Sale for now.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _toTenantTarget(AuthRole role) {
  if (role == AuthRole.admin || role == AuthRole.owner) {
    return AppRoute.branch.path;
  }
  return '${AppRoute.branchSelection.path}?switch=1';
}

String _resolveTenantName(AuthSession? session) {
  if (session == null || session.memberships.isEmpty) {
    return 'Tenant';
  }
  final activeId = session.activeTenantId;
  final membership = session.memberships.firstWhere(
    (item) => item.tenantId == activeId,
    orElse: () => session.memberships.first,
  );
  final tenantName = membership.tenantName.trim();
  return tenantName.isEmpty ? 'Tenant' : tenantName;
}

String _resolveBranchName(
  UserBranch? active,
  List<UserBranch> branches, {
  required String? activeBranchId,
  required String? activeBranchNameOverride,
}) {
  final overriddenName = (activeBranchNameOverride ?? '').trim();
  if (overriddenName.isNotEmpty) return overriddenName;

  final activeName = active?.name.trim() ?? '';
  if (activeName.isNotEmpty) return activeName;

  final normalizedActiveId = (activeBranchId ?? '').trim();
  if (normalizedActiveId.isNotEmpty) {
    for (final branch in branches) {
      final branchId = branch.branchId.trim().isNotEmpty
          ? branch.branchId.trim()
          : branch.id.trim();
      if (branchId == normalizedActiveId && branch.name.trim().isNotEmpty) {
        return branch.name.trim();
      }
    }
  }

  return 'No branch selected';
}

String _readCurrentPath(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.path;
  } catch (_) {
    return '';
  }
}
