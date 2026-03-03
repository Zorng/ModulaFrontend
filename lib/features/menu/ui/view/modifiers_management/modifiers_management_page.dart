import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/menu/ui/view/modifiers_management/widgets/modifier_group_tile.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A page for managing modifier groups.
class ModifiersManagementPage extends ConsumerStatefulWidget {
  const ModifiersManagementPage({super.key});

  @override
  ConsumerState<ModifiersManagementPage> createState() =>
      _ModifiersManagementPageState();
}

class _ModifiersManagementPageState
    extends ConsumerState<ModifiersManagementPage> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'active';

  static const List<DropdownMenuEntry<String>> _statusFilterEntries = [
    DropdownMenuEntry<String>(value: 'active', label: 'Active'),
    DropdownMenuEntry<String>(value: 'archived', label: 'Archived'),
    DropdownMenuEntry<String>(value: 'all', label: 'All'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(menuViewModelProvider.notifier).refreshModifierGroups(
        status: _selectedStatusFilter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuViewModelProvider);
    final modifierGroups = menuState.modifierGroups
        .where(
          (group) => group.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppSearchAddBar(
              searchHint: 'Search modifiers...',
              onSearchChanged: (value) {
                setState(() => _searchQuery = value);
              },
              onAddPressed: () {
                context.push(AppRoute.adminMenuAddModifierGroup.path);
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: DropdownMenu<String>(
                  initialSelection: _selectedStatusFilter,
                  label: const Text('Status'),
                  dropdownMenuEntries: _statusFilterEntries,
                  onSelected: (value) async {
                    if (value == null || value == _selectedStatusFilter) return;
                    setState(() => _selectedStatusFilter = value);
                    await ref
                        .read(menuViewModelProvider.notifier)
                        .refreshModifierGroups(status: value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: menuState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : modifierGroups.isEmpty
                      ? const Center(child: Text('No modifier groups yet'))
                      : ListView.builder(
                          itemCount: modifierGroups.length,
                          itemBuilder: (context, index) {
                            final group = modifierGroups[index];
                            return ModifierGroupTile(group: group);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
