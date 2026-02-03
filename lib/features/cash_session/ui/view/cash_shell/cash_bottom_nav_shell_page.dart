import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart';

class CashBottomNavShellPage extends StatelessWidget {
  const CashBottomNavShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const _titles = <String>[
    'Session',
    'Movement',
    'Report',
  ];

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.attach_money_outlined),
      label: 'Session',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.swap_horiz_outlined),
      label: 'Movement',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.description_outlined),
      label: 'Report',
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
