import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/tenant/ui/view/tenant_selection/widgets/create_tenant.dart';
import 'package:modular_pos/features/tenant/ui/view/tenant_selection/widgets/tenant_selection_tile.dart';
import 'package:modular_pos/features/tenant/ui/viewmodels/tenant_selection/tenant_selection_controller.dart';

class TenantSelectionPage extends ConsumerWidget {
  const TenantSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginControllerProvider);
    final tenantState = ref.watch(tenantSelectionControllerProvider);
    final tenantController = ref.read(
      tenantSelectionControllerProvider.notifier,
    );
    final loginController = ref.read(loginControllerProvider.notifier);
    final user = loginState.user;
    final hasMemberships = tenantState.memberships.isNotEmpty;
    final hasVisibleMemberships = tenantState.visibleMemberships.isNotEmpty;

    Future<void> handleLogout() async {
      await loginController.logout();
      if (!context.mounted) return;
      context.go(AppRoute.login.path);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 12,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                _initialFromUserName(user?.name),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                (user?.name ?? '').trim().isEmpty
                    ? 'Account'
                    : user!.name.trim(),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Inbox',
            onPressed: () {},
            icon: const Icon(Icons.inbox_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: loginState.isLoading ? null : handleLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = AppBreakpoints.isSmall(constraints.maxWidth);
                final searchField = TextFormField(
                  initialValue: tenantState.searchQuery,
                  onChanged: tenantController.setSearchQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search tenant',
                    prefixIcon: Icon(Icons.search),
                  ),
                );
                final createButton = FilledButton.icon(
                  onPressed: loginState.isLoading
                      ? null
                      : () {
                          tenantController.clearCreateTenantFeedback();
                          showCreateTenantDialog(context);
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Tenant'),
                );

                if (isSmall) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: 12),
                      createButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 12),
                    SizedBox(width: 170, child: createButton),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (loginState.error != null && loginState.error!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  loginState.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            Expanded(
              child: !hasMemberships
                  ? const Center(
                      child: Text(
                        'No tenant memberships found. Create a tenant to continue.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : !hasVisibleMemberships
                  ? const Center(
                      child: Text(
                        'No tenant matches your search.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: tenantState.visibleMemberships.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final membership =
                            tenantState.visibleMemberships[index];
                        return TenantSelectionTile(
                          membership: membership,
                          enabled: !loginState.isLoading,
                          onTap: () async {
                            final success = await loginController.selectTenant(
                              membership.tenantId,
                            );
                            if (!success) return;
                            if (!context.mounted) return;
                            final nextState = ref.read(loginControllerProvider);
                            final nextSession = nextState.session;
                            final nextRole = resolveSessionAuthRole(
                              nextSession,
                            );
                            final route = nextState.requiresBranchSelection
                                ? AppRoute.branchSelection.path
                                : (nextRole == AuthRole.admin ||
                                      nextRole == AuthRole.owner)
                                ? AppRoute.portal.path
                                : AppRoute.cashSession.path;
                            context.go(route);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initialFromUserName(String? name) {
  final normalized = (name ?? '').trim();
  if (normalized.isEmpty) return '?';
  return normalized.substring(0, 1).toUpperCase();
}
