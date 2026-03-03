import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/portal_feature_card.dart';
import 'package:modular_pos/core/widgets/navigation/workspace_nav_config.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/domain/workspace_context_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class WorkspacePortalContent extends ConsumerWidget {
  const WorkspacePortalContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(loginControllerProvider).session;
    final role = resolveSessionAuthRole(session);
    final workspaceContext = ref.watch(workspaceContextProvider);
    final sections = buildWorkspaceNavSections(
      role: role,
      workspaceContext: workspaceContext,
    );
    if (sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: Text('No workspace features available.')),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 800;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          Text(section.label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isWide ? 1.4 : 1.0,
            ),
            itemCount: section.items.length,
            itemBuilder: (context, index) {
              final item = section.items[index];
              return PortalFeatureCard(
                title: item.label,
                icon: item.icon,
                badgeText: item.type == WorkspaceNavItemType.enterPosMode
                    ? 'Mode'
                    : null,
                onTap: () => _onTap(context, ref, item),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, WorkspaceNavItem item) {
    switch (item.type) {
      case WorkspaceNavItemType.route:
        final route = item.route;
        if (route == null) return;
        context.push(route.path);
        return;
      case WorkspaceNavItemType.enterPosMode:
        final branchId = ref.read(activeBranchContextIdProvider);
        if (branchId == null || branchId.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select a branch first.')),
          );
          return;
        }
        ref
            .read(workspaceContextProvider.notifier)
            .setBranchPos(activeBranchId: branchId);
        context.go(AppRoute.sale.path);
        return;
    }
  }
}
