import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/navigation/navigation_layer_back_button.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_workspace_app_bar_actions.dart';

class PortalShell extends StatelessWidget {
  const PortalShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.tenantName,
    this.branchName,
    this.tenantInitial,
    this.onTenantBackPressed,
    this.tenantBackTooltip,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final String? tenantName;
  final String? branchName;
  final String? tenantInitial;
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
        titleSpacing: 12,
        leading: onTenantBackPressed != null
            ? NavigationLayerBackButton(
                onPressed: onTenantBackPressed!,
                tooltip: tenantBackTooltip,
              )
            : null,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        actions: const [TenantWorkspaceAppBarActions()],
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
