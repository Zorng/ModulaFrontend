import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_summary.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/view/add_stock_item/add_stock_item_page.dart';
import 'package:modular_pos/features/inventory/ui/view/category_management/category_management_page.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_home/inventory_home_page.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/inventory_journal_page.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal_detail/inventory_journal_detail_page.dart';
import 'package:modular_pos/features/inventory/ui/view/add_category/add_category_page.dart';
import 'package:modular_pos/features/inventory/ui/components/category_form.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_shell/inventory_bottom_nav_shell_page.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/inventory_stock_items_page.dart';
import 'package:modular_pos/features/inventory/ui/view/restock_stock_item/restock_stock_item_page.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_adjust_quantity/stock_adjust_quantity_page.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_item_detail/stock_item_detail_page.dart';

List<RouteBase> buildInventoryRoutes() {
  return [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return InventoryBottomNavShellPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.inventory.path,
              name: AppRoute.inventory.name,
              builder: (context, state) => const InventoryHomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.inventoryStockItems.path,
              name: AppRoute.inventoryStockItems.name,
              builder: (context, state) => const InventoryStockItemsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.inventoryCategories.path,
              name: AppRoute.inventoryCategories.name,
              builder: (context, state) => const CategoryManagementPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.inventoryJournal.path,
              name: AppRoute.inventoryJournal.name,
              builder: (context, state) => const InventoryJournalPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoute.inventoryAddItem.path,
      name: AppRoute.inventoryAddItem.name,
      builder: (context, state) => const AddStockItemPage(),
    ),
    GoRoute(
      path: AppRoute.inventoryAddCategory.path,
      name: AppRoute.inventoryAddCategory.name,
      builder: (context, state) => const AddInventoryCategoryPage(),
    ),
    GoRoute(
      path: AppRoute.inventoryCategoryDetail.path,
      name: AppRoute.inventoryCategoryDetail.name,
      builder: (context, state) {
        final category = state.extra as InventoryCategory;
        return CategoryFormPage(
          mode: CategoryFormMode.view,
          category: category,
        );
      },
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
      path: AppRoute.inventoryRestock.path,
      name: AppRoute.inventoryRestock.name,
      builder: (context, state) => const RestockStockItemPage(),
    ),
    GoRoute(
      path: AppRoute.inventoryJournalDetail.path,
      name: AppRoute.inventoryJournalDetail.name,
      builder: (context, state) {
        final summary = state.extra as InventoryJournalDaySummary;
        return InventoryJournalDetailPage(summary: summary);
      },
    ),
  ];
}
