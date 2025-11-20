enum AppRoute {
  login,
  adminPortal,
  cashierPortal,
  components,
  policy,
  account,
  settings,
  inventory,
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
      };
}
