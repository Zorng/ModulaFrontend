import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/sync/global_sync_status.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/notification/data/operational_notification_repository.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';
import 'package:modular_pos/features/sale/ui/view/sale_shell/sale_bottom_nav_shell_page.dart';

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession _session;

  @override
  LoginState build() => LoginState(session: _session);
}

class _FakeOperationalNotificationRepository
    implements OperationalNotificationRepository {
  const _FakeOperationalNotificationRepository();

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  Future<OperationalNotificationInboxPage> listInbox({
    bool unreadOnly = false,
    String? type,
    String? tenantId,
    String? branchId,
    int limit = 50,
    int offset = 0,
  }) async {
    return const OperationalNotificationInboxPage(
      items: <OperationalNotificationItem>[],
      limit: 50,
      offset: 0,
      total: 0,
      hasMore: false,
    );
  }

  @override
  Future<OperationalNotificationItem> getNotificationById(
    String notificationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<OperationalNotificationReadResult> markNotificationAsRead(
    String notificationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<OperationalNotificationMarkAllReadResult> markAllAsRead() {
    throw UnimplementedError();
  }
}

AuthSession _session() {
  const activeBranch = UserBranch(
    id: 'assignment-1',
    name: 'Branch 1',
    role: 'cashier',
    active: true,
    branchId: 'branch-1',
  );

  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: 'cashier',
      tenantId: 'tenant-1',
      branches: [activeBranch],
    ),
    memberships: const [
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: 'cashier',
        branches: [activeBranch],
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    accessTokenExpiresAt: DateTime(2026, 4, 1),
    refreshTokenExpiresAt: DateTime(2026, 4, 8),
  );
}

void _setSmallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Widget _saleShellHarness() {
  final router = GoRouter(
    initialLocation: AppRoute.saleCart.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return SaleBottomNavShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.sale.path,
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Sale tab body'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.saleCart.path,
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Cart tab body'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.orders.path,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Fulfillment tab body')),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(_session()),
      ),
      operationalNotificationRepositoryProvider.overrideWithValue(
        const _FakeOperationalNotificationRepository(),
      ),
      globalSyncStatusProvider.overrideWithValue(
        const GlobalSyncStatus(
          kind: GlobalSyncStatusKind.online,
          label: 'Online',
          detail: 'Workspace is connected.',
        ),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('small cart tab removes the legacy view-carts overflow action', (
    tester,
  ) async {
    _setSmallViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(_saleShellHarness());
    await tester.pumpAndSettle();

    expect(find.text('Cart tab body'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.text('View carts'), findsNothing);
  });
}
