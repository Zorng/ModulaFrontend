import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/routing/workspace_route_guard.dart';
import 'package:modular_pos/core/widgets/navigation/app_navigation_config.dart';
import 'package:modular_pos/core/widgets/navigation/portal_feature_card.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class AppNavigationPortalContent extends ConsumerWidget {
  const AppNavigationPortalContent({super.key, required this.layer});

  final AppNavigationLayer layer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = resolveSessionAuthRole(
      ref.watch(loginControllerProvider.select((state) => state.session)),
    );
    final activeBranchId = ref.watch(activeBranchContextIdProvider);
    final hasActiveBranchContext = (activeBranchId ?? '').trim().isNotEmpty;
    final sections = buildAppNavigationSections(role: role, layer: layer);
    final isWide = MediaQuery.of(context).size.width >= 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in sections) ...[
            Text(section.label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 1.4 : 1.0,
              ),
              itemCount: section.destinations.length,
              itemBuilder: (context, index) {
                final destination = section.destinations[index];
                final needsBranch =
                    destination.requiresBranchContext &&
                    !hasActiveBranchContext;
                return PortalFeatureCard(
                  title: destination.label,
                  icon: destination.icon,
                  badgeText: needsBranch ? 'Select branch' : null,
                  onTap: () => _onTap(
                    context,
                    role: role,
                    destination: destination,
                    hasActiveBranchContext: hasActiveBranchContext,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  void _onTap(
    BuildContext context, {
    required AuthRole role,
    required AppNavigationDestination destination,
    required bool hasActiveBranchContext,
  }) {
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
  }
}
