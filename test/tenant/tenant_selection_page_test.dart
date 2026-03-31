import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/routing/routes/account_routes.dart';
import 'package:modular_pos/core/sync/global_sync_status.dart';
import 'package:modular_pos/core/widgets/navigation/account_shell_action.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_workspace_app_bar_actions.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/notification/data/operational_notification_repository.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';
import 'package:modular_pos/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart';

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

AuthSession _session() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tenant User',
      role: 'OWNER',
      tenantId: 'tenant-001',
    ),
    memberships: const [],
    activeTenantId: null,
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
    tenantSelectionToken: 'selection-token',
  );
}

Widget _routerHarness() {
  final router = GoRouter(
    initialLocation: AppRoute.tenantSelection.path,
    routes: [
      GoRoute(
        path: AppRoute.tenantSelection.path,
        builder: (context, state) => const TenantSelectionPage(),
      ),
      ...buildAccountRoutes(),
      GoRoute(
        path: AppRoute.invitationInbox.path,
        builder: (context, state) => const Scaffold(body: Text('Inbox')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      initialAuthSessionProvider.overrideWithValue(_session()),
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

void _setSmallSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 844);
}

void main() {
  testWidgets('tenant selection uses inbox plus shared tenant actions', (
    tester,
  ) async {
    _setWideSurface(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_routerHarness());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.byType(TenantWorkspaceAppBarActions), findsOneWidget);
    expect(
      find.byKey(const Key('operational_notification_inbox_action')),
      findsOneWidget,
    );
    expect(find.text('Online'), findsOneWidget);
    expect(find.byKey(AccountShellAction.actionKey), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(find.byIcon(Icons.logout), findsNothing);
  });

  testWidgets('tenant selection account action opens account page', (
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

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('small tenant selection account page can go back', (
    tester,
  ) async {
    _setSmallSurface(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_routerHarness());
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Tenant User'), findsNothing);

    await tester.tap(find.byKey(AccountShellAction.actionKey));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Account'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Tenants'), findsOneWidget);
    expect(find.text('Account'), findsNothing);
  });
}
