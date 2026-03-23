import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/routing/workspace_route_guard.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_navigation_config.dart';
import 'package:modular_pos/core/widgets/navigation/navigation_layer_back_button.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_profile_header.dart';
import 'package:modular_pos/core/widgets/sync/global_sync_status_indicator.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/notification/ui/components/operational_notification_inbox_action.dart';

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
    final isBranchLayer = _isBranchScopedPath(currentPath);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = AppBreakpoints.isLarge(constraints.maxWidth);
        if (isBranchLayer || !isWide) {
          return child;
        }

        return Stack(
          children: [
            _buildWideShell(context, ref),
            Positioned.fill(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isWide ? 16 : 12,
                      right: isWide ? 16 : 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        OperationalNotificationInboxAction(compact: true),
                        SizedBox(width: 12),
                        GlobalSyncStatusIndicator(compact: false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWideShell(BuildContext context, WidgetRef ref) {
    final session = ref.watch(loginControllerProvider).session;
    final role = resolveSessionAuthRole(session);
    final isAdminOrOwner = role == AuthRole.admin || role == AuthRole.owner;
    final isBranchLayer = _isBranchScopedPath(currentPath);
    final layer = isBranchLayer
        ? AppNavigationLayer.branch
        : AppNavigationLayer.tenant;
    final sections = buildAppNavigationSections(role: role, layer: layer);
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
    final tenantInitial = tenantName.isNotEmpty
        ? tenantName.characters.first.toUpperCase()
        : '?';
    final hasMatch = _hasMatch(currentPath, sections);
    final defaultRoute = _defaultRoute(
      role: role,
      hasActiveBranchContext: (activeBranchId ?? '').trim().isNotEmpty,
    );
    final showFallbackSelection = _shouldUseFallbackSelection(currentPath);
    final layerBackTarget = _resolveLayerBackTarget(
      role: role,
      currentPath: currentPath,
      isBranchLayer: isBranchLayer,
    );
    final layerBackTooltip = _resolveLayerBackTooltip(
      role: role,
      currentPath: currentPath,
      isBranchLayer: isBranchLayer,
    );

    return SafeArea(
      child: Row(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: SizedBox(
              width: 280,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _RailHeader(
                    tenantName: tenantName,
                    branchName: branchName,
                    tenantInitial: tenantInitial,
                    currentPath: currentPath,
                    allowQuickSwitch: isAdminOrOwner && isBranchLayer,
                    availableBranches: _branchOptions(
                      session?.user.branches ?? const <UserBranch>[],
                    ),
                    onLayerBackPressed: layerBackTarget == null
                        ? null
                        : () => context.go(layerBackTarget),
                    layerBackTooltip: layerBackTooltip,
                  ),
                  const SizedBox(height: 16),
                  for (final section in sections) ...[
                    if (section.destinations.isNotEmpty)
                      _RailSectionHeader(label: section.label),
                    for (final destination in section.destinations)
                      _RailDestinationTile(
                        destination: destination,
                        selected:
                            appNavigationDestinationMatchesPath(
                              currentPath,
                              destination,
                            ) ||
                            (!hasMatch &&
                                showFallbackSelection &&
                                destination.route == defaultRoute),
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

bool _hasMatch(String path, List<AppNavigationSection> sections) {
  for (final section in sections) {
    for (final destination in section.destinations) {
      if (appNavigationDestinationMatchesPath(path, destination)) {
        return true;
      }
    }
  }
  return false;
}

AppRoute _defaultRoute({
  required AuthRole role,
  required bool hasActiveBranchContext,
}) {
  if (role == AuthRole.admin || role == AuthRole.owner) {
    return hasActiveBranchContext ? AppRoute.cashSession : AppRoute.branch;
  }
  return AppRoute.cashSession;
}

bool _shouldUseFallbackSelection(String currentPath) {
  return currentPath != AppRoute.account.path &&
      currentPath != AppRoute.settings.path;
}

String? _resolveLayerBackTarget({
  required AuthRole role,
  required String currentPath,
  required bool isBranchLayer,
}) {
  if (currentPath == AppRoute.account.path ||
      currentPath == AppRoute.settings.path) {
    return null;
  }
  if (role == AuthRole.admin || role == AuthRole.owner) {
    return isBranchLayer
        ? AppRoute.branch.path
        : '${AppRoute.tenantSelection.path}?switch=1';
  }
  return '${AppRoute.branchSelection.path}?switch=1';
}

String? _resolveLayerBackTooltip({
  required AuthRole role,
  required String currentPath,
  required bool isBranchLayer,
}) {
  if (currentPath == AppRoute.account.path ||
      currentPath == AppRoute.settings.path) {
    return null;
  }
  if (role == AuthRole.admin || role == AuthRole.owner) {
    return isBranchLayer ? 'Back to tenant' : 'Back to tenant selection';
  }
  return 'Back to branch selection';
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
      final matchesId =
          branch.branchId.trim() == normalizedActiveId ||
          branch.id.trim() == normalizedActiveId;
      if (matchesId && branch.name.trim().isNotEmpty) {
        return branch.name.trim();
      }
    }
  }

  return 'No branch selected';
}

List<_BranchOption> _branchOptions(List<UserBranch> branches) {
  final seen = <String>{};
  final options = <_BranchOption>[];
  for (final branch in branches) {
    final id = branch.branchId.trim().isNotEmpty
        ? branch.branchId.trim()
        : branch.id.trim();
    final name = branch.name.trim();
    if (id.isEmpty || name.isEmpty || !seen.add(id)) continue;
    options.add(_BranchOption(id: id, name: name));
  }
  return options;
}

class _RailHeader extends ConsumerWidget {
  const _RailHeader({
    required this.tenantName,
    required this.branchName,
    required this.tenantInitial,
    required this.currentPath,
    required this.allowQuickSwitch,
    required this.availableBranches,
    this.onLayerBackPressed,
    this.layerBackTooltip,
  });

  final String tenantName;
  final String branchName;
  final String tenantInitial;
  final String currentPath;
  final bool allowQuickSwitch;
  final List<_BranchOption> availableBranches;
  final VoidCallback? onLayerBackPressed;
  final String? layerBackTooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onLayerBackPressed != null) ...[
              NavigationLayerBackButton(
                onPressed: onLayerBackPressed!,
                tooltip: layerBackTooltip,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: TenantProfileHeader(
                tenantName: tenantName,
                branchName: branchName,
                initial: tenantInitial,
                onTap: () =>
                    context.go('${AppRoute.tenantSelection.path}?switch=1'),
              ),
            ),
          ],
        ),
        if (allowQuickSwitch && availableBranches.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BranchQuickSwitchButton(
            currentPath: currentPath,
            branchName: branchName,
            branches: availableBranches,
          ),
        ],
      ],
    );
  }
}

class _BranchOption {
  const _BranchOption({required this.id, required this.name});

  final String id;
  final String name;
}

class _BranchQuickSwitchButton extends ConsumerWidget {
  const _BranchQuickSwitchButton({
    required this.currentPath,
    required this.branchName,
    required this.branches,
  });

  final String currentPath;
  final String branchName;
  final List<_BranchOption> branches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayLabel = branchName == 'No branch selected'
        ? 'Choose branch'
        : branchName;

    return PopupMenuButton<String>(
      tooltip: 'Switch branch',
      onSelected: (branchId) => _selectBranch(context, ref, branchId),
      itemBuilder: (context) => [
        for (final branch in branches)
          PopupMenuItem<String>(value: branch.id, child: Text(branch.name)),
      ],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.store_mall_directory_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayLabel,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBranch(
    BuildContext context,
    WidgetRef ref,
    String branchId,
  ) async {
    final selectedBranch = branches.firstWhere(
      (branch) => branch.id == branchId,
      orElse: () => const _BranchOption(id: '', name: ''),
    );
    if (selectedBranch.id.isEmpty) return;

    await ref.read(loginControllerProvider.notifier).selectBranch(branchId);
    final loginState = ref.read(loginControllerProvider);
    if (!context.mounted) return;

    if (loginState.error != null && loginState.error!.trim().isNotEmpty) {
      final errorCode = (loginState.errorCode ?? '').trim().toUpperCase();
      if (errorCode == 'TENANT_CONTEXT_REQUIRED') {
        context.go(AppRoute.tenantSelection.path);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loginState.error!)));
      return;
    }

    ref
        .read(authActiveBranchOverrideProvider.notifier)
        .setOverride(selectedBranch.id);
    ref
        .read(authActiveBranchNameOverrideProvider.notifier)
        .setName(selectedBranch.name);

    if (_isBranchScopedPath(currentPath)) {
      context.go(currentPath);
      return;
    }
    if (isPathInGroup(currentPath, AppRoute.branch.path)) {
      context.go(AppRoute.cashSession.path);
    }
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
  const _RailDestinationTile({
    required this.destination,
    required this.selected,
  });

  final AppNavigationDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : theme.iconTheme.color;
    final hasActiveBranchContext =
        (ref.watch(activeBranchContextIdProvider) ?? '').trim().isNotEmpty;
    final role = resolveSessionAuthRole(
      ref.watch(loginControllerProvider.select((state) => state.session)),
    );
    final onTap = selected
        ? null
        : () {
            if (destination.requiresBranchContext && !hasActiveBranchContext) {
              context.go(
                buildBranchScopedRedirectForRole(
                  role: role,
                  continuePath: destination.route.path,
                  reasonCode: branchContextRequiredReasonCode,
                ),
              );
              return;
            }
            context.go(destination.route.path);
          };
    return ListTile(
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      leading: Icon(destination.icon, color: color),
      title: Text(destination.label),
      subtitle: destination.requiresBranchContext && !hasActiveBranchContext
          ? const Text('Select branch')
          : null,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}

bool _isBranchScopedPath(String path) {
  return isPathInGroup(path, AppRoute.branchSubscription.path) ||
      isPathInGroup(path, AppRoute.cashSession.path) ||
      isPathInGroup(path, AppRoute.cashHistory.path) ||
      isPathInGroup(path, AppRoute.policy.path) ||
      isPathInGroup(path, AppRoute.notifications.path) ||
      isPathInGroup(path, AppRoute.branchDiscount.path) ||
      isPathInGroup(path, AppRoute.sale.path) ||
      isPathInGroup(path, AppRoute.attendance.path) ||
      isPathInGroup(path, AppRoute.xReport.path) ||
      isPathInGroup(path, AppRoute.zReport.path) ||
      path == AppRoute.attendanceManagement.path;
}
