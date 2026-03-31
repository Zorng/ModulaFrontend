import 'package:flutter/material.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/widgets/layout/app_pagination_bar.dart';
import 'package:modular_pos/core/widgets/display/menu_item_card.dart';
import 'package:modular_pos/core/widgets/media/product_image.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/menu/menu_page_utils.dart';

class MenuPageItemsSection extends StatelessWidget {
  const MenuPageItemsSection({
    super.key,
    required this.isLoading,
    required this.error,
    required this.items,
    required this.categories,
    required this.branches,
    required this.emptyMessage,
    required this.currentPage,
    required this.totalPages,
    required this.visibleRangeStart,
    required this.visibleRangeEnd,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.useDesktopPagination,
    required this.onGoToPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onLoadMore,
    required this.onItemTap,
  });

  final bool isLoading;
  final String? error;
  final List<MenuItem> items;
  final List<MenuCategory> categories;
  final List<MenuBranch> branches;
  final String emptyMessage;
  final int currentPage;
  final int totalPages;
  final int visibleRangeStart;
  final int visibleRangeEnd;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final bool useDesktopPagination;
  final ValueChanged<int> onGoToPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onLoadMore;
  final ValueChanged<MenuItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && items.isEmpty) {
      return Center(
        child: Text(
          UserErrorMessage.build(context: 'Failed to load menu', error: error),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    if (!useDesktopPagination) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final computedCrossAxisCount = (constraints.maxWidth / 160).floor();
          final crossAxisCount = computedCrossAxisCount < 1
              ? 1
              : computedCrossAxisCount;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                  childAspectRatio: 0.75,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final categoryName = resolveCategoryName(
                    categories,
                    item.categoryId,
                  );
                  return MenuItemCard(
                    title: item.name,
                    category: categoryName,
                    price: item.price,
                    imagePath: item.imageUrl,
                    onTap: () => onItemTap(item),
                  );
                },
              ),
              if (hasNextPage)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: FilledButton(
                      onPressed: isLoading ? null : onLoadMore,
                      child: const Text('Load more'),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableContentWidth = constraints.maxWidth < 1120
            ? 1120.0
            : constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableContentWidth,
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
                              'Item Name',
                              style: AppTableTheme.headerText,
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Category',
                              style: AppTableTheme.headerText,
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Based Price',
                              style: AppTableTheme.headerText,
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Assigned Branch(es)',
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
                        rows: List<DataRow>.generate(items.length, (index) {
                          final item = items[index];
                          final categoryName = resolveCategoryName(
                            categories,
                            item.categoryId,
                          );
                          final assignedBranches = _assignedBranchesLabel(item);
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '${visibleRangeStart + index}',
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: ProductImage(
                                        imagePath: item.imageUrl,
                                        borderRadius: 12,
                                        placeholderIconSize: 24,
                                        showPlaceholderLabel: false,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        item.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration:
                                      AppTableTheme.categoryPillDecoration,
                                  child: Text(
                                    categoryName,
                                    style: AppTableTheme.categoryPillText,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '\$ ${item.price.toStringAsFixed(2)}',
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                              DataCell(
                                Text(
                                  assignedBranches,
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                              DataCell(
                                ElevatedButton(
                                  style: AppTableTheme.actionButtonStyle,
                                  onPressed: () => onItemTap(item),
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
            ),
            if (totalPages > 1) ...[
              const SizedBox(height: 16),
              AppPaginationBar(
                rangeLabel:
                    'Showing $visibleRangeStart-$visibleRangeEnd entries',
                currentPage: currentPage,
                totalPages: totalPages,
                canGoPrevious: hasPreviousPage,
                canGoNext: hasNextPage,
                isLoading: isLoading,
                onPageSelected: onGoToPage,
                onPrevious: onPreviousPage,
                onNext: onNextPage,
              ),
            ],
          ],
        );
      },
    );
  }

  String _assignedBranchesLabel(MenuItem item) {
    if (item.branchIds.isEmpty) return '-';
    final nameMap = {for (final branch in branches) branch.id: branch.name};
    final assignedNames = item.branchIds
        .map((id) => nameMap[id])
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    if (assignedNames.isEmpty) {
      return '${item.branchIds.length} branches assigned';
    }
    if (assignedNames.length == 1) return assignedNames.first;
    return '${assignedNames.length} branches assigned';
  }
}
