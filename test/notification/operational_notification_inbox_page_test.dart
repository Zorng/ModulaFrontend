import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/notification/data/operational_notification_repository.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';
import 'package:modular_pos/features/notification/ui/components/operational_notification_inbox_action.dart';
import 'package:modular_pos/features/notification/ui/view/operational_notification_inbox/operational_notification_inbox_page.dart'
    as notification_view;

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession _session;

  @override
  LoginState build() => LoginState(session: _session);
}

class _FakeOperationalNotificationRepository
    implements OperationalNotificationRepository {
  _FakeOperationalNotificationRepository({
    List<OperationalNotificationItem> items =
        const <OperationalNotificationItem>[],
    this.unreadCount = 0,
  }) : _items = items.toList(growable: true);

  final List<OperationalNotificationItem> _items;
  int unreadCount;

  @override
  Future<OperationalNotificationInboxPage> listInbox({
    bool unreadOnly = false,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    final filtered = _items
        .where((item) {
          if (unreadOnly && item.isRead) return false;
          if ((type ?? '').trim().isNotEmpty && item.type != type!.trim()) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    return OperationalNotificationInboxPage(
      items: filtered.skip(offset).take(limit).toList(growable: false),
      limit: limit,
      offset: offset,
      total: filtered.length,
      hasMore: offset + limit < filtered.length,
    );
  }

  @override
  Future<int> getUnreadCount() async => unreadCount;

  @override
  Future<OperationalNotificationItem> getNotificationById(
    String notificationId,
  ) async {
    return _items.firstWhere((item) => item.id == notificationId);
  }

  @override
  Future<OperationalNotificationReadResult> markNotificationAsRead(
    String notificationId,
  ) async {
    final index = _items.indexWhere((item) => item.id == notificationId);
    final current = _items[index];
    final readAt = DateTime.utc(2026, 3, 23, 10, 0);
    _items[index] = current.copyWith(isRead: true, readAt: readAt);
    if (!current.isRead && unreadCount > 0) unreadCount -= 1;
    return OperationalNotificationReadResult(
      notificationId: notificationId,
      isRead: true,
      readAt: readAt,
    );
  }

  @override
  Future<OperationalNotificationMarkAllReadResult> markAllAsRead() async {
    var updatedCount = 0;
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].isRead) continue;
      updatedCount += 1;
      _items[i] = _items[i].copyWith(
        isRead: true,
        readAt: DateTime.utc(2026, 3, 23, 10, 1),
      );
    }
    unreadCount = 0;
    return OperationalNotificationMarkAllReadResult(updatedCount: updatedCount);
  }
}

AuthSession _session() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: 'ADMIN',
      tenantId: 'tenant-1',
      branches: const <UserBranch>[
        UserBranch(
          id: 'assignment-1',
          name: 'Main Branch',
          role: 'ADMIN',
          active: true,
          branchId: 'branch-1',
        ),
      ],
    ),
    memberships: const <TenantMembership>[
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: 'ADMIN',
        branches: <UserBranch>[
          UserBranch(
            id: 'assignment-1',
            name: 'Main Branch',
            role: 'ADMIN',
            active: true,
            branchId: 'branch-1',
          ),
        ],
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
}

OperationalNotificationItem _notification({
  required String id,
  String type = OperationalNotificationTypes.voidApprovalNeeded,
  bool isRead = false,
  String subjectType = OperationalNotificationSubjectTypes.sale,
  String? subjectId,
  Map<String, dynamic>? payload,
}) {
  return OperationalNotificationItem(
    id: id,
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    type: type,
    subjectType: subjectType,
    subjectId: subjectId ?? 'sale-$id',
    title: 'Notification $id',
    body: 'Body $id',
    dedupeKey: 'dedupe-$id',
    payload: payload ?? {'id': id, 'saleId': 'sale-$id'},
    createdAt: DateTime.utc(2026, 3, 23, 9, 0),
    isRead: isRead,
    readAt: isRead ? DateTime.utc(2026, 3, 23, 9, 1) : null,
  );
}

Widget _pageHarness(OperationalNotificationRepository repository) {
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(_session()),
      ),
      initialAuthSessionProvider.overrideWithValue(_session()),
      operationalNotificationRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(
      home: notification_view.OperationalNotificationInboxPage(),
    ),
  );
}

Widget _actionRouterHarness(OperationalNotificationRepository repository) {
  final router = GoRouter(
    initialLocation: '/shell',
    routes: [
      GoRoute(
        path: '/shell',
        builder: (context, state) => Scaffold(
          appBar: AppBar(actions: const [OperationalNotificationInboxAction()]),
          body: const SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: AppRoute.notifications.path,
        builder: (context, state) =>
            const notification_view.OperationalNotificationInboxPage(),
      ),
      GoRoute(
        path: AppRoute.saleViewCarts.path,
        builder: (context, state) => Scaffold(
          body: Text('Sale route ${state.uri.queryParameters['state'] ?? '-'}'),
        ),
      ),
      GoRoute(
        path: AppRoute.cashHistory.path,
        builder: (context, state) =>
            const Scaffold(body: Text('Cash history route')),
        routes: [
          GoRoute(
            path: ':sessionId',
            builder: (context, state) => Scaffold(
              body: Text(
                'Cash session ${state.pathParameters['sessionId'] ?? '-'}',
              ),
            ),
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
      initialAuthSessionProvider.overrideWithValue(_session()),
      operationalNotificationRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('OperationalNotificationInboxPage shows notification cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pageHarness(
        _FakeOperationalNotificationRepository(
          items: [_notification(id: '1')],
          unreadCount: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notification 1'), findsOneWidget);
    expect(find.text('Mark as read'), findsOneWidget);
    expect(find.text('Unread only'), findsOneWidget);
  });

  testWidgets('Unread only filter hides already read notifications', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pageHarness(
        _FakeOperationalNotificationRepository(
          items: [
            _notification(id: '1', isRead: false),
            _notification(id: '2', isRead: true),
          ],
          unreadCount: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notification 1'), findsOneWidget);
    expect(find.text('Notification 2'), findsOneWidget);

    await tester.tap(find.text('Unread only'));
    await tester.pumpAndSettle();

    expect(find.text('Notification 1'), findsOneWidget);
    expect(find.text('Notification 2'), findsNothing);
  });

  testWidgets('notification action shows badge and opens inbox route', (
    tester,
  ) async {
    await tester.pumpWidget(
      _actionRouterHarness(
        _FakeOperationalNotificationRepository(
          items: [_notification(id: '1')],
          unreadCount: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('operational_notification_inbox_action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('operational_notification_unread_badge')),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('operational_notification_inbox_action')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Notification 1'), findsOneWidget);
  });

  testWidgets('open action routes void notifications to sale carts', (
    tester,
  ) async {
    await tester.pumpWidget(
      _actionRouterHarness(
        _FakeOperationalNotificationRepository(
          items: [_notification(id: '1')],
          unreadCount: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('operational_notification_inbox_action')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open carts'));
    await tester.pumpAndSettle();

    expect(find.text('Sale route VOID_PENDING'), findsOneWidget);
  });

  testWidgets('open action routes cash session notifications to detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      _actionRouterHarness(
        _FakeOperationalNotificationRepository(
          items: [
            _notification(
              id: '2',
              type: OperationalNotificationTypes.cashSessionClosed,
              subjectType: OperationalNotificationSubjectTypes.cashSession,
              subjectId: 'session-1',
              payload: const {'sessionId': 'session-1'},
            ),
          ],
          unreadCount: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('operational_notification_inbox_action')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('View session'));
    await tester.pumpAndSettle();

    expect(find.text('Cash session session-1'), findsOneWidget);
  });
}
