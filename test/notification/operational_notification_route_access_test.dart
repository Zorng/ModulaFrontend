import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/app.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
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
  const _FakeOperationalNotificationRepository({required this.items});

  final List<OperationalNotificationItem> items;

  @override
  Future<OperationalNotificationInboxPage> listInbox({
    bool unreadOnly = false,
    String? type,
    String? tenantId,
    String? branchId,
    int limit = 50,
    int offset = 0,
  }) async {
    return OperationalNotificationInboxPage(
      items: items,
      limit: limit,
      offset: offset,
      total: items.length,
      hasMore: false,
    );
  }

  @override
  Future<int> getUnreadCount() async =>
      items.where((item) => item.isUnread).length;

  @override
  Future<OperationalNotificationItem> getNotificationById(
    String notificationId,
  ) async {
    return items.firstWhere((item) => item.id == notificationId);
  }

  @override
  Future<OperationalNotificationReadResult> markNotificationAsRead(
    String notificationId,
  ) async {
    return OperationalNotificationReadResult(
      notificationId: notificationId,
      isRead: true,
      readAt: DateTime.utc(2026, 3, 24, 10, 0),
    );
  }

  @override
  Future<OperationalNotificationMarkAllReadResult> markAllAsRead() async {
    return OperationalNotificationMarkAllReadResult(updatedCount: items.length);
  }
}

AuthSession _tenantSessionWithoutActiveBranch() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Admin User',
      role: 'ADMIN',
      tenantId: 'tenant-1',
      branches: <UserBranch>[],
    ),
    memberships: const <TenantMembership>[
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: 'ADMIN',
        branches: <UserBranch>[],
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
}

AuthSession _accountSessionRequiringTenantSelection() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Admin User',
      role: 'ADMIN',
      tenantId: '',
      branches: <UserBranch>[],
    ),
    memberships: const <TenantMembership>[
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: 'ADMIN',
        branches: <UserBranch>[],
      ),
    ],
    activeTenantId: null,
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
    tenantSelectionToken: 'selection-token',
  );
}

OperationalNotificationItem _notification() {
  return OperationalNotificationItem(
    id: 'notif-1',
    tenantId: 'tenant-1',
    tenantName: 'Tenant 1',
    branchId: 'branch-1',
    branchName: 'Main Branch',
    type: OperationalNotificationTypes.voidApprovalNeeded,
    subjectType: OperationalNotificationSubjectTypes.sale,
    subjectId: 'sale-1',
    title: 'Void approval needed',
    body: 'Sale #001 requires review.',
    dedupeKey: 'VOID_APPROVAL_NEEDED:sale-1',
    payload: const {'saleId': 'sale-1'},
    createdAt: DateTime.utc(2026, 3, 24, 9, 0),
    isRead: false,
    readAt: null,
  );
}

Widget _routerHarness(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

void _setWideViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1800, 1200);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  testWidgets(
    'admin can open account-scoped notifications without tenant selection',
    (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      final session = _accountSessionRequiringTenantSelection();
      final container = ProviderContainer(
        overrides: [
          initialAuthSessionProvider.overrideWithValue(session),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(session),
          ),
          operationalNotificationRepositoryProvider.overrideWithValue(
            _FakeOperationalNotificationRepository(items: [_notification()]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(appRouterProvider).go(AppRoute.notifications.path);
      await tester.pumpWidget(_routerHarness(container));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Void approval needed'), findsOneWidget);
      expect(
        find.textContaining('Tenant: Tenant 1', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Main Branch', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Page not found'), findsNothing);
    },
  );

  testWidgets(
    'admin can open account-scoped notifications without active branch context',
    (tester) async {
      _setWideViewport(tester);
      addTearDown(() => _resetViewport(tester));

      final session = _tenantSessionWithoutActiveBranch();
      final container = ProviderContainer(
        overrides: [
          initialAuthSessionProvider.overrideWithValue(session),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(session),
          ),
          operationalNotificationRepositoryProvider.overrideWithValue(
            _FakeOperationalNotificationRepository(items: [_notification()]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(appRouterProvider).go(AppRoute.notifications.path);
      await tester.pumpWidget(_routerHarness(container));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Void approval needed'), findsOneWidget);
      expect(
        find.textContaining('Main Branch', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Page not found'), findsNothing);
    },
  );
}
