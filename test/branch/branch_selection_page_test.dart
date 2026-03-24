import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/routing/routes/account_routes.dart';
import 'package:modular_pos/core/sync/global_sync_status.dart';
import 'package:modular_pos/core/widgets/navigation/account_shell_action.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_workspace_app_bar_actions.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/ui/view/branch_selection/branch_selection_page.dart';
import 'package:modular_pos/features/notification/data/operational_notification_repository.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';

class _FakeOperationalNotificationRepository
    implements OperationalNotificationRepository {
  const _FakeOperationalNotificationRepository({this.unreadCount = 0});

  final int unreadCount;

  @override
  Future<int> getUnreadCount() async => unreadCount;

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

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._state);

  final LoginState _state;

  @override
  LoginState build() => _state;

  @override
  Future<void> loadBranchContexts() async {}
}

LoginState _state() {
  final session = AuthSession(
    user: User(
      id: 'user-1',
      name: 'Branch User',
      role: 'MANAGER',
      tenantId: 'tenant-001',
    ),
    memberships: const [
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-001',
        tenantName: 'Tenant A',
        role: 'MANAGER',
        branches: <UserBranch>[],
      ),
    ],
    activeTenantId: 'tenant-001',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );

  return LoginState(
    session: session,
    branchOptions: const [
      AuthBranchContextOption(
        branchId: 'branch-001',
        branchName: 'Main Branch',
      ),
    ],
  );
}

Widget _routerHarness() {
  final router = GoRouter(
    initialLocation: AppRoute.branchSelection.path,
    routes: [
      GoRoute(
        path: AppRoute.branchSelection.path,
        builder: (context, state) => const BranchSelectionPage(),
      ),
      GoRoute(
        path: AppRoute.tenantSelection.path,
        builder: (context, state) =>
            const Scaffold(body: Text('Tenant switch')),
      ),
      ...buildAccountRoutes(),
    ],
  );

  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(_state()),
      ),
      globalSyncStatusProvider.overrideWithValue(
        const GlobalSyncStatus(
          kind: GlobalSyncStatusKind.online,
          label: 'Online',
          detail: 'Workspace is connected.',
        ),
      ),
      operationalNotificationRepositoryProvider.overrideWithValue(
        const _FakeOperationalNotificationRepository(unreadCount: 2),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _setWideSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 1000);
}

void main() {
  testWidgets('branch selection app bar uses shared tenant actions', (
    tester,
  ) async {
    _setWideSurface(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_routerHarness());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('operational_notification_inbox_action')),
      findsOneWidget,
    );
    expect(find.byKey(AccountShellAction.actionKey), findsOneWidget);
    expect(find.byType(TenantWorkspaceAppBarActions), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsNothing);
  });

  testWidgets('branch selection account action opens account page', (
    tester,
  ) async {
    _setWideSurface(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_routerHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AccountShellAction.actionKey));
    await tester.pumpAndSettle();

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
