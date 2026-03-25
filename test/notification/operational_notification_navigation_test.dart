import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';
import 'package:modular_pos/features/notification/ui/viewmodels/operational_notification_navigation.dart';

void main() {
  test('void approval notifications route to carts with state and date', () {
    final item = OperationalNotificationItem(
      id: 'notif-1',
      tenantId: 'tenant-1',
      tenantName: 'Tenant 1',
      branchId: 'branch-1',
      type: OperationalNotificationTypes.voidApprovalNeeded,
      subjectType: OperationalNotificationSubjectTypes.sale,
      subjectId: 'sale-subject',
      title: 'Void approval needed',
      body: 'Review the void request.',
      dedupeKey: 'dedupe-1',
      payload: const {'saleId': 'sale-1'},
      createdAt: DateTime.utc(2026, 3, 23, 9, 0),
    );

    expect(
      operationalNotificationLocation(item),
      '/sale/carts?state=VOID_PENDING&date=2026-03-23&saleId=sale-1',
    );
    expect(operationalNotificationActionLabel(item), 'Open carts');
    expect(operationalNotificationUsesExplicitContextHandoff(item), isTrue);
    expect(
      operationalNotificationHandoffMessage(item),
      'Switch to Tenant 1 / this branch to review this void request?',
    );
  });

  test('cash session notifications route to session detail when present', () {
    final item = OperationalNotificationItem(
      id: 'notif-2',
      tenantId: 'tenant-1',
      tenantName: 'Tenant 1',
      branchId: 'branch-1',
      type: OperationalNotificationTypes.cashSessionClosed,
      subjectType: OperationalNotificationSubjectTypes.cashSession,
      subjectId: 'session-1',
      title: 'Cash session closed',
      body: 'Closed successfully.',
      dedupeKey: 'dedupe-2',
      createdAt: DateTime.utc(2026, 3, 23, 9, 0),
    );

    expect(
      operationalNotificationLocation(item),
      '/cash/session/history/session-1',
    );
    expect(operationalNotificationActionLabel(item), 'View session');
    expect(operationalNotificationUsesExplicitContextHandoff(item), isTrue);
  });
}
