import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart';

class AttendanceBottomNavShellPage extends StatelessWidget {
  const AttendanceBottomNavShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const _titles = <String>['Attendance', 'History'];

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.access_time_outlined),
      label: 'Attendance',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_outlined),
      label: 'History',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppBottomNavShellScaffold(
      navigationShell: navigationShell,
      titles: _titles,
      items: _items,
      centerTitle: false,
      onBackPressed: () => context.go(AppRoute.branchPortal.path),
      backIcon: Icons.home_outlined,
      backTooltip: 'Home',
    );
  }
}
