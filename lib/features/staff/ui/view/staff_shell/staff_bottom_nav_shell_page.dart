import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart';

class StaffBottomNavShellPage extends StatelessWidget {
  const StaffBottomNavShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _titles = <String>['Staff', 'Attendance', 'Shift'];

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Staff'),
    BottomNavigationBarItem(
      icon: Icon(Icons.access_time_outlined),
      label: 'Attendance',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.event_repeat_outlined),
      label: 'Shift',
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
