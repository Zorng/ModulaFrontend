import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/notification/data/operational_notification_api.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';

abstract class OperationalNotificationRepository {
  Future<OperationalNotificationInboxPage> listInbox({
    bool unreadOnly = false,
    String? type,
    int limit = 50,
    int offset = 0,
  });

  Future<int> getUnreadCount();

  Future<OperationalNotificationItem> getNotificationById(
    String notificationId,
  );

  Future<OperationalNotificationReadResult> markNotificationAsRead(
    String notificationId,
  );

  Future<OperationalNotificationMarkAllReadResult> markAllAsRead();
}

final operationalNotificationRepositoryProvider =
    Provider<OperationalNotificationRepository>((ref) {
      final api = ref.read(operationalNotificationApiProvider);
      return RemoteOperationalNotificationRepository(api);
    });

class RemoteOperationalNotificationRepository
    implements OperationalNotificationRepository {
  const RemoteOperationalNotificationRepository(this._api);

  final OperationalNotificationApi _api;

  @override
  Future<OperationalNotificationInboxPage> listInbox({
    bool unreadOnly = false,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    final dto = await _api.listInbox(
      unreadOnly: unreadOnly,
      type: type,
      limit: limit,
      offset: offset,
    );
    return OperationalNotificationInboxPage(
      items: dto.items.map(_toItem).toList(growable: false),
      limit: dto.limit,
      offset: dto.offset,
      total: dto.total,
      hasMore: dto.hasMore,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    final dto = await _api.getUnreadCount();
    return dto.unreadCount;
  }

  @override
  Future<OperationalNotificationItem> getNotificationById(
    String notificationId,
  ) async {
    final dto = await _api.getNotificationById(notificationId);
    return _toItem(dto);
  }

  @override
  Future<OperationalNotificationReadResult> markNotificationAsRead(
    String notificationId,
  ) async {
    final dto = await _api.markNotificationAsRead(notificationId);
    return OperationalNotificationReadResult(
      notificationId: dto.notificationId,
      isRead: dto.isRead,
      readAt: _asDateTime(dto.readAt),
    );
  }

  @override
  Future<OperationalNotificationMarkAllReadResult> markAllAsRead() async {
    final dto = await _api.markAllAsRead();
    return OperationalNotificationMarkAllReadResult(
      updatedCount: dto.updatedCount,
    );
  }

  OperationalNotificationItem _toItem(dynamic dto) {
    return OperationalNotificationItem(
      id: dto.id,
      tenantId: dto.tenantId,
      branchId: dto.branchId,
      type: OperationalNotificationTypes.normalize(dto.type),
      subjectType: OperationalNotificationSubjectTypes.normalize(
        dto.subjectType,
      ),
      subjectId: dto.subjectId,
      title: dto.title,
      body: dto.body,
      dedupeKey: dto.dedupeKey,
      payload: dto.payload,
      createdAt:
          _asDateTime(dto.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      isRead: dto.isRead,
      readAt: _asDateTime(dto.readAt),
    );
  }

  DateTime? _asDateTime(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    return DateTime.tryParse(value!);
  }
}
