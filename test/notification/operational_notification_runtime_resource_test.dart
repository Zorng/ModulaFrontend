import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/notification/data/operational_notification_repository.dart';
import 'package:modular_pos/features/notification/data/operational_notification_runtime_resource.dart';
import 'package:modular_pos/features/notification/data/operational_notification_stream_contract.dart';
import 'package:modular_pos/features/notification/data/operational_notification_stream_client.dart';
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
  int unreadCount;
  int listCalls = 0;

  @override
  Future<OperationalNotificationInboxPage> listInbox({
    bool unreadOnly = false,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    listCalls += 1;
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
    throw UnimplementedError();
  }

  @override
  Future<OperationalNotificationMarkAllReadResult> markAllAsRead() async {
    throw UnimplementedError();
  }
}

class _FakeOperationalNotificationStreamClient
    implements OperationalNotificationStreamClient {
  final List<_FakeOperationalNotificationStreamConnection> connections =
      <_FakeOperationalNotificationStreamConnection>[];
  int connectCalls = 0;

  @override
  bool get isSupported => true;

  @override
  Future<OperationalNotificationStreamConnection> connect({
    required String accessToken,
    required String tenantId,
    required String branchId,
  }) async {
    connectCalls += 1;
    final connection = _FakeOperationalNotificationStreamConnection();
    connections.add(connection);
    return connection;
  }
}

class _FakeOperationalNotificationStreamConnection
    implements OperationalNotificationStreamConnection {
  final StreamController<OperationalNotificationRealtimeEvent> _controller =
      StreamController<OperationalNotificationRealtimeEvent>.broadcast();

  bool isClosed = false;

  @override
  Stream<OperationalNotificationRealtimeEvent> get events => _controller.stream;

  @override
  Future<void> close() async {
    isClosed = true;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  void emit(OperationalNotificationRealtimeEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  Future<void> closeFromServer() async {
    if (_controller.isClosed) return;
    await _controller.close();
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
}) {
  return OperationalNotificationItem(
    id: id,
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    type: type,
    subjectType: OperationalNotificationSubjectTypes.sale,
    subjectId: 'sale-$id',
    title: 'Notification $id',
    body: 'Body $id',
    dedupeKey: 'dedupe-$id',
    payload: {'id': id},
    createdAt: DateTime.utc(2026, 3, 23, 9, 0),
    isRead: false,
    readAt: null,
  );
}

void main() {
  test(
    'runtime resource applies ready and created events to controllers',
    () async {
      final repository = _FakeOperationalNotificationRepository(
        items: const <OperationalNotificationItem>[],
        unreadCount: 0,
      );
      final streamClient = _FakeOperationalNotificationStreamClient();
      final container = createTestContainer(
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session()),
          operationalNotificationRepositoryProvider.overrideWithValue(
            repository,
          ),
          operationalNotificationStreamClientProvider.overrideWithValue(
            streamClient,
          ),
        ],
      );

      await container.read(
        operationalNotificationUnreadCountControllerProvider.future,
      );
      await container.read(
        operationalNotificationInboxControllerProvider.future,
      );

      final resource =
          container.read(operationalNotificationRuntimeResourceProvider)
              as OperationalNotificationRuntimeResource;
      await resource.onContextChanged(
        accessToken: 'access-token',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      );

      expect(streamClient.connectCalls, 1);
      final connection = streamClient.connections.single;
      connection.emit(
        const OperationalNotificationStreamReadyEvent(unreadCount: 2),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        container
            .read(operationalNotificationUnreadCountControllerProvider)
            .requireValue,
        2,
      );

      connection.emit(
        OperationalNotificationStreamCreatedEvent(
          notification: _notification(id: 'notif-1'),
          unreadCount: 3,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final inbox = container
          .read(operationalNotificationInboxControllerProvider)
          .requireValue;
      expect(
        container
            .read(operationalNotificationUnreadCountControllerProvider)
            .requireValue,
        3,
      );
      expect(inbox.items, hasLength(1));
      expect(inbox.items.single.id, 'notif-1');
    },
  );

  test(
    'runtime resource reconnects and refreshes loaded inbox on ready',
    () async {
      final repository = _FakeOperationalNotificationRepository(
        items: [_notification(id: 'existing')],
        unreadCount: 1,
      );
      final streamClient = _FakeOperationalNotificationStreamClient();
      final container = createTestContainer(
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session()),
          operationalNotificationRepositoryProvider.overrideWithValue(
            repository,
          ),
          operationalNotificationStreamClientProvider.overrideWithValue(
            streamClient,
          ),
          operationalNotificationRealtimeReconnectDelayProvider
              .overrideWithValue((_) => Duration.zero),
        ],
      );

      await container.read(
        operationalNotificationInboxControllerProvider.future,
      );
      await container.read(
        operationalNotificationUnreadCountControllerProvider.future,
      );
      expect(repository.listCalls, 1);

      final resource =
          container.read(operationalNotificationRuntimeResourceProvider)
              as OperationalNotificationRuntimeResource;
      await resource.onContextChanged(
        accessToken: 'access-token',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      );

      expect(streamClient.connectCalls, 1);
      await streamClient.connections.first.closeFromServer();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(streamClient.connectCalls, 2);
      streamClient.connections.last.emit(
        const OperationalNotificationStreamReadyEvent(unreadCount: 2),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.listCalls, greaterThanOrEqualTo(2));
      expect(
        container
            .read(operationalNotificationUnreadCountControllerProvider)
            .requireValue,
        2,
      );
    },
  );
}
