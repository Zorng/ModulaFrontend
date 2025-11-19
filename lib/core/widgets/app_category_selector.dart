import 'package:flutter/material.dart';

/// A horizontal, scrollable list of categories using styled chips.
class AppCategorySelector extends StatelessWidget {
  const AppCategorySelector({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.onCategorySelected,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String>? onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Ensure there's at least one category to avoid errors.
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 36, // Set a fixed height for the category bar
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            showCheckmark: false,
            shape: const StadiumBorder(),
            onSelected: (_) => onCategorySelected?.call(category),
            selectedColor: theme.primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? theme.colorScheme.onPrimary : null,
            ),
          );
        },
      ),
    );
  }
}
