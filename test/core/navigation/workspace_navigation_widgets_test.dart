import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/sync/global_sync_status.dart';
import 'package:modular_pos/core/widgets/navigation/account_shell_action.dart';
import 'package:modular_pos/core/widgets/navigation/app_navigation_config.dart';
import 'package:modular_pos/core/widgets/navigation/app_navigation_portal_content.dart';
import 'package:modular_pos/core/widgets/navigation/branch_workspace_scaffold.dart';
import 'package:modular_pos/core/widgets/navigation/app_wide_navigation_rail_shell.dart';
import 'package:modular_pos/core/widgets/navigation/navigation_layer_back_button.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_workspace_app_bar_actions.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_profile_header.dart';
import 'package:modular_pos/core/widgets/sync/global_sync_status_indicator.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/portals/admin_portal.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/notification/data/operational_notification_repository.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession _session;

  @override
  LoginState build() => LoginState(session: _session);
}

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

AuthSession _session({
  required String role,
  required List<UserBranch> branches,
}) {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: role,
      tenantId: 'tenant-1',
      branches: branches,
    ),
    memberships: [
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: role,
        branches: branches,
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
  );
}

Widget _portalHarness({
  required AuthSession session,
  required AppNavigationLayer layer,
}) {
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(session),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(body: AppNavigationPortalContent(layer: layer)),
    ),
  );
}

Widget _railHarness({
  required AuthSession session,
  required String path,
  Widget child = const SizedBox.shrink(),
}) {
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(session),
      ),
      operationalNotificationRepositoryProvider.overrideWithValue(
        const _FakeOperationalNotificationRepository(unreadCount: 3),
      ),
      globalSyncStatusProvider.overrideWithValue(
        const GlobalSyncStatus(
          kind: GlobalSyncStatusKind.online,
          label: 'Online',
          detail: 'Workspace is connected.',
        ),
      ),
    ],
    child: MaterialApp(
      home: AppScaffoldShell(currentPath: path, child: child),
    ),
  );
}

Widget _branchHarness({
  required AuthSession session,
  required String path,
  required String title,
}) {
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(session),
      ),
      operationalNotificationRepositoryProvider.overrideWithValue(
        const _FakeOperationalNotificationRepository(unreadCount: 3),
      ),
      globalSyncStatusProvider.overrideWithValue(
        const GlobalSyncStatus(
          kind: GlobalSyncStatusKind.online,
          label: 'Online',
          detail: 'Workspace is connected.',
        ),
      ),
    ],
    child: MaterialApp(
      home: AppScaffoldShell(
        currentPath: path,
        child: BranchWorkspaceScaffold(
          title: title,
          currentPath: path,
          body: const SizedBox.shrink(),
        ),
      ),
    ),
  );
}

Widget _adminPortalShellHarness({
  required AuthSession session,
  required AppNavigationLayer layer,
}) {
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(session),
      ),
      operationalNotificationRepositoryProvider.overrideWithValue(
        const _FakeOperationalNotificationRepository(unreadCount: 3),
      ),
      globalSyncStatusProvider.overrideWithValue(
        const GlobalSyncStatus(
          kind: GlobalSyncStatusKind.online,
          label: 'Online',
          detail: 'Workspace is connected.',
        ),
      ),
    ],
    child: MaterialApp(home: AdminPortal(layer: layer)),
  );
}

Widget _widePortalAppShellHarness({
  required AuthSession session,
  required AppNavigationLayer layer,
}) {
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(session),
      ),
      operationalNotificationRepositoryProvider.overrideWithValue(
        const _FakeOperationalNotificationRepository(unreadCount: 3),
      ),
      globalSyncStatusProvider.overrideWithValue(
        const GlobalSyncStatus(
          kind: GlobalSyncStatusKind.online,
          label: 'Online',
          detail: 'Workspace is connected.',
        ),
      ),
    ],
    child: MaterialApp(
      home: AppScaffoldShell(
        currentPath: AppRoute.portal.path,
        child: AdminPortal(layer: layer),
      ),
    ),
  );
}

void _setWideViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 800);
}

void _setNarrowViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 844);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  const noActiveBranches = [
    UserBranch(
      id: 'assign-a',
      name: 'Branch A',
      role: 'admin',
      active: false,
      branchId: 'branch-a',
    ),
    UserBranch(
      id: 'assign-b',
      name: 'Branch B',
      role: 'admin',
      active: false,
      branchId: 'branch-b',
    ),
  ];

  const activeBranch = [
    UserBranch(
      id: 'assign-a',
      name: 'Branch A',
      role: 'admin',
      active: true,
      branchId: 'branch-a',
    ),
  ];

  testWidgets('owner/admin tenant portal shows tenant destinations only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _portalHarness(
        session: _session(role: 'admin', branches: noActiveBranches),
        layer: AppNavigationLayer.tenant,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tenant 1'), findsOneWidget);
    expect(find.text('Branches'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Discounts'), findsOneWidget);
    expect(find.text('Branch'), findsNothing);
    expect(find.text('Cash Sessions'), findsNothing);
    expect(find.text('Policy'), findsNothing);
    expect(find.text('Sale'), findsNothing);
  });

  testWidgets('owner/admin branch portal shows branch destinations only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _portalHarness(
        session: _session(role: 'admin', branches: activeBranch),
        layer: AppNavigationLayer.branch,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Branch'), findsOneWidget);
    expect(find.text('Cash Sessions'), findsOneWidget);
    expect(find.text('Policy'), findsOneWidget);
    expect(find.text('Sale'), findsOneWidget);
    expect(find.text('Active Discount'), findsOneWidget);
    expect(find.text('Tenant'), findsNothing);
    expect(find.text('Branches'), findsNothing);
    expect(find.text('Inventory'), findsNothing);
  });

  testWidgets('cashier branch portal shows operations only', (tester) async {
    await tester.pumpWidget(
      _portalHarness(
        session: _session(role: 'cashier', branches: activeBranch),
        layer: AppNavigationLayer.branch,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Cash Sessions'), findsOneWidget);
    expect(find.text('Sale'), findsOneWidget);
    expect(find.text('Active Discount'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Tenant'), findsNothing);
    expect(find.text('Branch'), findsNothing);
    expect(find.text('Branches'), findsNothing);
  });

  testWidgets('wide rail shows tenant layer only for owner/admin', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(
      _railHarness(
        session: _session(role: 'admin', branches: noActiveBranches),
        path: '/branches',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TENANT'), findsOneWidget);
    expect(find.text('BRANCH'), findsNothing);
    expect(find.text('Branches'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Discounts'), findsOneWidget);
    expect(find.text('Cash Sessions'), findsNothing);
    expect(find.text('Active Discount'), findsNothing);
    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('Tenant 1'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byType(NavigationLayerBackButton), findsOneWidget);
    expect(find.byType(TenantProfileHeader), findsNothing);
    expect(find.byType(GlobalSyncStatusIndicator), findsNothing);
    expect(find.text('Online'), findsNothing);
    expect(
      find.byKey(const Key('operational_notification_inbox_action')),
      findsNothing,
    );
    expect(find.byKey(AccountShellAction.actionKey), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(find.text('No branch selected'), findsOneWidget);
    expect(find.byTooltip('Switch tenant'), findsNothing);
    expect(
      tester.getTopLeft(find.byIcon(Icons.arrow_back)).dy,
      lessThan(tester.getTopLeft(find.text('Workspace')).dy),
    );
    final railSurface = tester.widget<Material>(
      find.byKey(const Key('wide_navigation_rail_surface')),
    );
    expect(railSurface.color, Colors.white);

    final branchesTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Branches'),
    );
    expect(branchesTile.selected, isTrue);
  });

  testWidgets(
    'wide notifications route behaves like utility page, not branch page',
    (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      await tester.pumpWidget(
        _railHarness(
          session: _session(role: 'admin', branches: noActiveBranches),
          path: AppRoute.notifications.path,
          child: const Text('Notifications body'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications body'), findsOneWidget);
      expect(find.byType(NavigationLayerBackButton), findsNothing);

      final branchesTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Branches'),
      );
      expect(branchesTile.selected, isFalse);
    },
  );

  testWidgets('wide rail shows branch layer only for owner/admin', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(
      _branchHarness(
        session: _session(role: 'admin', branches: activeBranch),
        path: '/cash/session',
        title: 'Cash Session',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TenantProfileHeader), findsNothing);
    expect(find.byType(NavigationLayerBackButton), findsNothing);
    expect(find.byType(GlobalSyncStatusIndicator), findsOneWidget);
    expect(
      find.byKey(const Key('operational_notification_inbox_action')),
      findsOneWidget,
    );
    expect(find.byKey(AccountShellAction.actionKey), findsOneWidget);
    expect(
      find.byKey(const Key('operational_notification_unread_badge')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byType(GlobalSyncStatusIndicator)).dx,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const Key('operational_notification_inbox_action')),
            )
            .dx,
      ),
    );
    expect(
      tester.getTopLeft(find.byType(GlobalSyncStatusIndicator)).dx,
      lessThan(tester.getTopLeft(find.byKey(AccountShellAction.actionKey)).dx),
    );
    await tester.tap(find.byTooltip('Open workspace drawer'));
    await tester.pumpAndSettle();

    expect(find.text('Branch'), findsOneWidget);
    expect(find.text('Cash Sessions'), findsOneWidget);
    expect(find.text('Policy'), findsOneWidget);
    expect(find.text('Sale'), findsOneWidget);
    expect(find.text('Active Discount'), findsOneWidget);
    expect(find.text('Branch A'), findsOneWidget);
    expect(find.text('To tenant'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('To tenant')).dy,
      lessThan(tester.getTopLeft(find.text('Workspace')).dy),
    );

    final cashTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Cash Sessions'),
    );
    expect(cashTile.selected, isTrue);
  });

  testWidgets('wide rail keeps active discount in branch layer', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(
      _branchHarness(
        session: _session(role: 'admin', branches: activeBranch),
        path: AppRoute.branchDiscount.path,
        title: 'Active Discounts',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TenantProfileHeader), findsNothing);
    await tester.tap(find.byTooltip('Open workspace drawer'));
    await tester.pumpAndSettle();

    expect(find.text('Branch'), findsOneWidget);
    expect(find.text('Active Discount'), findsOneWidget);
    expect(find.text('Branches'), findsNothing);

    final activeDiscountTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Active Discount'),
    );
    expect(activeDiscountTile.selected, isTrue);
  });

  testWidgets('wide rail shows staff branch operations with branch back', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(
      _branchHarness(
        session: _session(role: 'manager', branches: activeBranch),
        path: '/attendance',
        title: 'Attendance',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationLayerBackButton), findsNothing);
    await tester.tap(find.byTooltip('Open workspace drawer'));
    await tester.pumpAndSettle();

    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Cash Sessions'), findsOneWidget);
    expect(find.text('Sale'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Attendance'), findsOneWidget);
    expect(find.text('Attendance Management'), findsOneWidget);
    expect(find.text('Branches'), findsNothing);
    expect(find.text('To tenant'), findsOneWidget);
  });

  testWidgets('wide rail keeps cash history in branch operations layer', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(
      _branchHarness(
        session: _session(role: 'manager', branches: activeBranch),
        path: '/cash/session/history',
        title: 'History',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open workspace drawer'));
    await tester.pumpAndSettle();

    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Cash Sessions'), findsOneWidget);
    expect(find.text('Sale'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Branches'), findsNothing);
    expect(find.text('To tenant'), findsOneWidget);

    final cashTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Cash Sessions'),
    );
    expect(cashTile.selected, isTrue);
  });

  testWidgets('tenant portal shell shows account action without settings', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(
      _adminPortalShellHarness(
        session: _session(role: 'admin', branches: noActiveBranches),
        layer: AppNavigationLayer.tenant,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AccountShellAction.actionKey), findsOneWidget);
    expect(find.byType(TenantWorkspaceAppBarActions), findsOneWidget);
    expect(find.byType(TenantProfileHeader), findsNothing);
    expect(find.text('Admin Portal'), findsOneWidget);
    expect(
      find.byKey(const Key('operational_notification_inbox_action')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(find.byType(GlobalSyncStatusIndicator), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(GlobalSyncStatusIndicator)).dx,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const Key('operational_notification_inbox_action')),
            )
            .dx,
      ),
    );
    expect(
      tester.getTopLeft(find.byType(GlobalSyncStatusIndicator)).dx,
      lessThan(tester.getTopLeft(find.byKey(AccountShellAction.actionKey)).dx),
    );
  });

  testWidgets('wide tenant portal does not duplicate shell utility icons', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(
      _widePortalAppShellHarness(
        session: _session(role: 'admin', branches: noActiveBranches),
        layer: AppNavigationLayer.tenant,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AccountShellAction.actionKey), findsOneWidget);
    expect(find.byType(TenantWorkspaceAppBarActions), findsOneWidget);
    expect(find.text('Workspace'), findsOneWidget);
    expect(find.byType(TenantProfileHeader), findsNothing);
    expect(find.text('Admin Portal'), findsOneWidget);
    expect(
      find.byKey(const Key('operational_notification_inbox_action')),
      findsOneWidget,
    );
    expect(find.byType(GlobalSyncStatusIndicator), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('mobile shell shows global sync indicator without wide rail', (
    tester,
  ) async {
    _setNarrowViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(
      _branchHarness(
        session: _session(role: 'manager', branches: activeBranch),
        path: '/attendance',
        title: 'Attendance',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GlobalSyncStatusIndicator), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.byType(TenantProfileHeader), findsNothing);
    expect(find.byType(NavigationLayerBackButton), findsNothing);
  });
}
