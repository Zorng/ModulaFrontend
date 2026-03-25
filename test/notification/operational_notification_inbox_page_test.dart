import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
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

class _SwitchingLoginController extends LoginController {
  _SwitchingLoginController({
    required this.initialSession,
    this.onSelectTenant,
    this.onSelectBranch,
  });

  final AuthSession initialSession;
  final Future<bool> Function(
    _SwitchingLoginController controller,
    String tenantId,
  )?
  onSelectTenant;
  final Future<void> Function(
    _SwitchingLoginController controller,
    String branchId,
  )?
  onSelectBranch;
  final List<String> selectedTenants = <String>[];
  final List<String> selectedBranches = <String>[];

  @override
  LoginState build() => LoginState(session: initialSession);

  @override
  Future<bool> selectTenant(String tenantId) async {
    selectedTenants.add(tenantId);
    if (onSelectTenant != null) {
      return onSelectTenant!(this, tenantId);
    }
    return true;
  }

  @override
  Future<void> selectBranch(String branchId) async {
    selectedBranches.add(branchId);
    if (onSelectBranch != null) {
      await onSelectBranch!(this, branchId);
    }
  }

  void setSession(AuthSession session) {
    state = state.copyWith(
      isLoading: false,
      session: session,
      error: null,
      errorCode: null,
      errorStatusCode: null,
      branchOptions: const [],
      requiresBranchSelection: false,
    );
  }

  void setBranchOverride(String branchId, String branchName) {
    ref.read(authActiveBranchOverrideProvider.notifier).setOverride(branchId);
    ref.read(authActiveBranchNameOverrideProvider.notifier).setName(branchName);
  }

  void setError(String message, {String code = 'TEST_ERROR'}) {
    state = state.copyWith(
      isLoading: false,
      error: message,
      errorCode: code,
      errorStatusCode: 400,
    );
  }
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
    String? tenantId,
    String? branchId,
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

AuthSession _tenantOnlySession() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: 'ADMIN',
      tenantId: 'tenant-1',
      branches: const <UserBranch>[],
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

AuthSession _accountScopedSessionWithoutTenantSelection() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: 'ADMIN',
      tenantId: '',
      branches: const <UserBranch>[],
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

OperationalNotificationItem _notification({
  required String id,
  String type = OperationalNotificationTypes.voidApprovalNeeded,
  bool isRead = false,
  String subjectType = OperationalNotificationSubjectTypes.sale,
  String? subjectId,
  Map<String, dynamic>? payload,
  String tenantId = 'tenant-1',
  String tenantName = 'Tenant 1',
  String branchId = 'branch-1',
  String? branchName = 'Main Branch',
}) {
  return OperationalNotificationItem(
    id: id,
    tenantId: tenantId,
    tenantName: tenantName,
    branchId: branchId,
    branchName: branchName,
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

Widget _pageHarness(
  OperationalNotificationRepository repository, {
  AuthSession? session,
  LoginController? controller,
}) {
  final resolvedSession = session ?? _session();
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => controller ?? _StaticLoginController(resolvedSession),
      ),
      initialAuthSessionProvider.overrideWithValue(resolvedSession),
      operationalNotificationRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(
      home: notification_view.OperationalNotificationInboxPage(),
    ),
  );
}

Widget _actionRouterHarness(
  OperationalNotificationRepository repository, {
  AuthSession? session,
  LoginController? controller,
}) {
  final resolvedSession = session ?? _session();
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
        () => controller ?? _StaticLoginController(resolvedSession),
      ),
      initialAuthSessionProvider.overrideWithValue(resolvedSession),
      operationalNotificationRepositoryProvider.overrideWithValue(repository),
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

void _resetSurface(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
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

  testWidgets('notification action shows badge and opens wide dialog', (
    tester,
  ) async {
    _setWideSurface(tester);
    addTearDown(() => _resetSurface(tester));

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

    expect(
      find.byKey(notification_view.operationalNotificationInboxDialogKey),
      findsOneWidget,
    );
    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Notification 1'), findsOneWidget);
  });

  testWidgets('notification action opens bottom sheet on small screens', (
    tester,
  ) async {
    _setSmallSurface(tester);
    addTearDown(() => _resetSurface(tester));

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

    expect(
      find.byKey(notification_view.operationalNotificationInboxBottomSheetKey),
      findsOneWidget,
    );
    expect(find.text('Notification 1'), findsOneWidget);
  });

  testWidgets(
    'notification action remains visible without an active branch context',
    (tester) async {
      await tester.pumpWidget(
        _actionRouterHarness(
          _FakeOperationalNotificationRepository(
            items: [_notification(id: '1')],
            unreadCount: 2,
          ),
          session: _tenantOnlySession(),
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
      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets(
    'notifications page loads account-level inbox before tenant selection',
    (tester) async {
      await tester.pumpWidget(
        _pageHarness(
          _FakeOperationalNotificationRepository(
            items: [_notification(id: '1')],
            unreadCount: 1,
          ),
          session: _accountScopedSessionWithoutTenantSelection(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification 1'), findsOneWidget);
      expect(
        find.textContaining('Tenant 1', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Main Branch', findRichText: true),
        findsOneWidget,
      );
    },
  );

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

  testWidgets(
    'void action prompts before switching context when workspace differs',
    (tester) async {
      _setWideSurface(tester);
      addTearDown(() => _resetSurface(tester));

      final initialSession = _accountScopedSessionWithoutTenantSelection();
      final controller = _SwitchingLoginController(
        initialSession: initialSession,
        onSelectTenant: (controller, tenantId) async {
          controller.setSession(
            AuthSession(
              user: initialSession.user.copyWith(tenantId: tenantId),
              memberships: initialSession.memberships,
              activeTenantId: tenantId,
              accessToken: initialSession.accessToken,
              refreshToken: initialSession.refreshToken,
              accessTokenExpiresAt: initialSession.accessTokenExpiresAt,
              refreshTokenExpiresAt: initialSession.refreshTokenExpiresAt,
            ),
          );
          return true;
        },
        onSelectBranch: (controller, branchId) async {
          controller.setSession(_session());
          controller.setBranchOverride(branchId, 'Main Branch');
        },
      );

      await tester.pumpWidget(
        _actionRouterHarness(
          _FakeOperationalNotificationRepository(
            items: [_notification(id: '1')],
            unreadCount: 1,
          ),
          session: initialSession,
          controller: controller,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('operational_notification_inbox_action')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open carts'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(notification_view.operationalNotificationHandoffDialogKey),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Switch to Tenant 1 / Main Branch to review this void request?',
        ),
        findsOneWidget,
      );
      expect(find.text('Sale route VOID_PENDING'), findsNothing);

      await tester.tap(find.text('Switch and open'));
      await tester.pumpAndSettle();

      expect(controller.selectedTenants, ['tenant-1']);
      expect(controller.selectedBranches, ['branch-1']);
      expect(find.text('Sale route VOID_PENDING'), findsOneWidget);
    },
  );

  testWidgets('void action shows failure when notification access is stale', (
    tester,
  ) async {
    _setWideSurface(tester);
    addTearDown(() => _resetSurface(tester));

    final deniedSession = AuthSession(
      user: User(
        id: 'user-1',
        name: 'Tester',
        role: 'ADMIN',
        tenantId: '',
        branches: const <UserBranch>[],
      ),
      memberships: const <TenantMembership>[
        TenantMembership(
          membershipId: 'membership-2',
          tenantId: 'tenant-2',
          tenantName: 'Tenant 2',
          role: 'ADMIN',
          branches: <UserBranch>[],
        ),
      ],
      activeTenantId: null,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      accessTokenExpiresAt: DateTime.now().toUtc().add(
        const Duration(hours: 1),
      ),
      refreshTokenExpiresAt: DateTime.now().toUtc().add(
        const Duration(days: 1),
      ),
      tenantSelectionToken: 'selection-token',
    );

    await tester.pumpWidget(
      _actionRouterHarness(
        _FakeOperationalNotificationRepository(
          items: [_notification(id: '4')],
          unreadCount: 1,
        ),
        session: deniedSession,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('operational_notification_inbox_action')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open carts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch and open'));
    await tester.pumpAndSettle();

    expect(find.text('You can no longer open these carts.'), findsWidgets);
    expect(find.text('Sale route VOID_PENDING'), findsNothing);
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

    expect(
      find.byKey(notification_view.operationalNotificationHandoffDialogKey),
      findsNothing,
    );
    expect(find.text('Cash session session-1'), findsOneWidget);
  });

  testWidgets(
    'cash session action prompts before switching context when workspace differs',
    (tester) async {
      _setWideSurface(tester);
      addTearDown(() => _resetSurface(tester));

      final initialSession = _accountScopedSessionWithoutTenantSelection();
      final controller = _SwitchingLoginController(
        initialSession: initialSession,
        onSelectTenant: (controller, tenantId) async {
          controller.setSession(
            AuthSession(
              user: initialSession.user.copyWith(tenantId: tenantId),
              memberships: initialSession.memberships,
              activeTenantId: tenantId,
              accessToken: initialSession.accessToken,
              refreshToken: initialSession.refreshToken,
              accessTokenExpiresAt: initialSession.accessTokenExpiresAt,
              refreshTokenExpiresAt: initialSession.refreshTokenExpiresAt,
            ),
          );
          return true;
        },
        onSelectBranch: (controller, branchId) async {
          controller.setSession(_session());
          controller.setBranchOverride(branchId, 'Main Branch');
        },
      );

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
          session: initialSession,
          controller: controller,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('operational_notification_inbox_action')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View session'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(notification_view.operationalNotificationHandoffDialogKey),
        findsOneWidget,
      );
      expect(find.text('Switch workspace?'), findsOneWidget);
      expect(
        find.textContaining(
          'Switch to Tenant 1 / Main Branch to view this closed session?',
        ),
        findsOneWidget,
      );
      expect(find.text('Cash session session-1'), findsNothing);

      await tester.tap(find.text('Switch and view'));
      await tester.pumpAndSettle();

      expect(controller.selectedTenants, ['tenant-1']);
      expect(controller.selectedBranches, ['branch-1']);
      expect(find.text('Cash session session-1'), findsOneWidget);
    },
  );

  testWidgets(
    'cash session action shows failure when notification access is stale',
    (tester) async {
      _setWideSurface(tester);
      addTearDown(() => _resetSurface(tester));

      final deniedSession = AuthSession(
        user: User(
          id: 'user-1',
          name: 'Tester',
          role: 'ADMIN',
          tenantId: '',
          branches: const <UserBranch>[],
        ),
        memberships: const <TenantMembership>[
          TenantMembership(
            membershipId: 'membership-2',
            tenantId: 'tenant-2',
            tenantName: 'Tenant 2',
            role: 'ADMIN',
            branches: <UserBranch>[],
          ),
        ],
        activeTenantId: null,
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        accessTokenExpiresAt: DateTime.now().toUtc().add(
          const Duration(hours: 1),
        ),
        refreshTokenExpiresAt: DateTime.now().toUtc().add(
          const Duration(days: 1),
        ),
        tenantSelectionToken: 'selection-token',
      );

      await tester.pumpWidget(
        _actionRouterHarness(
          _FakeOperationalNotificationRepository(
            items: [
              _notification(
                id: '3',
                type: OperationalNotificationTypes.cashSessionClosed,
                subjectType: OperationalNotificationSubjectTypes.cashSession,
                subjectId: 'session-2',
                payload: const {'sessionId': 'session-2'},
              ),
            ],
            unreadCount: 1,
          ),
          session: deniedSession,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('operational_notification_inbox_action')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch and view'));
      await tester.pumpAndSettle();

      expect(
        find.text('You can no longer view this closed session.'),
        findsWidgets,
      );
      expect(find.text('Cash session session-2'), findsNothing);
    },
  );
}
