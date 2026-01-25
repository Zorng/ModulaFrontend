import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart';

class InventoryBottomNavShellPage extends StatelessWidget {
  const InventoryBottomNavShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const _titles = <String>[
    'Inventory',
    'Stock items',
    'Categories',
    'Journal',
  ];

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.inventory_2_outlined),
      label: 'Inventory',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.list_alt_outlined),
      label: 'Stock',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.category_outlined),
      label: 'Categories',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      label: 'Journal',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppBottomNavShellScaffold(
      navigationShell: navigationShell,
      titles: _titles,
      items: _items,
      centerTitle: false,
      onBackPressed: () => context.go(AppRoute.portal.path),
      backIcon: Icons.home_outlined,
      backTooltip: 'Home',
    );
  }
}
