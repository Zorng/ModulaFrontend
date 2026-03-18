import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/features/inventory/ui/components/category_form.dart';
import 'package:modular_pos/features/inventory/ui/view/category_management/widgets/inventory_category_actions.dart';
import 'package:modular_pos/features/inventory/ui/view/category_management/widgets/inventory_category_tile.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/core/routing/app_router.dart';

class CategoryManagementPage extends ConsumerStatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  ConsumerState<CategoryManagementPage> createState() =>
      _CategoryManagementPageState();
}

class _CategoryManagementPageState
    extends ConsumerState<CategoryManagementPage> {
  final _searchController = TextEditingController();
  _CategoryStatusFilter _statusFilter = _CategoryStatusFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(categoryControllerProvider.notifier)
          .loadCategories(status: _statusApiValue(_statusFilter));
      ref.read(stockInventoryControllerProvider.notifier).loadStockItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryControllerProvider);
    final stockItems = ref.watch(stockInventoryControllerProvider).stockItems;
    final isWide = !AppBreakpoints.isSmall(MediaQuery.of(context).size.width);
    final isDesktop = AppBreakpoints.isLarge(MediaQuery.of(context).size.width);
    final compactViewButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppTableTheme.actionButtonColor,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    final query = _searchController.text.trim().toLowerCase();
    final categories = state.categories.where((category) {
      if (query.isEmpty) return true;
      return category.name.toLowerCase().contains(query);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    final itemCountByCategory = <String, int>{};
    for (final item in stockItems) {
      final categoryId = item.categoryId;
      if (categoryId == null || categoryId.isEmpty) continue;
      itemCountByCategory.update(
        categoryId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    if (isDesktop) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSearchAddBar(
                  searchHint: 'Search categories',
                  searchController: _searchController,
                  onSearchChanged: (_) => setState(() {}),
                  middleChild: InventoryDropdown<_CategoryStatusFilter>(
                    initialValue: _statusFilter,
                    label: const Text('Status'),
                    entries: const [
                      DropdownMenuEntry(
                        value: _CategoryStatusFilter.all,
                        label: 'All statuses',
                      ),
                      DropdownMenuEntry(
                        value: _CategoryStatusFilter.active,
                        label: 'Active',
                      ),
                      DropdownMenuEntry(
                        value: _CategoryStatusFilter.archived,
                        label: 'Archived',
                      ),
                    ],
                    onSelected: (value) {
                      final selected = value ?? _CategoryStatusFilter.all;
                      setState(() => _statusFilter = selected);
                      ref
                          .read(categoryControllerProvider.notifier)
                          .loadCategories(status: _statusApiValue(selected));
                    },
                  ),
                  onAddPressed: () =>
                      _openCreateCategory(context, useDialog: true),
                  addButtonLabel: 'Add new',
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Archiving a category moves linked stock items to Uncategorized.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDesktopCategoryBody(
                  context: context,
                  state: state,
                  categories: categories,
                  itemCountByCategory: itemCountByCategory,
                  compactViewButtonStyle: compactViewButtonStyle,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchAddBar(
              searchHint: 'Search categories',
              searchController: _searchController,
              onSearchChanged: (_) => setState(() {}),
              middleChild: isWide
                  ? InventoryDropdown<_CategoryStatusFilter>(
                      initialValue: _statusFilter,
                      label: const Text('Status'),
                      entries: const [
                        DropdownMenuEntry(
                          value: _CategoryStatusFilter.all,
                          label: 'All statuses',
                        ),
                        DropdownMenuEntry(
                          value: _CategoryStatusFilter.active,
                          label: 'Active',
                        ),
                        DropdownMenuEntry(
                          value: _CategoryStatusFilter.archived,
                          label: 'Archived',
                        ),
                      ],
                      onSelected: (value) {
                        final selected = value ?? _CategoryStatusFilter.all;
                        setState(() => _statusFilter = selected);
                        ref
                            .read(categoryControllerProvider.notifier)
                            .loadCategories(status: _statusApiValue(selected));
                      },
                    )
                  : null,
              onAddPressed: () =>
                  _openCreateCategory(context, useDialog: isWide),
              addButtonLabel: 'Add new',
            ),
            if (!isWide) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: double.infinity,
                  child: InventoryDropdown<_CategoryStatusFilter>(
                    initialValue: _statusFilter,
                    label: const Text('Status'),
                    entries: const [
                      DropdownMenuEntry(
                        value: _CategoryStatusFilter.all,
                        label: 'All statuses',
                      ),
                      DropdownMenuEntry(
                        value: _CategoryStatusFilter.active,
                        label: 'Active',
                      ),
                      DropdownMenuEntry(
                        value: _CategoryStatusFilter.archived,
                        label: 'Archived',
                      ),
                    ],
                    onSelected: (value) {
                      final selected = value ?? _CategoryStatusFilter.all;
                      setState(() => _statusFilter = selected);
                      ref
                          .read(categoryControllerProvider.notifier)
                          .loadCategories(status: _statusApiValue(selected));
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Archiving a category moves linked stock items to Uncategorized.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null
                    ? Center(
                        child: Text(
                          UserErrorMessage.build(
                            context: 'Failed to load categories',
                            error: state.error,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Theme.of(context).hintColor),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : categories.isEmpty
                    ? Center(
                        child: Text(
                          'No categories yet. Add a category to organize stock items.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final hasNavigationRail = AppBreakpoints.isLarge(
                            MediaQuery.of(context).size.width,
                          );
                          if (!hasNavigationRail) {
                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final stockCount =
                                    itemCountByCategory[category.id] ?? 0;
                                return InventoryCategoryTile(
                                  category: category,
                                  itemCount: stockCount,
                                  onArchived: _reloadCurrentFilter,
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
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              AppTableTheme.headerBackground,
                                            ),
                                        dataRowColor:
                                            const WidgetStatePropertyAll(
                                              AppTableTheme.background,
                                            ),
                                        dividerThickness: AppTableTheme
                                            .dataTableDividerThickness,
                                        border: AppTableTheme.dataTableBorder,
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
                                            final stockCount =
                                                itemCountByCategory[category
                                                    .id] ??
                                                0;
                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    '${index + 1}',
                                                    style:
                                                        AppTableTheme.cellText,
                                                  ),
                                                ),
                                                DataCell(
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        category.name,
                                                        style: AppTableTheme
                                                            .cellText
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      if (category.description !=
                                                              null &&
                                                          category
                                                              .description!
                                                              .isNotEmpty)
                                                        Text(
                                                          category.description!,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                color: Theme.of(
                                                                  context,
                                                                ).hintColor,
                                                              ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    '$stockCount',
                                                    style:
                                                        AppTableTheme.cellText,
                                                  ),
                                                ),
                                                DataCell(
                                                  ElevatedButton(
                                                    style:
                                                        compactViewButtonStyle,
                                                    onPressed: () =>
                                                        InventoryCategoryActionMenu.openView(
                                                          context,
                                                          category,
                                                          useDialog: true,
                                                          onArchived:
                                                              _reloadCurrentFilter,
                                                        ),
                                                    child: const Text('View'),
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
      await context.push(AppRoute.inventoryAddCategory.path);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: CategoryFormBody(
            mode: CategoryFormMode.create,
            showHeader: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  String _statusApiValue(_CategoryStatusFilter filter) {
    return switch (filter) {
      _CategoryStatusFilter.all => 'all',
      _CategoryStatusFilter.active => 'active',
      _CategoryStatusFilter.archived => 'archived',
    };
  }

  void _reloadCurrentFilter() {
    ref
        .read(categoryControllerProvider.notifier)
        .loadCategories(status: _statusApiValue(_statusFilter));
  }

  Widget _buildDesktopCategoryBody({
    required BuildContext context,
    required dynamic state,
    required List<dynamic> categories,
    required Map<String, int> itemCountByCategory,
    required ButtonStyle compactViewButtonStyle,
  }) {
    if (state.isLoading) {
      return const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 96),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.error != null) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 16),
          child: Center(
            child: Text(
              UserErrorMessage.build(
                context: 'Failed to load categories',
                error: state.error,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (categories.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 16),
          child: Center(
            child: Text(
              'No categories yet. Add a category to organize stock items.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
                    dividerThickness: AppTableTheme.dataTableDividerThickness,
                    border: AppTableTheme.dataTableBorder,
                    columns: const [
                      DataColumn(
                        label: Text('No.', style: AppTableTheme.headerText),
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
                        label: Text('Action', style: AppTableTheme.headerText),
                      ),
                    ],
                    rows: List<DataRow>.generate(categories.length, (index) {
                      final category = categories[index];
                      final stockCount = itemCountByCategory[category.id] ?? 0;
                      return DataRow(
                        cells: [
                          DataCell(
                            Text('${index + 1}', style: AppTableTheme.cellText),
                          ),
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: AppTableTheme.cellText.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (category.description != null &&
                                    category.description!.isNotEmpty)
                                  Text(
                                    category.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context).hintColor,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text('$stockCount', style: AppTableTheme.cellText),
                          ),
                          DataCell(
                            ElevatedButton(
                              style: compactViewButtonStyle,
                              onPressed: () =>
                                  InventoryCategoryActionMenu.openView(
                                    context,
                                    category,
                                    useDialog: true,
                                    onArchived: _reloadCurrentFilter,
                                  ),
                              child: const Text('View'),
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
        );
      },
    );
  }
}

enum _CategoryStatusFilter { all, active, archived }
