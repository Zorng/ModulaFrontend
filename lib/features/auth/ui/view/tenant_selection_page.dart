import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

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
                        final tenantLabel = (membership.tenantName.isNotEmpty
                                ? membership.tenantName
                                : membership.tenantId)
                            .trim();

                        return Container(
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ListTile(
                            tileColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            title: Text(
                              tenantLabel.isEmpty ? 'Tenant' : tenantLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: membership.role.trim().isEmpty
                                ? null
                                : Text('Role: ${membership.role.trim().toUpperCase()}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: isLoading
                                ? null
                                : () async {
                                    await controller.selectTenant(membership.tenantId);

                                    final updatedSession =
                                        ref.read(loginControllerProvider).session;
                                    if (updatedSession == null ||
                                        updatedSession.requiresTenantSelection) {
                                      return;
                                    }
                                    final role =
                                        (updatedSession.user.role.isNotEmpty
                                                ? updatedSession.user.role
                                                : 'cashier')
                                            .trim()
                                            .toLowerCase();
                                    final route = switch (role) {
                                      'admin' => AppRoute.adminPortal.path,
                                      'cashier' || 'manager' => AppRoute.cashierPortal.path,
                                      _ => AppRoute.cashierPortal.path,
                                    };

                                    if (context.mounted) context.go(route);
                                  },
                          ),
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
