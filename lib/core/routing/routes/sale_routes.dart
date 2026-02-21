import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/sale_summary.dart';
import 'package:modular_pos/features/sale/ui/view/order/order_page.dart';
import 'package:modular_pos/features/sale/ui/view/order_detail/order_detail_page.dart';
import 'package:modular_pos/features/sale/ui/view/sale/sale_page.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/sale_cart_page.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/view/sale_shell/sale_bottom_nav_shell_page.dart';
import 'package:modular_pos/features/sale/ui/view/view_cart_detail/view_cart_detail_page.dart';
import 'package:modular_pos/features/sale/ui/view/view_carts/view_carts_page.dart';

List<RouteBase> buildSaleRoutes() {
  return [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return SaleBottomNavShellPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.sale.path,
              name: AppRoute.sale.name,
              builder: (context, state) => const SalePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.saleCart.path,
              name: AppRoute.saleCart.name,
              builder: (context, state) => const SaleCartPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.orders.path,
              name: AppRoute.orders.name,
              builder: (context, state) => const OrderPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoute.saleItemDetail.path,
      name: AppRoute.saleItemDetail.name,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is SaleItemDetailRouteExtra) {
          return SaleItemDetailPage(
            item: extra.item,
            useMockData: extra.useMockData,
          );
        }
        final item = extra as MenuItem;
        return SaleItemDetailPage(item: item);
      },
    ),
    GoRoute(
      path: AppRoute.saleViewCarts.path,
      name: AppRoute.saleViewCarts.name,
      builder: (context, state) => const ViewCartsPage(),
    ),
    GoRoute(
      path: AppRoute.saleViewCartDetail.path,
      name: AppRoute.saleViewCartDetail.name,
      builder: (context, state) {
        final summary = state.extra as SaleSummary;
        return ViewCartDetailPage(summary: summary);
      },
    ),
    GoRoute(
      path: AppRoute.orderDetail.path,
      name: AppRoute.orderDetail.name,
      builder: (context, state) {
        final orderNumber = state.extra as String;
        return OrderDetailPage(orderNumber: orderNumber);
      },
    ),
  ];
}
