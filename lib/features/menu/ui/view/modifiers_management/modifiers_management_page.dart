import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/buttons/app_add_new_button.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/core/widgets/forms/app_search_bar.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
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
          (group) =>
              group.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
    final hasNavigationRail = AppBreakpoints.isLarge(
      MediaQuery.of(context).size.width,
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (hasNavigationRail)
              Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      hintText: 'Search modifiers...',
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 180,
                    child: InventoryDropdown<String>(
                      initialValue: _selectedStatusFilter,
                      entries: _statusFilterEntries,
                      onSelected: (value) async {
                        if (value == null || value == _selectedStatusFilter) {
                          return;
                        }
                        setState(() => _selectedStatusFilter = value);
                        await ref
                            .read(menuViewModelProvider.notifier)
                            .refreshModifierGroups(status: value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 150,
                    child: AppAddNewButton(
                      onPressed: () {
                        context.push(AppRoute.adminMenuAddModifierGroup.path);
                      },
                      label: 'Add new',
                    ),
                  ),
                ],
              )
            else ...[
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
              SizedBox(
                width: double.infinity,
                child: InventoryDropdown<String>(
                  initialValue: _selectedStatusFilter,
                  entries: _statusFilterEntries,
                  onSelected: (value) async {
                    if (value == null || value == _selectedStatusFilter) {
                      return;
                    }
                    setState(() => _selectedStatusFilter = value);
                    await ref
                        .read(menuViewModelProvider.notifier)
                        .refreshModifierGroups(status: value);
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: menuState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : modifierGroups.isEmpty
                      ? const Center(child: Text('No modifier groups yet'))
                      : hasNavigationRail
                      ? _ModifierGroupsTable(groups: modifierGroups)
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

class _ModifierGroupsTable extends StatelessWidget {
  const _ModifierGroupsTable({required this.groups});

  final List<ModifierGroup> groups;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTableTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTableTheme.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: DataTable(
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 70,
                      headingRowColor: WidgetStateProperty.all(
                        AppTableTheme.headerBackground,
                      ),
                      dataRowColor: const WidgetStatePropertyAll(
                        AppTableTheme.background,
                      ),
                      dividerThickness: 1,
                      border: const TableBorder(),
                      columns: const [
                        DataColumn(
                          label: Text('No.', style: AppTableTheme.headerText),
                        ),
                        DataColumn(
                          label: Text(
                            'Modifier name',
                            style: AppTableTheme.headerText,
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Number of options',
                            style: AppTableTheme.headerText,
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Action',
                            style: AppTableTheme.headerText,
                          ),
                        ),
                      ],
                      rows: List<DataRow>.generate(groups.length, (index) {
                        final group = groups[index];
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '${index + 1}',
                                style: AppTableTheme.cellText,
                              ),
                            ),
                            DataCell(
                              Text(group.name, style: AppTableTheme.cellText),
                            ),
                            DataCell(
                              Text(
                                '${group.options.length}',
                                style: AppTableTheme.cellText,
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 96,
                                child: ElevatedButton(
                                  style: AppTableTheme.actionButtonStyle,
                                  onPressed: () {
                                    context.push(
                                      AppRoute.adminMenuViewModifierGroup.path,
                                      extra: group,
                                    );
                                  },
                                  child: const Text('View'),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
