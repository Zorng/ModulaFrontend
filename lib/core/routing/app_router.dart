enum AppRoute { login, adminPortal, adminMenu, cashierPortal, components }

extension AppRoutePath on AppRoute {
  String get path => switch (this) {
        AppRoute.login => '/login',
        AppRoute.adminPortal => '/portal/admin',
        AppRoute.adminMenu => '/admin/portal/menu',
        AppRoute.cashierPortal => '/portal/cashier',
        AppRoute.components => '/components',
      };

  String get name => switch (this) {
        AppRoute.login => 'login',
        AppRoute.adminPortal => 'adminPortal',
        AppRoute.adminMenu => 'adminMenu',
        AppRoute.cashierPortal => 'cashierPortal',
        AppRoute.components => 'components',
      };
}
