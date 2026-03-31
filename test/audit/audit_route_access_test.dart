import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/app.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/app_navigation_config.dart';
import 'package:modular_pos/core/widgets/navigation/app_navigation_portal_content.dart';
import 'package:modular_pos/features/audit/data/audit_repository.dart';
import 'package:modular_pos/features/audit/domain/models/audit_event.dart';
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

class _StaticAuditRepository implements AuditRepository {
  const _StaticAuditRepository({required this.items});

  final List<AuditEvent> items;

  @override
  Future<AuditEventPage> listEvents({
    String? branchId,
    String? actionKey,
    AuditOutcome? outcome,
    int limit = 50,
    int offset = 0,
  }) async {
    return AuditEventPage(
      items: items,
      limit: limit,
      offset: offset,
      total: items.length,
      hasMore: false,
    );
  }
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

AuthSession _session(String role) {
  const branch = UserBranch(
    id: 'assign-1',
    name: 'Main Branch',
    role: 'admin',
    active: false,
    branchId: 'branch-1',
  );

  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'User',
      role: role,
      tenantId: 'tenant-1',
      branches: const [branch],
    ),
    memberships: [
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: role,
        branches: const [branch],
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
}

AuditEvent _event() {
  return AuditEvent(
    id: 'event-1',
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    actorAccountId: 'actor-1',
    actorDisplayName: 'Cashier Dara',
    actionKey: 'attendance.checkIn',
    outcome: AuditOutcome.success,
    reasonCode: null,
    entityType: 'attendance_record',
    entityId: 'record-1',
    metadata: const {'replayed': false},
    createdAt: DateTime.utc(2026, 4, 1, 9, 0),
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

Widget _portalHarness(AuthSession session) {
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(session),
      ),
      auditRepositoryProvider.overrideWithValue(
        _StaticAuditRepository(items: [_event()]),
      ),
      operationalNotificationRepositoryProvider.overrideWithValue(
        const _FakeOperationalNotificationRepository(),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: AppNavigationPortalContent(layer: AppNavigationLayer.tenant),
      ),
    ),
  );
}

void _setWideViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1024);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  testWidgets('admin can open audit route without branch context', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    final session = _session('ADMIN');
    final container = ProviderContainer(
      overrides: [
        initialAuthSessionProvider.overrideWithValue(session),
        loginControllerProvider.overrideWith(
          () => _StaticLoginController(session),
        ),
        auditRepositoryProvider.overrideWithValue(
          _StaticAuditRepository(items: [_event()]),
        ),
        operationalNotificationRepositoryProvider.overrideWithValue(
          const _FakeOperationalNotificationRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(appRouterProvider).go(AppRoute.audit.path);
    await tester.pumpWidget(_routerHarness(container));
    await tester.pumpAndSettle();

    expect(find.textContaining('attendance.checkIn'), findsWidgets);
    expect(find.text('View details'), findsOneWidget);
    expect(find.text('Page not found'), findsNothing);
  });

  testWidgets('manager is denied from audit route', (tester) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    final session = _session('MANAGER');
    final container = ProviderContainer(
      overrides: [
        initialAuthSessionProvider.overrideWithValue(session),
        loginControllerProvider.overrideWith(
          () => _StaticLoginController(session),
        ),
        auditRepositoryProvider.overrideWithValue(
          _StaticAuditRepository(items: [_event()]),
        ),
        operationalNotificationRepositoryProvider.overrideWithValue(
          const _FakeOperationalNotificationRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(appRouterProvider).go(AppRoute.audit.path);
    await tester.pumpWidget(_routerHarness(container));
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
  });

  testWidgets('tenant portal shows audit destination for admin', (
    tester,
  ) async {
    await tester.pumpWidget(_portalHarness(_session('ADMIN')));
    await tester.pumpAndSettle();

    expect(find.text('Audit Log'), findsOneWidget);
  });

  testWidgets('tenant portal hides audit destination for manager', (
    tester,
  ) async {
    await tester.pumpWidget(_portalHarness(_session('MANAGER')));
    await tester.pumpAndSettle();

    expect(find.text('Audit Log'), findsNothing);
  });
}
