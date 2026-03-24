import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';

class AccountShellAction extends StatelessWidget {
  const AccountShellAction({super.key});

  static const actionKey = Key('account_shell_action');

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: actionKey,
      tooltip: 'Account',
      onPressed: () {
        final currentPath = GoRouterState.of(context).uri.path;
        if (currentPath == AppRoute.account.path) return;
        context.push(AppRoute.account.path);
      },
      icon: const Icon(Icons.person_outline),
    );
  }
}
