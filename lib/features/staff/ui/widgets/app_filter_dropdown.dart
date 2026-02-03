import 'package:flutter/material.dart';

// Sentinel value to represent "All" option
const String _kAllOptionSentinel = '__ALL__';

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

    // Use PopupMenuButton for a dropdown that opens below the widget.
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      onSelected: (selectedValue) {
        if (selectedValue == _kAllOptionSentinel) {
          onChanged(null);
        } else {
          // Find the original item from the string representation
          final item = items.firstWhere((i) => i.toString() == selectedValue);
          onChanged(item);
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      color: Colors.white,
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            value: _kAllOptionSentinel,
            child: Text(allText, style: const TextStyle(color: Colors.black)),
          ),
          ...items.map((item) {
            return PopupMenuItem<String>(
              value: item.toString(),
              child: Text(item.toString(), style: const TextStyle(color: Colors.black)),
            );
          }),
        ];
      },
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