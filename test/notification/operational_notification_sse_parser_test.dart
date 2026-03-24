import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/notification/data/operational_notification_sse_parser.dart';
import 'package:modular_pos/features/notification/data/operational_notification_stream_contract.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';

void main() {
  test('parser handles chunked ready and notification.created events', () {
    final parser = OperationalNotificationSseParser();

    final firstChunk = parser.addChunk(
      ': keep-alive\n\n'
      'event: ready\n'
      'data: {"unreadCount":2,',
    );
    expect(firstChunk, isEmpty);

    final secondChunk = parser.addChunk(
      '"serverTime":"2026-03-23T10:00:00.000Z"}\n\n'
      'event: notification.created\n'
      'data: {"notificationId":"notif-1","tenantId":"tenant-1","tenantName":"Tenant 1","branchId":"branch-1","branchName":"Main Branch",'
      '"notificationType":"VOID_APPROVAL_NEEDED","subjectType":"SALE","subjectId":"sale-1",'
      '"title":"Void approval needed","body":"Sale requires approval.",'
      '"payload":{"saleId":"sale-1"},"createdAt":"2026-03-23T10:01:00.000Z","unreadCount":3}\n\n',
    );

    expect(secondChunk, hasLength(2));
    final ready = secondChunk.first as OperationalNotificationStreamReadyEvent;
    expect(ready.unreadCount, 2);
    expect(ready.serverTime, DateTime.parse('2026-03-23T10:00:00.000Z'));

    final created =
        secondChunk.last as OperationalNotificationStreamCreatedEvent;
    expect(created.unreadCount, 3);
    expect(created.notification.id, 'notif-1');
    expect(
      created.notification.type,
      OperationalNotificationTypes.voidApprovalNeeded,
    );
    expect(created.notification.tenantName, 'Tenant 1');
    expect(created.notification.branchName, 'Main Branch');
    expect(created.notification.payload, {'saleId': 'sale-1'});
  });
}
