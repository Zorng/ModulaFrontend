import 'package:flutter/material.dart';

/// A horizontal, scrollable list of categories using styled chips.
///
/// Manages its own selection state and calls a callback when a new
/// category is selected.
class AppCategorySelector extends StatefulWidget {
  const AppCategorySelector({
    super.key,
    required this.categories,
    this.onCategorySelected,
  });

  final List<String> categories;
  final ValueChanged<String>? onCategorySelected;

  @override
  State<AppCategorySelector> createState() => _AppCategorySelectorState();
}

class _AppCategorySelectorState extends State<AppCategorySelector> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Ensure there's at least one category to avoid errors.
    if (widget.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 36, // Set a fixed height for the category bar
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final isSelected = _selectedIndex == index;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            showCheckmark: false,
            shape: const StadiumBorder(),
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedIndex = index);
                widget.onCategorySelected?.call(category);
              }
            },
            selectedColor: theme.primaryColor,
            labelStyle: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimary : null),
          );
        },
      ),
    );
  }
}
