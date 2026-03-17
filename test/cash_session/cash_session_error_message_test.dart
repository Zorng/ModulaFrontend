import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_error_codes.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_error_message.dart';

void main() {
  test('maps unpaid-ticket close denial to deterministic message', () {
    final message = mapCashSessionErrorMessage(
      errorCode: CashSessionErrorCodes.cashSessionUnpaidTicketsExist,
      error: 'raw backend error',
    );

    expect(
      message,
      'This branch session cannot be closed while unpaid tickets are still open.',
    );
  });

  test('maps offline failures to deterministic message', () {
    final message = mapCashSessionErrorMessage(
      errorCode: ' offline_unreachable ',
      error: 'socket exception',
    );

    expect(
      message,
      'Cash-session actions are unavailable while offline. Reconnect and try again.',
    );
  });

  test('maps online-only actions to deterministic message', () {
    final message = mapCashSessionErrorMessage(
      errorCode: CashSessionErrorCodes.onlineOnlyAction,
      error: 'raw backend error',
    );

    expect(
      message,
      'This cash-session action requires connectivity and cannot be queued offline.',
    );
  });

  test('falls back to generic user message for unknown codes', () {
    final message = mapCashSessionErrorMessage(
      context: 'Failed to load cash session',
      errorCode: 'SOMETHING_NEW',
      error: 'unexpected',
    );

    expect(message, startsWith('Failed to load cash session.'));
  });
}
