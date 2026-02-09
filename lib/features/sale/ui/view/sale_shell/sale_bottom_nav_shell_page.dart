import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart';

class SaleBottomNavShellPage extends StatelessWidget {
  const SaleBottomNavShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _titles = <String>['Sale', 'Cart', 'Orders'];

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = AppBreakpoints.isLarge(constraints.maxWidth);

        if (isWide) {
          final wideItems = <BottomNavigationBarItem>[_items[0], _items[2]];
          final wideIndex = index == 2 ? 1 : 0;

          final showCartPanel = index == 0;
          final appBarTitle = index == 2 ? _titles[2] : _titles[0];
          return Scaffold(
            appBar: AppBar(
              title: Text(appBarTitle),
              centerTitle: false,
              actions: actionsForIndex(index, context),
            ),
            body: Row(
              children: [
                Expanded(child: navigationShell),
                if (showCartPanel) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: 360,
                    child: SaleCartPanel(
                      key: const ValueKey('wide_cart_panel'),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: wideIndex,
              items: wideItems,
              type: BottomNavigationBarType.fixed,
              onTap: (tabIndex) {
                navigationShell.goBranch(tabIndex == 0 ? 0 : 2);
              },
            ),
          );
        }

        return AppBottomNavShellScaffold(
          navigationShell: navigationShell,
          titles: _titles,
          items: _items,
          centerTitle: false,
          actions: actionsForIndex(index, context),
          onBackPressed: () => context.go(AppRoute.portal.path),
          backIcon: Icons.home_outlined,
          backTooltip: 'Home',
        );
      },
    );
  }

  List<Widget>? actionsForIndex(int index, BuildContext context) {
    if (index != 1) return null;
    return [
      PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'view_carts') {
            context.push(AppRoute.saleViewCarts.path);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem<String>(value: 'view_carts', child: Text('View carts')),
        ],
      ),
    ];
  }
}
