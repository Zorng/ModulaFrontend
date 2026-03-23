import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/notification/data/operational_notification_api.dart';

class _MockDio extends Mock implements Dio {}

class _FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeOptions());
  });

  group('OperationalNotificationApi', () {
    test(
      'listInbox forwards canonical query params and parses envelope',
      () async {
        final dio = _MockDio();
        when(
          () => dio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response<dynamic>(
            requestOptions: RequestOptions(path: '/v0/notifications/inbox'),
            data: {
              'success': true,
              'data': {
                'items': [
                  {
                    'id': 'notif-1',
                    'tenantId': 'tenant-1',
                    'branchId': 'branch-1',
                    'type': 'VOID_APPROVAL_NEEDED',
                    'subjectType': 'SALE',
                    'subjectId': 'sale-1',
                    'title': 'Void approval needed',
                    'body': 'Sale #001 is waiting for approval.',
                    'dedupeKey': 'VOID_APPROVAL_NEEDED:sale-1',
                    'payload': {'saleId': 'sale-1'},
                    'createdAt': '2026-03-23T09:00:00.000Z',
                    'isRead': false,
                    'readAt': null,
                  },
                ],
                'limit': 20,
                'offset': 0,
                'total': 1,
                'hasMore': false,
              },
            },
          ),
        );

        final api = OperationalNotificationApi(dio);
        final page = await api.listInbox(
          unreadOnly: true,
          type: 'VOID_APPROVAL_NEEDED',
          limit: 20,
          offset: 0,
        );

        verify(
          () => dio.get<dynamic>(
            '/v0/notifications/inbox',
            queryParameters: {
              'unreadOnly': true,
              'type': 'VOID_APPROVAL_NEEDED',
              'limit': 20,
              'offset': 0,
            },
          ),
        ).called(1);
        expect(page.items, hasLength(1));
        expect(page.items.single.id, 'notif-1');
        expect(page.items.single.payload, {'saleId': 'sale-1'});
        expect(page.total, 1);
      },
    );

    test('getUnreadCount parses unread count envelope', () async {
      final dio = _MockDio();
      when(() => dio.get<dynamic>(any())).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: '/v0/notifications/unread-count',
          ),
          data: {
            'success': true,
            'data': {'unreadCount': 3},
          },
        ),
      );

      final api = OperationalNotificationApi(dio);
      final result = await api.getUnreadCount();

      expect(result.unreadCount, 3);
    });

    test('markNotificationAsRead posts canonical route', () async {
      final dio = _MockDio();
      when(() => dio.post<dynamic>(any())).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: '/v0/notifications/notif-1/read',
          ),
          data: {
            'success': true,
            'data': {
              'notificationId': 'notif-1',
              'isRead': true,
              'readAt': '2026-03-23T09:01:00.000Z',
            },
          },
        ),
      );

      final api = OperationalNotificationApi(dio);
      final result = await api.markNotificationAsRead('notif-1');

      verify(
        () => dio.post<dynamic>('/v0/notifications/notif-1/read'),
      ).called(1);
      expect(result.notificationId, 'notif-1');
      expect(result.isRead, isTrue);
    });

    test('listInbox maps error envelope to ApiClientException', () async {
      final dio = _MockDio();
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioError(
          requestOptions: RequestOptions(path: '/v0/notifications/inbox'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/v0/notifications/inbox'),
            statusCode: 403,
            data: {
              'success': false,
              'error': 'Inbox unavailable',
              'code': 'PERMISSION_DENIED',
            },
          ),
          error: 'forbidden',
          type: DioErrorType.badResponse,
        ),
      );

      final api = OperationalNotificationApi(dio);

      await expectLater(
        () => api.listInbox(),
        throwsA(
          isA<ApiClientException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having((error) => error.code, 'code', 'PERMISSION_DENIED'),
        ),
      );
    });
  });
}
