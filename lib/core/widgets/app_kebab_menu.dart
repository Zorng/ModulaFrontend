import 'package:flutter/material.dart';

/// Represents a single option in the [AppKebabMenu].
class KebabMenuItem {
  const KebabMenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

/// A standardized kebab menu (three-dot) button that shows a popup menu.
///
/// It is configured by passing a list of [KebabMenuItem] objects.
class AppKebabMenu extends StatelessWidget {
  const AppKebabMenu({super.key, required this.items});

  final List<KebabMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<KebabMenuItem>(
      icon: const Icon(Icons.more_vert),
      color: Colors.white,
      offset: const Offset(0, 40), // Position the menu below the button
      onSelected: (item) => item.onTap(),
      itemBuilder: (BuildContext context) {
        return items.map((item) {
          return PopupMenuItem<KebabMenuItem>(
            value: item,
            child: Text(item.label),
          );
        }).toList();
      },
    );
  }
}
