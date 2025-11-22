enum AppRoute {
  login,
  adminPortal,
  cashierPortal,
  components,
  policy,
  account,
  settings,
  inventory,
  inventoryAddItem,
  inventoryStockDetail,
  inventoryAdjustStock,
  inventoryStockItems,
  inventoryRestock,
  inventoryCategories,
}

extension AppRoutePath on AppRoute {
  String get path => switch (this) {
        AppRoute.login => '/login',
        AppRoute.adminPortal => '/portal/admin',
        AppRoute.cashierPortal => '/portal/cashier',
        AppRoute.components => '/components',
        AppRoute.policy => '/portal/admin/policy',
        AppRoute.account => '/account',
        AppRoute.settings => '/settings',
        AppRoute.inventory => '/portal/admin/inventory',
        AppRoute.inventoryAddItem => '/portal/admin/inventory/add-item',
        AppRoute.inventoryStockDetail => '/portal/admin/inventory/detail',
        AppRoute.inventoryAdjustStock => '/portal/admin/inventory/adjust',
        AppRoute.inventoryStockItems => '/portal/admin/inventory/stock-items',
        AppRoute.inventoryRestock => '/portal/admin/inventory/restock',
        AppRoute.inventoryCategories => '/portal/admin/inventory/categories',
      };

  String get name => switch (this) {
        AppRoute.login => 'login',
        AppRoute.adminPortal => 'adminPortal',
        AppRoute.cashierPortal => 'cashierPortal',
        AppRoute.components => 'components',
        AppRoute.policy => 'policy',
        AppRoute.account => 'account',
        AppRoute.settings => 'settings',
        AppRoute.inventory => 'inventory',
        AppRoute.inventoryAddItem => 'inventoryAddItem',
        AppRoute.inventoryStockDetail => 'inventoryStockDetail',
        AppRoute.inventoryAdjustStock => 'inventoryAdjustStock',
        AppRoute.inventoryStockItems => 'inventoryStockItems',
        AppRoute.inventoryRestock => 'inventoryRestock',
        AppRoute.inventoryCategories => 'inventoryCategories',
      };
}
