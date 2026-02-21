import 'package:flutter/material.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/display/menu_item_card.dart';
import 'package:modular_pos/core/widgets/layout/card_container.dart';
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
    required this.onItemTap,
  });

  final bool isLoading;
  final String? error;
  final List<MenuItem> items;
  final List<MenuCategory> categories;
  final List<MenuBranch> branches;
  final ValueChanged<MenuItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
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
          'No menu items match your filters.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final hasNavigationRail = AppBreakpoints.isLarge(
      MediaQuery.of(context).size.width,
    );
    if (!hasNavigationRail) {
      return CardContainer(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final categoryName = resolveCategoryName(categories, item.categoryId);
          return MenuItemCard(
            title: item.name,
            category: categoryName,
            price: item.price,
            imagePath: item.imageUrl,
            onTap: () => onItemTap(item),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(12),
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
                  border: const TableBorder(
                    top: BorderSide(color: AppTableTheme.divider),
                    bottom: BorderSide(color: AppTableTheme.divider),
                    left: BorderSide(color: AppTableTheme.divider),
                    right: BorderSide(color: AppTableTheme.divider),
                  ),
                  columns: const [
                DataColumn(label: Text('No.', style: AppTableTheme.headerText)),
                DataColumn(
                  label: Text('Item Name', style: AppTableTheme.headerText),
                ),
                DataColumn(
                  label: Text('Category', style: AppTableTheme.headerText),
                ),
                DataColumn(
                  label: Text('Based Price', style: AppTableTheme.headerText),
                ),
                DataColumn(
                  label: Text(
                    'Assigned Branch(es)',
                    style: AppTableTheme.headerText,
                  ),
                ),
                DataColumn(label: Text('Status', style: AppTableTheme.headerText)),
                DataColumn(label: Text('Action', style: AppTableTheme.headerText)),
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
                          Text('${index + 1}', style: AppTableTheme.cellText),
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
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                            decoration: AppTableTheme.categoryPillDecoration,
                            child: Text(
                              categoryName,
                              style: AppTableTheme.categoryPillText,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: AppTableTheme.cellText,
                          ),
                        ),
                        DataCell(
                          Text(assignedBranches, style: AppTableTheme.cellText),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: item.isActive
                                ? AppTableTheme.healthyDecoration
                                : AppTableTheme.dangerDecoration,
                            child: Text(
                              item.isActive ? 'Active' : 'Inactive',
                              style: item.isActive
                                  ? AppTableTheme.healthyText
                                  : AppTableTheme.dangerText,
                            ),
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
