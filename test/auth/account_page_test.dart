import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/routing/routes/account_routes.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession _session;

  @override
  LoginState build() => LoginState(session: _session);
}

AuthSession _session() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Alex Owner',
      role: 'OWNER',
      tenantId: 'tenant-001',
      phone: '+85512345678',
      branches: const [
        UserBranch(
          id: 'assignment-1',
          name: 'Main Branch',
          role: 'OWNER',
          active: true,
          branchId: 'branch-001',
        ),
      ],
    ),
    memberships: const [
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-001',
        tenantName: 'Main Tenant',
        role: 'OWNER',
        branches: [
          UserBranch(
            id: 'assignment-1',
            name: 'Main Branch',
            role: 'OWNER',
            active: true,
            branchId: 'branch-001',
          ),
          UserBranch(
            id: 'assignment-2',
            name: 'Outlet Branch',
            role: 'MANAGER',
            active: false,
            branchId: 'branch-002',
          ),
        ],
      ),
      TenantMembership(
        membershipId: 'membership-2',
        tenantId: 'tenant-002',
        tenantName: 'Second Tenant',
        role: 'CASHIER',
        branches: [],
      ),
    ],
    activeTenantId: 'tenant-001',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
}

Widget _routerHarness() {
  final router = GoRouter(
    initialLocation: AppRoute.account.path,
    routes: buildAccountRoutes(),
  );

  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(_session()),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _setLargeSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 1200);
}

void main() {
  testWidgets(
    'Account page shows profile, access, settings, and session sections',
    (tester) async {
      _setLargeSurface(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_routerHarness());
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Access'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Session'), findsOneWidget);
      expect(find.text('Main Tenant'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Open settings'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    },
  );

  testWidgets(
    'Settings entry routes to settings page without edit affordance',
    (tester) async {
      _setLargeSurface(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_routerHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();

      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    },
  );
}
