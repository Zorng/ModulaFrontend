import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_error_codes.dart';

String mapCashSessionErrorMessage({
  String? context,
  String? errorCode,
  Object? error,
}) {
  switch (CashSessionErrorCodes.normalize(errorCode)) {
    case CashSessionErrorCodes.cashSessionAlreadyOpen:
      return 'A branch cash session is already open. Refresh and review the active session.';
    case CashSessionErrorCodes.cashSessionNotFound:
      return 'This cash session could not be found. Refresh and try again.';
    case CashSessionErrorCodes.cashSessionNotOpen:
      return 'This branch cash session is no longer open.';
    case CashSessionErrorCodes.cashSessionAlreadyClosed:
      return 'This cash session was already closed. Refresh to see the latest status.';
    case CashSessionErrorCodes.cashSessionUnpaidTicketsExist:
      return 'This branch session cannot be closed while unpaid tickets are still open.';
    case CashSessionErrorCodes.cashSessionForbiddenSelfScope:
      return 'You do not have permission to manage this branch cash session.';
    case CashSessionErrorCodes.idempotencyKeyRequired:
      return 'This cash-session request could not be completed safely. Try again.';
    case CashSessionErrorCodes.idempotencyConflict:
      return 'This cash-session action conflicts with another request. Wait a moment and try again.';
    case CashSessionErrorCodes.idempotencyInProgress:
      return 'This cash-session action is already in progress. Wait a moment and refresh.';
    case CashSessionErrorCodes.offlineUnreachable:
      return 'Cash-session actions are unavailable while offline. Reconnect and try again.';
    default:
      return UserErrorMessage.build(context: context, error: error);
  }
}
