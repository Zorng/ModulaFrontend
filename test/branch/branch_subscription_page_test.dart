import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/sync/global_sync_status.dart';
import 'package:modular_pos/core/widgets/navigation/account_shell_action.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_workspace_app_bar_actions.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/branch_subscription/ui/view/branch_subscription_page.dart';
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

AuthSession _session() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tenant User',
      role: 'OWNER',
      tenantId: 'tenant-001',
    ),
    memberships: const [],
    activeTenantId: 'tenant-001',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
}

Widget _harness() {
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
    child: const MaterialApp(home: BranchSubscriptionPage()),
  );
}

void _setWideSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 1000);
}

void main() {
  testWidgets('branch subscription uses tenant workspace app bar actions', (
    tester,
  ) async {
    _setWideSurface(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Branch Subscription'), findsOneWidget);
    expect(find.byType(TenantWorkspaceAppBarActions), findsOneWidget);
    expect(
      find.byKey(const Key('operational_notification_inbox_action')),
      findsOneWidget,
    );
    expect(find.byKey(AccountShellAction.actionKey), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
  });
}
