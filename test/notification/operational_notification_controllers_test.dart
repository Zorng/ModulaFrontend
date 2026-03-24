import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/notification/data/operational_notification_repository.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';
import 'package:modular_pos/features/notification/ui/viewmodels/operational_notification_inbox_controller.dart';
import 'package:modular_pos/features/notification/ui/viewmodels/operational_notification_unread_count_controller.dart';

import '../test_utils/riverpod_test_utils.dart';

class _FakeOperationalNotificationRepository
    implements OperationalNotificationRepository {
  _FakeOperationalNotificationRepository({
    List<OperationalNotificationItem> items =
        const <OperationalNotificationItem>[],
    this.unreadCount = 0,
  }) : _items = items.toList(growable: true);

  final List<OperationalNotificationItem> _items;
  Object? listError;
  Object? unreadCountError;
  Object? markReadError;
  Object? markAllError;
  int unreadCount;
  int listCalls = 0;

  @override
  Future<OperationalNotificationInboxPage> listInbox({
    bool unreadOnly = false,
    String? type,
    String? tenantId,
    String? branchId,
    int limit = 50,
    int offset = 0,
  }) async {
    listCalls += 1;
    if (listError != null) throw listError!;
    final filtered = _items
        .where((item) {
          if (unreadOnly && item.isRead) return false;
          if ((type ?? '').trim().isNotEmpty && item.type != type!.trim()) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    final start = offset.clamp(0, filtered.length);
    final end = (start + limit).clamp(0, filtered.length);
    final pageItems = filtered.sublist(start, end);
    return OperationalNotificationInboxPage(
      items: pageItems,
      limit: limit,
      offset: offset,
      total: filtered.length,
      hasMore: end < filtered.length,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    if (unreadCountError != null) throw unreadCountError!;
    return unreadCount;
  }

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
    if (markReadError != null) throw markReadError!;
    final index = _items.indexWhere((item) => item.id == notificationId);
    final current = _items[index];
    final readAt = DateTime.utc(2026, 3, 23, 9, 1);
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
    if (markAllError != null) throw markAllError!;
    var updatedCount = 0;
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].isRead) continue;
      updatedCount += 1;
      _items[i] = _items[i].copyWith(
        isRead: true,
        readAt: DateTime.utc(2026, 3, 23, 9, 2),
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
}) {
  return OperationalNotificationItem(
    id: id,
    tenantId: 'tenant-1',
    tenantName: 'Tenant 1',
    branchId: 'branch-1',
    branchName: 'Main Branch',
    type: type,
    subjectType: OperationalNotificationSubjectTypes.sale,
    subjectId: 'sale-$id',
    title: 'Notification $id',
    body: 'Body $id',
    dedupeKey: 'dedupe-$id',
    payload: {'id': id},
    createdAt: DateTime.utc(2026, 3, 23, 9, 0),
    isRead: isRead,
    readAt: isRead ? DateTime.utc(2026, 3, 23, 9, 1) : null,
  );
}

void main() {
  test('unread count controller loads unread count from repository', () async {
    final repository = _FakeOperationalNotificationRepository(unreadCount: 3);
    final container = createTestContainer(
      overrides: [
        initialAuthSessionProvider.overrideWithValue(_session()),
        operationalNotificationRepositoryProvider.overrideWithValue(repository),
      ],
    );

    final unreadCount = await container.read(
      operationalNotificationUnreadCountControllerProvider.future,
    );

    expect(unreadCount, 3);
  });

  test('pre-tenant session still loads unread count from repository', () async {
    final repository = _FakeOperationalNotificationRepository(unreadCount: 2);
    final baseSession = _session();
    final preTenantSession = baseSession.copyWith(
      activeTenantId: null,
      tenantSelectionToken: 'selection-token',
      user: baseSession.user.copyWith(
        tenantId: '',
        branches: const <UserBranch>[],
      ),
    );
    final container = createTestContainer(
      overrides: [
        initialAuthSessionProvider.overrideWithValue(preTenantSession),
        operationalNotificationRepositoryProvider.overrideWithValue(repository),
      ],
    );

    final unreadCount = await container.read(
      operationalNotificationUnreadCountControllerProvider.future,
    );

    expect(unreadCount, 2);
  });

  test('inbox controller loads notifications from repository', () async {
    final repository = _FakeOperationalNotificationRepository(
      items: [
        _notification(id: '1'),
        _notification(id: '2'),
      ],
      unreadCount: 2,
    );
    final container = createTestContainer(
      overrides: [
        initialAuthSessionProvider.overrideWithValue(_session()),
        operationalNotificationRepositoryProvider.overrideWithValue(repository),
      ],
    );

    final state = await container.read(
      operationalNotificationInboxControllerProvider.future,
    );

    expect(repository.listCalls, 1);
    expect(state.items, hasLength(2));
    expect(state.total, 2);
  });

  test('pre-tenant session still loads account-scoped inbox', () async {
    final repository = _FakeOperationalNotificationRepository(
      items: [_notification(id: '1')],
      unreadCount: 1,
    );
    final session = _session();
    final preTenantSession = session.copyWith(
      activeTenantId: null,
      tenantSelectionToken: 'selection-token',
      user: session.user.copyWith(tenantId: '', branches: const <UserBranch>[]),
    );
    final container = createTestContainer(
      overrides: [
        initialAuthSessionProvider.overrideWithValue(preTenantSession),
        operationalNotificationRepositoryProvider.overrideWithValue(repository),
      ],
    );

    final state = await container.read(
      operationalNotificationInboxControllerProvider.future,
    );

    expect(state.items, hasLength(1));
    expect(state.items.single.tenantName, 'Tenant 1');
    expect(state.items.single.branchName, 'Main Branch');
  });

  test('refresh keeps stale data and exposes inlineError on failure', () async {
    final repository = _FakeOperationalNotificationRepository(
      items: [_notification(id: '1')],
      unreadCount: 1,
    );
    final container = createTestContainer(
      overrides: [
        initialAuthSessionProvider.overrideWithValue(_session()),
        operationalNotificationRepositoryProvider.overrideWithValue(repository),
      ],
    );

    await container.read(operationalNotificationInboxControllerProvider.future);
    repository.listError = const ApiClientException(
      message: 'Failed to load notifications.',
      code: 'INBOX_DOWN',
      statusCode: 503,
    );

    await container
        .read(operationalNotificationInboxControllerProvider.notifier)
        .refresh();

    final state = container
        .read(operationalNotificationInboxControllerProvider)
        .requireValue;
    expect(state.items, hasLength(1));
    expect(state.isRefreshing, isFalse);
    expect(state.inlineError, 'Failed to load notifications.');
  });

  test('loadMore appends the next page', () async {
    final repository = _FakeOperationalNotificationRepository(
      items: List<OperationalNotificationItem>.generate(
        51,
        (index) => _notification(id: '${index + 1}'),
      ),
      unreadCount: 51,
    );
    final container = createTestContainer(
      overrides: [
        initialAuthSessionProvider.overrideWithValue(_session()),
        operationalNotificationRepositoryProvider.overrideWithValue(repository),
      ],
    );

    final current = await container.read(
      operationalNotificationInboxControllerProvider.future,
    );
    expect(current.items, hasLength(50));
    expect(current.hasMore, isTrue);

    await container
        .read(operationalNotificationInboxControllerProvider.notifier)
        .loadMore();

    final state = container
        .read(operationalNotificationInboxControllerProvider)
        .requireValue;
    expect(state.items, hasLength(51));
    expect(state.items.last.id, '51');
  });

  test('markAsRead updates inbox item and unread badge count', () async {
    final repository = _FakeOperationalNotificationRepository(
      items: [_notification(id: '1')],
      unreadCount: 1,
    );
    final container = createTestContainer(
      overrides: [
        initialAuthSessionProvider.overrideWithValue(_session()),
        operationalNotificationRepositoryProvider.overrideWithValue(repository),
      ],
    );

    await container.read(
      operationalNotificationUnreadCountControllerProvider.future,
    );
    final inbox = await container.read(
      operationalNotificationInboxControllerProvider.future,
    );

    final success = await container
        .read(operationalNotificationInboxControllerProvider.notifier)
        .markAsRead(inbox.items.single);

    final updatedInbox = container
        .read(operationalNotificationInboxControllerProvider)
        .requireValue;
    final unreadCount = container
        .read(operationalNotificationUnreadCountControllerProvider)
        .requireValue;
    expect(success, isTrue);
    expect(updatedInbox.items.single.isRead, isTrue);
    expect(unreadCount, 0);
  });

  test(
    'markAllAsRead clears unread-only view and zeroes unread count',
    () async {
      final repository = _FakeOperationalNotificationRepository(
        items: [
          _notification(id: '1'),
          _notification(id: '2'),
        ],
        unreadCount: 2,
      );
      final container = createTestContainer(
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session()),
          operationalNotificationRepositoryProvider.overrideWithValue(
            repository,
          ),
        ],
      );

      await container.read(
        operationalNotificationUnreadCountControllerProvider.future,
      );
      await container.read(
        operationalNotificationInboxControllerProvider.future,
      );
      await container
          .read(operationalNotificationInboxControllerProvider.notifier)
          .applyFilters(unreadOnly: true);

      final updatedCount = await container
          .read(operationalNotificationInboxControllerProvider.notifier)
          .markAllAsRead();

      final inboxState = container
          .read(operationalNotificationInboxControllerProvider)
          .requireValue;
      final unreadCount = container
          .read(operationalNotificationUnreadCountControllerProvider)
          .requireValue;
      expect(updatedCount, 2);
      expect(inboxState.items, isEmpty);
      expect(inboxState.total, 0);
      expect(unreadCount, 0);
    },
  );
}
