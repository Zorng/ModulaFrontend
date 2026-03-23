import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/notification/data/dto/operational_notification_dto.dart';
import 'package:modular_pos/features/notification/data/operational_notification_api.dart';
import 'package:modular_pos/features/notification/data/operational_notification_repository.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';

class _MockOperationalNotificationApi extends Mock
    implements OperationalNotificationApi {}

void main() {
  test('repository maps dto responses into domain models', () async {
    final api = _MockOperationalNotificationApi();
    when(
      () => api.listInbox(
        unreadOnly: any(named: 'unreadOnly'),
        type: any(named: 'type'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => const OperationalNotificationInboxPageDto(
        items: [
          OperationalNotificationItemDto(
            id: 'notif-1',
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            type: 'VOID_APPROVED',
            subjectType: 'SALE',
            subjectId: 'sale-1',
            title: 'Void approved',
            body: 'Sale #001 was approved.',
            dedupeKey: 'VOID_APPROVED:sale-1',
            payload: {'saleId': 'sale-1'},
            createdAt: '2026-03-23T09:00:00.000Z',
            isRead: false,
            readAt: null,
          ),
        ],
        limit: 50,
        offset: 0,
        total: 1,
        hasMore: false,
      ),
    );
    when(() => api.getUnreadCount()).thenAnswer(
      (_) async => const OperationalNotificationUnreadCountDto(unreadCount: 2),
    );
    when(() => api.getNotificationById(any())).thenAnswer(
      (_) async => const OperationalNotificationItemDto(
        id: 'notif-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        type: 'VOID_APPROVED',
        subjectType: 'SALE',
        subjectId: 'sale-1',
        title: 'Void approved',
        body: 'Sale #001 was approved.',
        dedupeKey: 'VOID_APPROVED:sale-1',
        payload: {'saleId': 'sale-1'},
        createdAt: '2026-03-23T09:00:00.000Z',
        isRead: false,
        readAt: null,
      ),
    );
    when(() => api.markNotificationAsRead(any())).thenAnswer(
      (_) async => const OperationalNotificationReadResultDto(
        notificationId: 'notif-1',
        isRead: true,
        readAt: '2026-03-23T09:01:00.000Z',
      ),
    );
    when(() => api.markAllAsRead()).thenAnswer(
      (_) async =>
          const OperationalNotificationMarkAllReadResultDto(updatedCount: 4),
    );

    final repository = RemoteOperationalNotificationRepository(api);

    final page = await repository.listInbox();
    final unreadCount = await repository.getUnreadCount();
    final detail = await repository.getNotificationById('notif-1');
    final readResult = await repository.markNotificationAsRead('notif-1');
    final markAllResult = await repository.markAllAsRead();

    expect(page.items, hasLength(1));
    expect(page.items.single.type, OperationalNotificationTypes.voidApproved);
    expect(
      page.items.single.subjectType,
      OperationalNotificationSubjectTypes.sale,
    );
    expect(page.items.single.payload, {'saleId': 'sale-1'});
    expect(unreadCount, 2);
    expect(detail.id, 'notif-1');
    expect(readResult.isRead, isTrue);
    expect(readResult.readAt, DateTime.parse('2026-03-23T09:01:00.000Z'));
    expect(markAllResult.updatedCount, 4);
  });
}
