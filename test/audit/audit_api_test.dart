import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/audit/data/audit_api.dart';
import 'package:modular_pos/features/audit/domain/models/audit_event.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    dotenv.testLoad();
    registerFallbackValue(Options());
  });

  test('AuditApi.listEvents parses audit event page', () async {
    final dio = _MockDio();
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        data: {
          'success': true,
          'data': {
            'items': [
              {
                'id': 'event-1',
                'tenantId': 'tenant-1',
                'branchId': 'branch-1',
                'actorAccountId': 'account-1',
                'actorDisplayName': 'Sok Dara',
                'actionKey': 'attendance.checkIn',
                'outcome': 'SUCCESS',
                'reasonCode': null,
                'entityType': 'attendance_record',
                'entityId': 'record-1',
                'metadata': {
                  'replayed': false,
                  'endpoint': '/v0/attendance/check-in',
                },
                'createdAt': '2026-02-15T12:00:00.000Z',
              },
            ],
            'limit': 50,
            'offset': 0,
            'total': 1,
            'hasMore': false,
          },
        },
        requestOptions: RequestOptions(path: '/v0/audit/events'),
      ),
    );

    final api = AuditApi(dio);

    final page = await api.listEvents(
      branchId: 'branch-1',
      actionKey: 'attendance.checkIn',
      outcome: AuditOutcome.success,
    );

    expect(page.limit, 50);
    expect(page.total, 1);
    expect(page.hasMore, isFalse);
    expect(page.items, hasLength(1));
    final item = page.items.first;
    expect(item.id, 'event-1');
    expect(item.actionKey, 'attendance.checkIn');
    expect(item.actorDisplayName, 'Sok Dara');
    expect(item.outcome, 'SUCCESS');
    expect(item.metadata['replayed'], isFalse);
    expect(item.entityType, 'attendance_record');
  });
}
