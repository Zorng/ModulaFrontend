import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/buttons/app_add_new_button.dart';
import 'package:modular_pos/core/widgets/forms/app_category_selector.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/core/widgets/forms/app_search_bar.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';

class MenuPageFilterBar extends StatelessWidget {
  const MenuPageFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.branchOptions,
    required this.selectedBranchId,
    required this.onBranchSelected,
    required this.statusOptions,
    required this.selectedStatus,
    required this.onStatusSelected,
    required this.onSearchChanged,
    required this.onAddPressed,
  });

  final List<MenuCategory> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  final List<DropdownMenuEntry<String>> branchOptions;
  final String selectedBranchId;
  final ValueChanged<String> onBranchSelected;
  final List<DropdownMenuEntry<String>> statusOptions;
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final categoryLabels = categories.map((c) => c.name).toList();
    final selectedLabel = categories
        .firstWhere(
          (c) => c.id == selectedCategoryId,
          orElse: () => categories.first,
        )
        .name;

    return Column(
      children: [
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final hasNavigationRail = AppBreakpoints.isLarge(
              MediaQuery.of(context).size.width,
            );

            if (hasNavigationRail) {
              return Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      hintText: 'Search menu items...',
                      onChanged: onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 220,
                    child: InventoryDropdown<String>(
                      initialValue: selectedBranchId,
                      entries: branchOptions,
                      onSelected: (value) {
                        if (value == null) return;
                        onBranchSelected(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: InventoryDropdown<String>(
                      initialValue: selectedStatus,
                      entries: statusOptions,
                      onSelected: (value) {
                        if (value == null) return;
                        onStatusSelected(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 132,
                    child: AppAddNewButton(
                      onPressed: onAddPressed,
                      label: 'Add menu',
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                AppSearchAddBar(
                  searchHint: 'Search menu items...',
                  addButtonLabel: 'Add menu',
                  onSearchChanged: onSearchChanged,
                  onAddPressed: onAddPressed,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InventoryDropdown<String>(
                        initialValue: selectedBranchId,
                        entries: branchOptions,
                        onSelected: (value) {
                          if (value == null) return;
                          onBranchSelected(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InventoryDropdown<String>(
                        initialValue: selectedStatus,
                        entries: statusOptions,
                        onSelected: (value) {
                          if (value == null) return;
                          onStatusSelected(value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        AppCategorySelector(
          categories: categoryLabels,
          selectedCategory: selectedLabel,
          onCategorySelected: (label) {
            final category = categories.firstWhere((c) => c.name == label);
            onCategorySelected(category.id);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
