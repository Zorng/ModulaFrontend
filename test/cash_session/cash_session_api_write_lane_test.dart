import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_api.dart';

class _MockDio extends Mock implements Dio {}

class _FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeOptions());
  });

  group('CashSessionApi write idempotency', () {
    test('openSession includes idempotency metadata', () async {
      final dio = _MockDio();
      final payload = {
        'openingFloatUsd': 20.0,
        'openingFloatKhr': 50000.0,
        'note': 'Shift start',
      };
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/cash/sessions'),
          data: {
            'success': true,
            'data': {
              'id': 'session-1',
              'status': 'OPEN',
              'openingFloatUsd': 20,
              'openingFloatKhr': 50000,
            },
          },
        ),
      );

      final api = CashSessionApi(dio);
      await api.openSession(payload);

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/v0/cash/sessions',
          data: payload,
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having((r) => r.actionKey, 'actionKey', 'cashSession.open')
                  .having((r) => r.payload, 'payload', payload),
            ),
          ),
        ),
      ).called(1);
    });

    test('closeSession includes idempotency metadata', () async {
      final dio = _MockDio();
      final body = {
        'countedCashUsd': 31.0,
        'countedCashKhr': 74000.0,
        'note': 'End shift',
      };
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(
            path: '/v0/cash/sessions/session-1/close',
          ),
          data: {
            'success': true,
            'data': {
              'id': 'session-1',
              'status': 'CLOSED',
              'openingFloatUsd': 20,
              'openingFloatKhr': 50000,
            },
          },
        ),
      );

      final api = CashSessionApi(dio);
      await api.closeSession('session-1', body);

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/v0/cash/sessions/session-1/close',
          data: body,
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having((r) => r.actionKey, 'actionKey', 'cashSession.close')
                  .having((r) => r.payload, 'payload', {
                    'sessionId': 'session-1',
                    ...body,
                  }),
            ),
          ),
        ),
      ).called(1);
    });

    test('forceCloseSession includes idempotency metadata', () async {
      final dio = _MockDio();
      final body = {
        'countedCashUsd': 31.0,
        'countedCashKhr': 74000.0,
        'reason': 'Cashier left unexpectedly',
        'note': 'Manager override',
      };
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(
            path: '/v0/cash/sessions/session-1/force-close',
          ),
          data: {
            'success': true,
            'data': {
              'id': 'session-1',
              'status': 'FORCE_CLOSED',
              'openingFloatUsd': 20,
              'openingFloatKhr': 50000,
            },
          },
        ),
      );

      final api = CashSessionApi(dio);
      await api.forceCloseSession('session-1', body);

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/v0/cash/sessions/session-1/force-close',
          data: body,
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having(
                    (r) => r.actionKey,
                    'actionKey',
                    'cashSession.forceClose',
                  )
                  .having((r) => r.payload, 'payload', {
                    'sessionId': 'session-1',
                    ...body,
                  }),
            ),
          ),
        ),
      ).called(1);
    });
  });
}
