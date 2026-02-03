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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryControllerProvider);
    final stockItems = ref.watch(stockInventoryControllerProvider).items;
    final isWide = !AppBreakpoints.isSmall(
      MediaQuery.of(context).size.width,
    );
    final query = _searchController.text.trim().toLowerCase();
    final categories = state.categories.where((category) {
      if (query.isEmpty) return true;
      return category.name.toLowerCase().contains(query);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    final itemCountByCategory = <String, int>{};
    for (final item in stockItems) {
      itemCountByCategory.update(
        item.category,
        (value) => value + 1,
        ifAbsent: () => 1,
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
              onAddPressed: () =>
                  _openCreateCategory(context, useDialog: isWide),
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
                          'No categories found',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = !AppBreakpoints.isSmall(
                            constraints.maxWidth,
                          );
                          if (!isWide) {
                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final stockCount =
                                    itemCountByCategory[category.name] ?? 0;
                                return InventoryCategoryTile(
                                  category: category,
                                  itemCount: stockCount,
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
                              child: Container(
                                color: AppTableTheme.background,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 24,
                                ),
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    dataRowMinHeight: 60,
                                    dataRowMaxHeight: 70,
                                    headingRowColor: WidgetStateProperty.all(
                                      AppTableTheme.headerBackground,
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
                                          'Status',
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
                                        final isActive = category.isActive;
                                        final stockCount =
                                            itemCountByCategory[
                                                  category.name
                                                ] ??
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
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    category.name,
                                                    style: AppTableTheme.cellText
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  if (category.description !=
                                                          null &&
                                                      category.description!
                                                          .isNotEmpty)
                                                    Text(
                                                      category.description!,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                                style: AppTableTheme.cellText,
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: isActive
                                                    ? AppTableTheme
                                                        .healthyDecoration
                                                    : AppTableTheme
                                                        .dangerDecoration,
                                                child: Text(
                                                  isActive
                                                      ? 'Active'
                                                      : 'Inactive',
                                                  style: isActive
                                                      ? AppTableTheme
                                                          .healthyText
                                                      : AppTableTheme
                                                          .dangerText,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              InventoryCategoryActionMenu(
                                                category: category,
                                                compact: false,
                                                useDialog: true,
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: CategoryFormBody(
            mode: CategoryFormMode.create,
            showHeader: true,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
