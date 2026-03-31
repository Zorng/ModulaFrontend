import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/auth/ui/view/account/widgets/account_membership_list.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/auth/ui/view/account/widgets/account_action_tiles.dart';
import 'package:modular_pos/features/auth/ui/view/account/widgets/account_branch_list.dart';
import 'package:modular_pos/features/auth/ui/view/account/widgets/account_user_tile.dart';

enum AccountPagePresentation { page, dialog }

class AccountPage extends ConsumerWidget {
  const AccountPage({
    super.key,
    this.presentation = AccountPagePresentation.page,
  });

  final AccountPagePresentation presentation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginControllerProvider);
    final session = state.session;
    final user = state.user;

    if (user == null) {
      return _AccountFrame(
        presentation: presentation,
        child: const Center(child: Text('No user information available.')),
      );
    }

    return _AccountFrame(
      presentation: presentation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccountUserTile(user: user),
            if ((session?.memberships ?? const []).isNotEmpty)
              AccountMembershipList(
                memberships: session!.memberships,
                activeTenantId: session.activeTenantId,
              )
            else if (user.branches.isNotEmpty)
              AccountBranchList(branches: user.branches),
            AccountActionTiles(
              onSettingsTap: () {
                final router = GoRouter.of(context);
                if (presentation == AccountPagePresentation.dialog) {
                  Navigator.of(context).pop();
                }
                router.push(AppRoute.settings.path);
              },
              onLogoutTap: () async {
                final router = GoRouter.of(context);
                if (presentation == AccountPagePresentation.dialog) {
                  Navigator.of(context).pop();
                }
                await ref.read(loginControllerProvider.notifier).logout();
                router.go(AppRoute.login.path);
              },
              logoutEnabled: !state.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showAccountDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
          child: const AccountPage(
            presentation: AccountPagePresentation.dialog,
          ),
        ),
      );
    },
  );
}

class _AccountFrame extends StatelessWidget {
  const _AccountFrame({required this.presentation, required this.child});

  final AccountPagePresentation presentation;
  final Widget child;

  bool get _isDialog => presentation == AccountPagePresentation.dialog;

  @override
  Widget build(BuildContext context) {
    if (_isDialog) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close account',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Account'),
      ),
      body: SafeArea(child: child),
    );
  }
}
