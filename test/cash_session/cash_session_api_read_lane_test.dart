import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  test('listSessions uses the cash session list read lane and parses items', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/cash/sessions'),
        data: {
          'success': true,
          'data': [
            {
              'id': 'session-1',
              'status': 'CLOSED',
              'openedByName': 'John Smith',
              'openedAt': '2026-03-10T01:00:00.000Z',
              'closedAt': '2026-03-10T09:00:00.000Z',
            },
          ],
        },
      ),
    );

    final api = CashSessionApi(dio);
    final sessions = await api.listSessions(
      from: DateTime.utc(2026, 3, 10, 0),
      to: DateTime.utc(2026, 3, 10, 23, 59, 59),
      limit: 50,
      offset: 0,
    );

    expect(sessions, hasLength(1));
    expect(sessions.first.id, 'session-1');
    expect(sessions.first.status, 'CLOSED');
    verify(
      () => dio.get<Map<String, dynamic>>(
        '/v0/cash/sessions',
        queryParameters: {
          'status': 'all',
          'from': '2026-03-10T00:00:00.000Z',
          'to': '2026-03-10T23:59:59.000Z',
          'limit': 50,
          'offset': 0,
        },
      ),
    ).called(1);
  });

  test('listSessions omits date filters when no filter is applied', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/cash/sessions'),
        data: {
          'success': true,
          'data': const [],
        },
      ),
    );

    final api = CashSessionApi(dio);
    await api.listSessions(limit: 20, offset: 0);

    verify(
      () => dio.get<Map<String, dynamic>>(
        '/v0/cash/sessions',
        queryParameters: {
          'status': 'all',
          'limit': 20,
          'offset': 0,
        },
      ),
    ).called(1);
  });

  test('listSales uses the session sales read lane and parses items', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(
          path: '/v0/cash/sessions/session-1/sales',
        ),
        data: {
          'success': true,
          'data': {
            'sessionId': 'session-1',
            'items': [
              {
                'saleId': 'sale-1',
                'status': 'FINALIZED',
                'paymentMethod': 'CASH',
                'saleType': 'TAKEAWAY',
                'finalizedAt': '2026-03-09T09:10:00.000Z',
                'totalItems': 3,
                'grandTotalUsd': 7.5,
                'grandTotalKhr': 30750,
                'cashierAccountId': 'cashier-1',
                'cashierName': 'John Smith',
                'voidedAt': null,
              },
            ],
            'limit': 20,
            'offset': 0,
          },
        },
      ),
    );

    final api = CashSessionApi(dio);
    final list = await api.listSales('session-1', limit: 20, offset: 0);

    expect(list, hasLength(1));
    expect(list.first.saleId, 'sale-1');
    expect(list.first.cashierName, 'John Smith');
    verify(
      () => dio.get<Map<String, dynamic>>(
        '/v0/cash/sessions/session-1/sales',
        queryParameters: {'limit': 20, 'offset': 0},
      ),
    ).called(1);
  });
}
