import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/forms/app_category_selector.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
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
    required this.onSearchChanged,
    required this.onAddPressed,
  });

  final List<MenuCategory> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  final List<DropdownMenuEntry<String>> branchOptions;
  final String selectedBranchId;
  final ValueChanged<String> onBranchSelected;

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
        AppSearchAddBar(
          searchHint: 'Search menu items...',
          onSearchChanged: onSearchChanged,
          onAddPressed: onAddPressed,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: DropdownMenu<String>(
            width: double.infinity,
            initialSelection: selectedBranchId,
            leadingIcon: const Icon(Icons.store_outlined),
            label: const Text('Branch'),
            dropdownMenuEntries: branchOptions,
            onSelected: (value) {
              if (value == null) return;
              onBranchSelected(value);
            },
          ),
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
