import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/unsaved_input_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/modal_form_state_provider.dart';

class CashBottomNavShellPage extends ConsumerWidget {
  const CashBottomNavShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const _titles = <String>[
    'Session',
    'Movement',
    'Report',
  ];

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.attach_money_outlined),
      label: 'Session',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.swap_horiz_outlined),
      label: 'Movement',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.description_outlined),
      label: 'Report',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unsavedState = ref.watch(unsavedInputProvider);

    // Create a navigation guard function
    Future<bool> checkUnsavedData() async {
      if (!unsavedState.hasAnyUnsavedData) return true;

      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved input in your forms. '
            'Are you sure you want to leave? All unsaved data will be lost.',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: AppButtons.secondary(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Leave'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (shouldLeave == true && context.mounted) {
        // Clear all unsaved data
        ref.read(unsavedInputProvider.notifier).clearAll();
        ref.read(startSessionFormProvider.notifier).clear();
        ref.read(cashMovementFormProvider.notifier).clear();
        ref.read(closeSessionFormProvider.notifier).clear();
        return true;
      }
      return false;
    }

    return PopScope(
      canPop: !unsavedState.hasAnyUnsavedData,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        final shouldLeave = await checkUnsavedData();
        if (shouldLeave && context.mounted) {
          context.go(AppRoute.portal.path);
        }
      },
      child: AppBottomNavShellScaffold(
        navigationShell: navigationShell,
        titles: _titles,
        items: _items,
        centerTitle: false,
        onBackPressed: () async {
          final shouldLeave = await checkUnsavedData();
          if (shouldLeave && context.mounted) {
            context.go(AppRoute.portal.path);
          }
        },
        backIcon: Icons.home_outlined,
        backTooltip: 'Home',
        actions: const [],
      ),
    );
  }
}
