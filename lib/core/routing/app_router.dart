enum AppRoute { login, adminPortal, cashierPortal }

extension AppRoutePath on AppRoute {
  String get path => switch (this) {
        AppRoute.login => '/login',
        AppRoute.adminPortal => '/portal/admin',
        AppRoute.cashierPortal => '/portal/cashier',
      };

  String get name => switch (this) {
        AppRoute.login => 'login',
        AppRoute.adminPortal => 'adminPortal',
        AppRoute.cashierPortal => 'cashierPortal',
      };
}
