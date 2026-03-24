import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/navigation_layer_back_button.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_workspace_app_bar_actions.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_profile_header.dart';

class PortalShell extends StatelessWidget {
  const PortalShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.tenantName,
    this.branchName,
    this.tenantInitial,
    this.onTenantTap,
    this.onTenantBackPressed,
    this.tenantBackTooltip,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final String? tenantName;
  final String? branchName;
  final String? tenantInitial;
  final VoidCallback? onTenantTap;
  final VoidCallback? onTenantBackPressed;
  final String? tenantBackTooltip;

  @override
  Widget build(BuildContext context) {
    final content = body;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 4,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              if (onTenantBackPressed != null) ...[
                NavigationLayerBackButton(
                  onPressed: onTenantBackPressed!,
                  tooltip: tenantBackTooltip,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TenantProfileHeader(
                    tenantName: tenantName ?? title,
                    branchName: branchName ?? subtitle,
                    initial:
                        tenantInitial ??
                        (tenantName?.characters.first.toUpperCase() ?? '?'),
                    onTap:
                        onTenantTap ??
                        () => context.go(
                          '${AppRoute.tenantSelection.path}?switch=1',
                        ),
                  ),
                ),
              ),
              const Spacer(),
              const TenantWorkspaceAppBarActions(),
            ],
          ),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: content is Scaffold
                ? content
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [const SizedBox(height: 12), content],
                  ),
          ),
        ],
      ),
    );
  }
}
