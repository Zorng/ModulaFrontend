import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart';

class SaleBottomNavShellPage extends StatelessWidget {
  const SaleBottomNavShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const _titles = <String>[
    'Sale',
    'Cart',
    'Orders',
  ];

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.storefront_outlined),
      label: 'Sale',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart_outlined),
      label: 'Cart',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      label: 'Orders',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;

    return AppBottomNavShellScaffold(
      navigationShell: navigationShell,
      titles: _titles,
      items: _items,
      centerTitle: false,
      actions:
          index == 1
              ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'view_carts') {
                      context.push(AppRoute.saleViewCarts.path);
                    }
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem<String>(
                          value: 'view_carts',
                          child: Text('View carts'),
                        ),
                      ],
                ),
              ]
              : null,
      onBackPressed: () => context.go(AppRoute.portal.path),
      backIcon: Icons.home_outlined,
      backTooltip: 'Home',
    );
  }
}
