import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/auth/ui/view/tenant_selection/widgets/tenant_selection_tile.dart';

class TenantSelectionPage extends ConsumerWidget {
  const TenantSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginControllerProvider);
    final session = loginState.session;
    final controller = ref.read(loginControllerProvider.notifier);

    final memberships = session?.memberships ?? const [];
    final isLoading = loginState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Tenant'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await controller.logout();
              if (context.mounted) context.go(AppRoute.login.path);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose which workspace you want to enter.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: memberships.isEmpty
                  ? const Center(
                      child: Text(
                        'No tenant memberships found.',
                        style: TextStyle(fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      itemCount: memberships.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final membership = memberships[index];
                        return TenantSelectionTile(
                          tenantName: membership.tenantName,
                          tenantId: membership.tenantId,
                          role: membership.role,
                          enabled: !isLoading,
                          onTap: () async {
                            await controller.selectTenant(membership.tenantId);

                            final updatedSession = ref
                                .read(loginControllerProvider)
                                .session;
                            final updatedState = ref.read(
                              loginControllerProvider,
                            );
                            if (updatedSession == null ||
                                updatedSession.requiresTenantSelection) {
                              return;
                            }
                            final route = updatedState.requiresBranchSelection
                                ? AppRoute.branchSelection.path
                                : AppRoute.portal.path;

                            if (context.mounted) context.go(route);
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
