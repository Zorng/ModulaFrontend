import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/features/auth/ui/view/login_view.dart';

enum AppRoute { login }

extension AppRoutePath on AppRoute {
  String get path => switch (this) {
        AppRoute.login => '/login',
      };

  String get name => switch (this) {
        AppRoute.login => 'login',
      };
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.login.path,
    routes: [
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );
});
