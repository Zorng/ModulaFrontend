import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
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
