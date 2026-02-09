import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
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
    final useMock = ref.watch(useMockCashSessionProvider);
    final unsavedState = ref.watch(unsavedInputProvider);

    // Listen for mock toggle changes and reset viewmodel to prevent errors
    ref.listen(useMockCashSessionProvider, (previous, next) {
      if (previous != null && previous != next) {
        // Reset viewmodel when switching between mock and API
        ref.invalidate(cashSessionViewModelProvider);
        // Clear any unsaved data
        ref.read(unsavedInputProvider.notifier).clearAll();
        ref.read(startSessionFormProvider.notifier).clear();
        ref.read(cashMovementFormProvider.notifier).clear();
        ref.read(closeSessionFormProvider.notifier).clear();
      }
    });

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
        actions: [
          // Mock/Real toggle button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Tooltip(
              message: useMock
                  ? 'Using Mock Data (for testing)'
                  : 'Using Real API',
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      useMock ? Icons.science : Icons.cloud,
                      size: 16,
                      color: useMock
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      useMock ? 'Mock' : 'API',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: useMock
                            ? Colors.orange.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                selected: useMock,
                onSelected: (selected) {
                  ref.read(useMockCashSessionProvider.notifier).setMock(selected);
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: useMock
                    ? Colors.orange.shade50
                    : Colors.blue.shade50,
                checkmarkColor: useMock
                    ? Colors.orange.shade700
                    : Colors.blue.shade700,
                side: BorderSide(
                  color: useMock
                      ? Colors.orange.shade300
                      : Colors.blue.shade300,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
