import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/menu/ui/view/add_category/add_category_page.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management/widgets/category_tile.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management/widgets/menu_category_action_menu.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A page for managing menu categories.
class CategoriesManagementPage extends ConsumerStatefulWidget {
  const CategoriesManagementPage({super.key});

  @override
  ConsumerState<CategoriesManagementPage> createState() =>
      _CategoriesManagementPageState();
}

class _CategoriesManagementPageState
    extends ConsumerState<CategoriesManagementPage> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'active';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(menuViewModelProvider.notifier).refreshCategories(
        status: _selectedStatus,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuViewModelProvider);
    final isWide = AppBreakpoints.isLarge(MediaQuery.of(context).size.width);
    const statusOptions = <DropdownMenuEntry<String>>[
      DropdownMenuEntry<String>(value: 'active', label: 'Active'),
      DropdownMenuEntry<String>(value: 'archived', label: 'Archived'),
    ];
    final query = _searchController.text.trim().toLowerCase();
    final categories = menuState.categories.where((category) {
      final matchesStatus = switch (_selectedStatus) {
        'archived' => !category.isActive,
        _ => category.isActive,
      };
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;
      return category.name.toLowerCase().contains(query);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    final items = menuState.allItems;
    final itemCountByCategory = <String, int>{};
    for (final item in items) {
      itemCountByCategory.update(
        item.categoryId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isWide)
              Row(
                children: [
                  Expanded(
                    child: AppSearchAddBar(
                      searchHint: 'Search categories...',
                      searchController: _searchController,
                      onSearchChanged: (_) => setState(() {}),
                      middleChild: InventoryDropdown<String>(
                        initialValue: _selectedStatus,
                        entries: statusOptions,
                        onSelected: (value) async {
                          if (value == null) return;
                          setState(() => _selectedStatus = value);
                          await ref
                              .read(menuViewModelProvider.notifier)
                              .refreshCategories(status: value);
                        },
                      ),
                      middleMaxWidth: 160,
                      addButtonLabel: 'Add category',
                      onAddPressed: () {
                        _openCreateCategory(context, useDialog: isWide);
                      },
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  AppSearchAddBar(
                    searchHint: 'Search categories...',
                    searchController: _searchController,
                    onSearchChanged: (_) => setState(() {}),
                    addButtonLabel: 'Add category',
                    onAddPressed: () {
                      _openCreateCategory(context, useDialog: isWide);
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: InventoryDropdown<String>(
                      initialValue: _selectedStatus,
                      entries: statusOptions,
                      onSelected: (value) async {
                        if (value == null) return;
                        setState(() => _selectedStatus = value);
                        await ref
                            .read(menuViewModelProvider.notifier)
                            .refreshCategories(status: value);
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Expanded(
              child: menuState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : menuState.error != null
                  ? Center(
                      child: Text(
                        UserErrorMessage.build(
                          context: 'Failed to load categories',
                          error: menuState.error,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : categories.isEmpty
                  ? const Center(child: Text('No categories yet'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (!isWide) {
                          return ListView.builder(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final count =
                                  itemCountByCategory[category.id] ?? 0;
                              return CategoryTile(
                                category: category,
                                itemCount: count,
                                onArchived: _reloadActiveFilter,
                              );
                            },
                          );
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: SingleChildScrollView(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTableTheme.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTableTheme.divider,
                                  ),
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
                                      dataRowColor:
                                          const WidgetStatePropertyAll(
                                            AppTableTheme.background,
                                          ),
                                      dividerThickness: 1,
                                      border: const TableBorder(
                                        horizontalInside: BorderSide(
                                          color: AppTableTheme.divider,
                                        ),
                                      ),
                                      columns: const [
                                        DataColumn(
                                          label: Text(
                                            'No.',
                                            style: AppTableTheme.headerText,
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Category name',
                                            style: AppTableTheme.headerText,
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Item count',
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
                                      rows: List<DataRow>.generate(
                                        categories.length,
                                        (index) {
                                          final category = categories[index];
                                          final count =
                                              itemCountByCategory[category
                                                  .id] ??
                                              0;
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(
                                                  '${index + 1}',
                                                  style: AppTableTheme.cellText,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  category.name,
                                                  style: AppTableTheme.cellText,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  '$count',
                                                  style: AppTableTheme.cellText,
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 96,
                                                  child: ElevatedButton(
                                                    style: AppTableTheme
                                                        .actionButtonStyle,
                                                    onPressed: () =>
                                                        MenuCategoryActionMenu.openView(
                                                          context,
                                                          category,
                                                          useDialog: true,
                                                          onArchived:
                                                              _reloadActiveFilter,
                                                        ),
                                                    child: const Text('View'),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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

  Future<void> _openCreateCategory(
    BuildContext context, {
    required bool useDialog,
  }) async {
    if (!useDialog) {
      await context.push(AppRoute.adminMenuAddCategory.path);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AddCategoryDialogBody(
            showHeader: true,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    );
    if (!mounted) return;
    _reloadCurrentFilter();
  }

  void _reloadCurrentFilter() {
    ref
        .read(menuViewModelProvider.notifier)
        .refreshCategories(status: _selectedStatus);
  }

  void _reloadActiveFilter() {
    setState(() => _selectedStatus = 'active');
    ref
        .read(menuViewModelProvider.notifier)
        .refreshCategories(status: 'active');
  }
}
