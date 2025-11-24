import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginControllerProvider);
    final user = state.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user information available.')),
      );
    }

    return PolicyDetailScaffold(
      title: 'Account',
      isEditing: false,
      onEditToggle: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PolicySettingGroup(
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name.characters.first.toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(user.name,
                    style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text(user.role),
              ),
              if (user.phone.isNotEmpty)
                ListTile(
                  title: const Text('Phone'),
                  subtitle: Text(user.phone),
                ),
              if (user.tenantId.isNotEmpty)
                ListTile(
                  title: const Text('Tenant ID'),
                  subtitle: Text(user.tenantId),
                ),
            ],
          ),
          if (user.branches.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Branches', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            PolicySettingGroup(
              children: user.branches
                  .map(
                    (branch) => ListTile(
                      title: Text(branch.name),
                      subtitle: Text(branch.role),
                      trailing:
                          branch.active ? const Icon(Icons.check) : null,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Text('Actions', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          PolicySettingGroup(
            children: const [
              PolicyComingSoonTile(
                title: 'Change password',
                icon: Icons.lock_outline,
              ),
              PolicyComingSoonTile(
                title: 'Change business name',
                icon: Icons.store_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await ref.read(loginControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoute.login.path);
              }
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
