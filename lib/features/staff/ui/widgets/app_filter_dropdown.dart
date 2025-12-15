import 'package:flutter/material.dart';

class AppFilterDropdown<T> extends StatelessWidget {
  const AppFilterDropdown({
    super.key,
    required this.hintText,
    required this.items,
    required this.allText,
    this.value,
    required this.onChanged,
  });

  final String hintText;
  final List<T> items;
  final T? value;
  final String allText;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelMedium;

    // Create a combined list with "All" at the beginning
    final menuItems = [allText, ...items.map((i) => i.toString())];

    // Use PopupMenuButton for a dropdown that opens below the widget.
    return PopupMenuButton<String>(
      offset: const Offset(0, 40), // Pushes the menu down to open below
      onSelected: (selectedValue) {
        // If the selected value is the "All" text, pass null. Otherwise, find the original item.
        if (selectedValue == allText) {
          onChanged(null);
        } else {
          onChanged(items.firstWhere((item) => item.toString() == selectedValue));
        }
      },
      // Style the menu to look like an iOS popover
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      color: Colors.white, // A white menu background
      itemBuilder: (BuildContext context) {
        return menuItems.map((item) {
          return PopupMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(color: Colors.black)),
          );
        }).toList();
      },
      // This is the visible part of the button (the filter chip).
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value?.toString() ?? hintText, style: textStyle),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }
}