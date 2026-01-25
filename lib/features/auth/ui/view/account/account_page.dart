import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';
import 'package:modular_pos/features/auth/ui/view/account/widgets/account_action_tiles.dart';
import 'package:modular_pos/features/auth/ui/view/account/widgets/account_branch_list.dart';
import 'package:modular_pos/features/auth/ui/view/account/widgets/account_user_tile.dart';

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
          AccountUserTile(user: user),
          if (user.branches.isNotEmpty) AccountBranchList(branches: user.branches),
          const AccountActionTiles(),
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
