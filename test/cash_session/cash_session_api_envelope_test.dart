import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_api_envelope.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_error_codes.dart';

void main() {
  group('CashSessionErrorCodes', () {
    test('normalize canonicalizes known contract codes', () {
      expect(
        CashSessionErrorCodes.normalize(' cash_session_unpaid_tickets_exist '),
        CashSessionErrorCodes.cashSessionUnpaidTicketsExist,
      );
      expect(
        CashSessionErrorCodes.normalize('idempotency_conflict'),
        CashSessionErrorCodes.idempotencyConflict,
      );
    });

    test('isOffline recognizes normalized offline code', () {
      expect(CashSessionErrorCodes.isOffline(' offline_unreachable '), isTrue);
    });
  });

  test('unwrapRequiredSessionMap reads direct session data envelope', () {
    final map = CashSessionApiEnvelope.unwrapRequiredSessionMap({
      'success': true,
      'data': {'id': 'session-1', 'status': 'OPEN'},
    }, fallbackMessage: 'fallback');

    expect(map['id'], 'session-1');
    expect(map['status'], 'OPEN');
  });

  test(
    'unwrapOptionalSessionMap returns null when active session is absent',
    () {
      final map = CashSessionApiEnvelope.unwrapOptionalSessionMap({
        'success': true,
        'data': {'session': null},
      }, fallbackMessage: 'fallback');

      expect(map, isNull);
    },
  );

  test(
    'unwrapOptionalSessionMap throws ApiClientException on failure envelope',
    () {
      expect(
        () => CashSessionApiEnvelope.unwrapOptionalSessionMap({
          'success': false,
          'error': 'No access to this branch session.',
          'code': ' cash_session_forbidden_self_scope ',
        }, fallbackMessage: 'fallback'),
        throwsA(
          isA<ApiClientException>()
              .having(
                (e) => e.message,
                'message',
                'No access to this branch session.',
              )
              .having(
                (e) => e.code,
                'code',
                CashSessionErrorCodes.cashSessionForbiddenSelfScope,
              ),
        ),
      );
    },
  );

  test(
    'unwrapOptionalSessionMap throws when active-session payload is missing session key',
    () {
      expect(
        () => CashSessionApiEnvelope.unwrapOptionalSessionMap({
          'success': true,
          'data': {'id': 'session-1'},
        }, fallbackMessage: 'Failed to load active cash session.'),
        throwsA(
          isA<ApiClientException>().having(
            (e) => e.message,
            'message',
            'Failed to load active cash session.',
          ),
        ),
      );
    },
  );

  test('unwrapDataList reads movement collection payloads', () {
    final list = CashSessionApiEnvelope.unwrapDataList({
      'success': true,
      'data': {
        'movements': [
          {'id': 'movement-1', 'movementType': 'MANUAL_IN'},
        ],
      },
    }, fallbackMessage: 'fallback');

    expect(list, hasLength(1));
    expect(list.first['id'], 'movement-1');
  });
}
