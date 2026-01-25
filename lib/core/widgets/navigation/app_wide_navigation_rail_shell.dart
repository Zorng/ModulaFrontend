import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/nav_destinations.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_profile_header.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

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
    final width = MediaQuery.of(context).size.width;
    final isWide = AppBreakpoints.isLarge(width);
    if (!isWide) return child;

    final session = ref.watch(loginControllerProvider).session;
    final role = (session?.user.role ?? 'cashier').trim().toLowerCase();
    final tenantName = _resolveTenantName(session);
    final branchName = _resolveBranchName(
      ref.watch(authActiveBranchProvider),
      session?.user.branches ?? const <UserBranch>[],
    );
    final tenantInitial = tenantName.isNotEmpty
        ? tenantName.characters.first.toUpperCase()
        : '?';
    final branches = session?.user.branches ?? const <UserBranch>[];
    final activeBranch = ref.watch(authActiveBranchProvider);
    final selectedBranchId = _branchKey(activeBranch) ??
        (branches.isNotEmpty ? _branchKey(branches.first) : null);

    final sections = navSectionsForRole(role);
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
                    if (section.destinations.isNotEmpty)
                      _RailSectionHeader(label: section.label),
                    if (section.label == 'Branch')
                      _RailBranchSelector(
                        branches: branches,
                        selectedBranchId: selectedBranchId,
                      ),
                    for (final destination in section.destinations)
                      _RailDestinationTile(
                        destination: destination,
                        selected:
                            _matchesDestination(currentPath, destination) ||
                            (!hasMatch &&
                                destination.path == AppRoute.sale.path),
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
  }
}

bool _matchesDestination(String path, NavDestination destination) {
  return path.startsWith(destination.path);
}

bool _hasMatch(String path, List<NavSection> sections) {
  for (final section in sections) {
    for (final destination in section.destinations) {
      if (_matchesDestination(path, destination)) return true;
    }
  }
  return false;
}

String? _branchKey(UserBranch? branch) {
  if (branch == null) return null;
  if (branch.branchId.isNotEmpty) return branch.branchId;
  if (branch.id.isNotEmpty) return branch.id;
  return null;
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
      (branches.isNotEmpty ? branches.first : const UserBranch(id: '', name: '', role: '', active: false));
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

class _RailBranchSelector extends ConsumerWidget {
  const _RailBranchSelector({
    required this.branches,
    required this.selectedBranchId,
  });

  final List<UserBranch> branches;
  final String? selectedBranchId;

  String _branchKey(UserBranch branch) =>
      branch.branchId.isNotEmpty ? branch.branchId : branch.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (branches.isEmpty) return const SizedBox.shrink();
    final hasMultipleBranches = branches.length > 1;
    final selectedBranch = branches.firstWhere(
      (b) => _branchKey(b) == selectedBranchId,
      orElse: () => branches.first,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: hasMultipleBranches
          ? DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                initialValue: selectedBranchId,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: branches
                    .map(
                      (b) => DropdownMenuItem(
                        value: _branchKey(b),
                        child: Text(b.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  ref
                      .read(authActiveBranchOverrideProvider.notifier)
                      .setOverride(value);
                },
              ),
            )
          : Row(
              children: [
                const Icon(Icons.store_mall_directory_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedBranch.name,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
    );
  }
}

class _RailDestinationTile extends StatelessWidget {
  const _RailDestinationTile({
    required this.destination,
    required this.selected,
  });

  final NavDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : theme.iconTheme.color;
    return ListTile(
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      leading: Icon(destination.icon, color: color),
      title: Text(destination.label),
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: selected ? null : () => context.go(destination.path),
    );
  }
}
