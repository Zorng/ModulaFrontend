import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/features/auth/ui/portals/admin_portal.dart';
import 'package:modular_pos/features/auth/ui/portals/cashier_portal.dart';
import 'package:modular_pos/features/auth/ui/view/login_view.dart';
import 'package:modular_pos/features/menu/ui/view/menu_page.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/core/widgets/widget_gallery_page.dart';
import 'package:modular_pos/features/policy/ui/view/policy_page.dart';
import 'package:modular_pos/features/common/ui/settings_page.dart';
import 'package:modular_pos/features/auth/ui/view/account_page.dart';
import 'package:modular_pos/features/inventory/ui/view/category_management_page.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_home_page.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/view/add_stock_item_page.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_item_detail_page.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items_page.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_adjust_quantity_page.dart';
import 'package:modular_pos/features/inventory/ui/view/restock_stock_item_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    errorBuilder: (context, state) => const Scaffold(
      body: Center(
        child: Text(
          'Page not found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    redirect: (context, state) {
      final authState = ref.read(loginControllerProvider);
      final session = authState.session;
      final path = state.uri.path; // current path
      final isLoggingIn = path == AppRoute.login.path;

      // Developer-only gallery should be reachable without auth.
      if (path == AppRoute.components.path) {
        return null;
      }

      // Not authenticated: only allow /login
      if (session == null) {
        return isLoggingIn ? null : AppRoute.login.path;
      }

      final role = session.user.role.toLowerCase();

      String homeForRole() {
        switch (role) {
          case 'admin':
            return AppRoute.adminPortal.path;
          case 'cashier':
          case 'manager':
          default:
            return AppRoute.cashierPortal.path;
        }
      }

      // Already authenticated: prevent going back to /login
      if (isLoggingIn) {
        return homeForRole();
      }

      // Authenticated but not allowed to access admin portal → 404
      if (path == AppRoute.adminPortal.path && role != 'admin') {
        return '/404';
      }

      // Authenticated but not allowed to access policy → 404
      if (path == AppRoute.policy.path && role != 'admin') {
        return '/404';
      }
      if ((path == AppRoute.inventory.path ||
              path == AppRoute.inventoryAddItem.path ||
              path == AppRoute.inventoryStockDetail.path ||
              path == AppRoute.inventoryStockItems.path ||
              path == AppRoute.inventoryRestock.path ||
              path == AppRoute.inventoryCategories.path) &&
          role != 'admin') {
        return '/404';
      }

      // Authenticated but not allowed to access cashier portal → 404
      if (path == AppRoute.cashierPortal.path && role != 'cashier') {
        return '/404';
      }

      // For other paths (including unknown ones), don't redirect here.
      // If no route matches, errorBuilder will show "Page not found".
      return null;
    },
    initialLocation: AppRoute.login.path,
    routes: [
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoute.components.path,
        name: AppRoute.components.name,
        builder: (context, state) => const WidgetGalleryPage(),
      ),
      // Temporary route for developing and testing the MenuPage.
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuPage(),
      ),
      GoRoute(
        path: AppRoute.adminPortal.path,
        name: AppRoute.adminPortal.name,
        builder: (context, state) => const AdminPortal(),
      ),
      GoRoute(
        path: AppRoute.policy.path,
        name: AppRoute.policy.name,
        builder: (context, state) => const PolicyPage(),
      ),
      GoRoute(
        path: AppRoute.account.path,
        name: AppRoute.account.name,
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: AppRoute.settings.path,
        name: AppRoute.settings.name,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoute.cashierPortal.path,
        name: AppRoute.cashierPortal.name,
        builder: (context, state) => const CashierPortal(),
      ),
      GoRoute(
        path: AppRoute.inventory.path,
        name: AppRoute.inventory.name,
        builder: (context, state) => const InventoryHomePage(),
      ),
      GoRoute(
        path: AppRoute.inventoryAddItem.path,
        name: AppRoute.inventoryAddItem.name,
        builder: (context, state) => const AddStockItemPage(),
      ),
      GoRoute(
        path: AppRoute.inventoryStockDetail.path,
        name: AppRoute.inventoryStockDetail.name,
        builder: (context, state) {
          final item = state.extra is StockItem
              ? state.extra as StockItem
              : const StockItem(
                  id: 'unknown',
                  name: 'Unknown item',
                  category: 'Uncategorized',
                  baseUnit: 'pcs',
                  pieceSize: 1,
                  branchId: 'main',
                  branchName: 'Main Branch',
                  onHand: 0,
                  minThreshold: 0,
                  isActive: true,
                );
          return StockItemDetailPage(item: item);
        },
      ),
      GoRoute(
        path: AppRoute.inventoryAdjustStock.path,
        name: AppRoute.inventoryAdjustStock.name,
        builder: (context, state) {
          final item = state.extra as StockItem;
          return AdjustStockQuantityPage(item: item);
        },
      ),
      GoRoute(
        path: AppRoute.inventoryStockItems.path,
        name: AppRoute.inventoryStockItems.name,
        builder: (context, state) => const InventoryStockItemsPage(),
      ),
      GoRoute(
        path: AppRoute.inventoryRestock.path,
        name: AppRoute.inventoryRestock.name,
        builder: (context, state) => const RestockStockItemPage(),
      ),
      GoRoute(
        path: AppRoute.inventoryCategories.path,
        name: AppRoute.inventoryCategories.name,
        builder: (context, state) => const CategoryManagementPage(),
      ),
    ],
  );
});


class ModulaApp extends ConsumerWidget {
  const ModulaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Modula POS',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
