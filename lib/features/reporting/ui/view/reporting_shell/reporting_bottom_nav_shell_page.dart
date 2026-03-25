import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart';

class ReportingBottomNavShellPage extends StatelessWidget {
  const ReportingBottomNavShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _titles = <String>['Sales', 'Inventory', 'Attendance'];

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.trending_up_outlined),
      label: 'Sales',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.inventory_2_outlined),
      label: 'Inventory',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.groups_2_outlined),
      label: 'Attendance',
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
