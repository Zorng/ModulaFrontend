import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/hydration/app_hydration_listener.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/features/auth/ui/portals/admin_portal.dart';
import 'package:modular_pos/features/auth/ui/portals/cashier_portal.dart';
import 'package:modular_pos/features/auth/ui/view/login_view.dart';
import 'package:modular_pos/features/auth/ui/view/tenant_selection/tenant_selection_page.dart';
import 'package:modular_pos/features/menu/ui/view/menu/menu_page.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management/categories_management_page.dart';
import 'package:modular_pos/features/menu/ui/view/add_category/add_category_page.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/ui/view/edit_category/edit_category_page.dart';
import 'package:modular_pos/features/menu/ui/view/modifiers_management/modifiers_management_page.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group/add_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/view/view_modifier_group/view_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/view/edit_modifier_group/edit_modifier_group_page.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/menu_item_form_page.dart';
import 'package:modular_pos/features/menu/ui/view/view_menu_item/view_menu_item_page.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/core/widgets/widget_gallery_page.dart';
import 'package:modular_pos/features/policy/ui/view/policy/policy_page.dart';
import 'package:modular_pos/features/policy/ui/view/policy/policy_route_args.dart';
import 'package:modular_pos/features/policy/ui/view/policy_detail/policy_detail_page.dart';
import 'package:modular_pos/features/policy/ui/view/vat_policy_detail/vat_policy_detail_page.dart';
import 'package:modular_pos/features/sale/ui/view/order/order_page.dart';
import 'package:modular_pos/features/sale/ui/view/order_detail/order_detail_page.dart';
import 'package:modular_pos/features/sale/ui/view/sale/sale_page.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/sale_cart_page.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/view/view_carts/view_carts_page.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/sale_summary.dart';
import 'package:modular_pos/features/sale/ui/view/view_cart_detail/view_cart_detail_page.dart';
import 'package:modular_pos/features/common/ui/settings_page.dart';
import 'package:modular_pos/features/auth/ui/view/account/account_page.dart';
import 'package:modular_pos/features/inventory/ui/view/category_management/category_management_page.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_home/inventory_home_page.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/view/add_stock_item/add_stock_item_page.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_item_detail/stock_item_detail_page.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/inventory_stock_items_page.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_adjust_quantity/stock_adjust_quantity_page.dart';
import 'package:modular_pos/features/inventory/ui/view/restock_stock_item/restock_stock_item_page.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_summary.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/inventory_journal_page.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal_detail/inventory_journal_detail_page.dart';
import 'package:modular_pos/features/cash_session/ui/view/cashier_cash_session.dart';
import 'package:modular_pos/features/cash_session/ui/view/x_report/x_report_page.dart';
import 'package:modular_pos/features/cash_session/ui/view/z_report/z_report_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_list_view.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';
import 'package:modular_pos/features/staff/ui/view/staff_add_placeholder_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_detail_view.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form_view.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance/attendance_page.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_management/attendance_management_page.dart';

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

      // Legacy path aliases (keep old bookmarks working).
      if (path.startsWith('/admin/portal/menu')) {
        return path.replaceFirst('/admin/portal/menu', AppRoute.adminMenu.path);
      }
      final isLoggingIn = path == AppRoute.login.path;
      final isTenantSelection = path == AppRoute.tenantSelection.path;

      // Developer-only gallery should be reachable without auth.
      if (path == AppRoute.components.path) {
        return null;
      }

      // Not authenticated: only allow /login
      if (session == null) {
        return isLoggingIn ? null : AppRoute.login.path;
      }

      // Authenticated, but tenant context not selected yet.
      if (session.requiresTenantSelection) {
        return isTenantSelection ? null : AppRoute.tenantSelection.path;
      }

      final role = session.user.role.trim().toLowerCase();

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

      // Authenticated but not allowed to access admin portal/menu → 404
      bool isInPathGroup(String root) {
        return path == root || path.startsWith('$root/');
      }

      if ((path == AppRoute.adminPortal.path ||
              isInPathGroup(AppRoute.adminMenu.path)) &&
          role != 'admin') {
        return '/404';
      }

      // Authenticated but not allowed to access policy → 404
      if (isInPathGroup(AppRoute.policy.path) &&
          role != 'admin' &&
          role != 'cashier') {
        return '/404';
      }
      if (isInPathGroup(AppRoute.inventory.path) && role != 'admin') {
        return '/404';
      }
      if (isInPathGroup(AppRoute.staff.path) && role != 'admin') {
        return '/404';
      }
      // Authenticated but not allowed to access cashier portal → 404
      if (path == AppRoute.cashierPortal.path &&
          role != 'cashier' &&
          role != 'admin') {
        return '/404';
      }

      // Authenticated but not allowed to access cashier dashboard → 404
      if (isInPathGroup(AppRoute.cashierCashSession.path) &&
          role != 'cashier' &&
          role != 'admin') {
        return '/404';
      }
      if (path == AppRoute.adminCashSession.path && role != 'admin') {
        return '/404';
      }
      if (isInPathGroup(AppRoute.attendance.path) &&
          role != 'cashier' &&
          role != 'manager') {
        return '/404';
      }
      if (path == AppRoute.xReport.path &&
          role != 'admin' &&
          role != 'cashier') {
        return '/404';
      }
      if (path == AppRoute.zReport.path && role != 'admin') {
        return '/404';
      }
      if (path == AppRoute.attendanceManagement.path && role != 'admin') {
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
        path: AppRoute.tenantSelection.path,
        name: AppRoute.tenantSelection.name,
        builder: (context, state) => const TenantSelectionPage(),
      ),
      GoRoute(
        path: AppRoute.components.path,
        name: AppRoute.components.name,
        builder: (context, state) => const WidgetGalleryPage(),
      ),
      GoRoute(
        path: AppRoute.adminPortal.path,
        name: AppRoute.adminPortal.name,
        builder: (context, state) => const AdminPortal(),
      ),
      GoRoute(
        path: AppRoute.adminMenu.path,
        name: AppRoute.adminMenu.name,
        builder: (context, state) => const MenuPage(),
      ),
      GoRoute(
        path: AppRoute.adminMenuCategories.path,
        name: AppRoute.adminMenuCategories.name,
        builder: (context, state) => const CategoriesManagementPage(),
      ),
      GoRoute(
        path: AppRoute.adminMenuAddCategory.path,
        name: AppRoute.adminMenuAddCategory.name,
        builder: (context, state) => const AddCategoryPage(),
      ),
      GoRoute(
        path: AppRoute.adminMenuEditCategory.path,
        name: AppRoute.adminMenuEditCategory.name,
        builder: (context, state) {
          final category = state.extra as MenuCategory;
          return EditCategoryPage(category: category);
        },
      ),
      GoRoute(
        path: AppRoute.adminMenuModifiers.path,
        name: AppRoute.adminMenuModifiers.name,
        builder: (context, state) => const ModifiersManagementPage(),
      ),
      GoRoute(
        path: AppRoute.adminMenuAddModifierGroup.path,
        name: AppRoute.adminMenuAddModifierGroup.name,
        builder: (context, state) => const AddModifierGroupPage(),
      ),
      GoRoute(
        path: AppRoute.adminMenuViewModifierGroup.path,
        name: AppRoute.adminMenuViewModifierGroup.name,
        builder: (context, state) {
          final group = state.extra as ModifierGroup;
          return ViewModifierGroupPage(group: group);
        },
      ),
      GoRoute(
        path: AppRoute.adminMenuEditModifierGroup.path,
        name: AppRoute.adminMenuEditModifierGroup.name,
        builder: (context, state) {
          final group = state.extra as ModifierGroup;
          return EditModifierGroupPage(group: group);
        },
      ),
      GoRoute(
        path: AppRoute.adminMenuItemForm.path,
        name: AppRoute.adminMenuItemForm.name,
        builder: (context, state) {
          final item = state.extra is MenuItem ? state.extra as MenuItem : null;
          return MenuItemFormPage(initialItem: item);
        },
      ),
      GoRoute(
        path: AppRoute.adminMenuViewMenuItem.path,
        name: AppRoute.adminMenuViewMenuItem.name,
        builder: (context, state) {
          final item = state.extra as MenuItem;
          return ViewMenuItemPage(menuItem: item);
        },
      ),
      GoRoute(
        path: AppRoute.policy.path,
        name: AppRoute.policy.name,
        builder: (context, state) => const PolicyPage(),
      ),
      GoRoute(
        path: AppRoute.policyVatDetail.path,
        name: AppRoute.policyVatDetail.name,
        builder: (context, state) {
          final args = state.extra as VatPolicyDetailArgs;
          final rateText = args.ratePercent == args.ratePercent.roundToDouble()
              ? args.ratePercent.toInt().toString()
              : args.ratePercent.toString();
          return VatPolicyDetailPage(
            enabled: args.enabled,
            currentRate: '$rateText%',
          );
        },
      ),
      GoRoute(
        path: AppRoute.policyItemDetail.path,
        name: AppRoute.policyItemDetail.name,
        builder: (context, state) {
          final args = state.extra as PolicyItemDetailArgs;
          return PolicyDetailPage(item: args.item, value: args.value);
        },
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
        path: AppRoute.attendance.path,
        name: AppRoute.attendance.name,
        builder: (context, state) => const AttendancePage(),
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
      GoRoute(
        path: AppRoute.inventoryJournal.path,
        name: AppRoute.inventoryJournal.name,
        builder: (context, state) => const InventoryJournalPage(),
      ),
      GoRoute(
        path: AppRoute.inventoryJournalDetail.path,
        name: AppRoute.inventoryJournalDetail.name,
        builder: (context, state) {
          final summary = state.extra as InventoryJournalDaySummary;
          return InventoryJournalDetailPage(summary: summary);
        },
      ),
      GoRoute(
        path: AppRoute.sale.path,
        name: AppRoute.sale.name,
        builder: (context, state) => const SalePage(),
      ),
      GoRoute(
        path: AppRoute.saleCart.path,
        name: AppRoute.saleCart.name,
        builder: (context, state) => const SaleCartPage(),
      ),
      GoRoute(
        path: AppRoute.saleItemDetail.path,
        name: AppRoute.saleItemDetail.name,
        builder: (context, state) {
          final item = state.extra as MenuItem;
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
        path: AppRoute.orders.path,
        name: AppRoute.orders.name,
        builder: (context, state) => const OrderPage(),
      ),
      GoRoute(
        path: AppRoute.orderDetail.path,
        name: AppRoute.orderDetail.name,
        builder: (context, state) {
          final orderNumber = state.extra as String;
          return OrderDetailPage(orderNumber: orderNumber);
        },
      ),
      GoRoute(
        path: AppRoute.cashierCashSession.path,
        name: AppRoute.cashierCashSession.name,
        builder: (context, state) => const CashSessionScreen(),
      ),
      GoRoute(
        path: AppRoute.adminCashSession.path,
        name: AppRoute.adminCashSession.name,
        builder: (context, state) => const CashSessionScreen(),
      ),
      GoRoute(
        path: AppRoute.xReport.path,
        name: AppRoute.xReport.name,
        builder: (context, state) => const XReportPage(),
      ),
      GoRoute(
        path: AppRoute.zReport.path,
        name: AppRoute.zReport.name,
        builder: (context, state) => const ZReportPage(),
      ),
      GoRoute(
        path: AppRoute.attendanceManagement.path,
        name: AppRoute.attendanceManagement.name,
        builder: (context, state) => const AttendanceManagementPage(),
      ),
      GoRoute(
        path: AppRoute.staff.path,
        name: AppRoute.staff.name,
        builder: (context, state) => const StaffListView(),
      ),
      GoRoute(
        path: AppRoute.staffDetail.path,
        name: AppRoute.staffDetail.name,
        builder: (context, state) {
          final staff = state.extra as Staff;
          return StaffDetailView(staff: staff);
        },
      ),
      GoRoute(
        path: AppRoute.staffForm.path,
        name: AppRoute.staffForm.name,
        builder: (context, state) {
          final staff = state.extra is Staff ? state.extra as Staff : null;
          return StaffFormView(staff: staff);
        },
      ),
      GoRoute(
        path: AppRoute.staffAdd.path,
        name: AppRoute.staffAdd.name,
        builder: (context, state) => const StaffAddPlaceholderPage(),
      ),
    ],
  );
});

class ModulaApp extends ConsumerWidget {
  const ModulaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return AppHydrationListener(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Modula POS',
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
