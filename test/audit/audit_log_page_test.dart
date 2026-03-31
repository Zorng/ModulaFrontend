import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_workspace_app_bar_actions.dart';
import 'package:modular_pos/features/audit/data/audit_repository.dart';
import 'package:modular_pos/features/audit/domain/models/audit_event.dart';
import 'package:modular_pos/features/audit/ui/view/audit_log_page.dart';
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
  const _StaticAuditRepository(this.page);

  final AuditEventPage page;

  @override
  Future<AuditEventPage> listEvents({
    String? branchId,
    String? actionKey,
    AuditOutcome? outcome,
    int limit = 50,
    int offset = 0,
  }) async {
    return page;
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

AuthSession _session() {
  const branch = UserBranch(
    id: 'assign-1',
    name: 'Main Branch',
    role: 'admin',
    active: true,
    branchId: 'branch-1',
  );

  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Admin User',
      role: 'ADMIN',
      tenantId: 'tenant-1',
      branches: const [branch],
    ),
    memberships: const [
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: 'ADMIN',
        branches: [branch],
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime(2026, 4, 1),
    refreshTokenExpiresAt: DateTime(2026, 4, 8),
  );
}

AuditEventPage _page() {
  return AuditEventPage(
    items: [
      AuditEvent(
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
        metadata: const {
          'endpoint': '/v0/attendance/check-in',
          'replayed': false,
        },
        createdAt: DateTime.utc(2026, 4, 1, 8, 0),
      ),
    ],
    limit: 50,
    offset: 0,
    total: 75,
    hasMore: true,
  );
}

void _setWideViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 900);
}

void _setSmallViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Widget _harness() {
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(_session()),
      ),
      auditRepositoryProvider.overrideWithValue(
        _StaticAuditRepository(_page()),
      ),
      operationalNotificationRepositoryProvider.overrideWithValue(
        const _FakeOperationalNotificationRepository(),
      ),
    ],
    child: const MaterialApp(home: AuditLogPage()),
  );
}

void main() {
  testWidgets('wide audit page shows event and metadata dialog', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Audit Log'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(TenantWorkspaceAppBarActions), findsOneWidget);
    expect(find.textContaining('all branches'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('attendance.checkIn'), findsWidgets);
    expect(
      find.textContaining('Cashier Dara', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('actor-1', findRichText: true), findsNothing);
    expect(find.textContaining('Showing 1-1 entries'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);

    final viewDetailsButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'View details').first,
    );
    viewDetailsButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('Audit Event'), findsOneWidget);
    expect(find.text('Actor account ID'), findsOneWidget);
    expect(find.text('actor-1'), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
    expect(find.textContaining('/v0/attendance/check-in'), findsOneWidget);
  });

  testWidgets('small audit page opens details in a bottom sheet', (
    tester,
  ) async {
    _setSmallViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.byType(TenantWorkspaceAppBarActions), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View details').last);
    await tester.pumpAndSettle();

    expect(find.text('Audit Event'), findsOneWidget);
    expect(find.textContaining('record-1'), findsOneWidget);
  });
}
