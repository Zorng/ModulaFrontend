import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';

class SaleCheckoutErrorMessage {
  static String build({String? reasonCode, String? fallback}) {
    switch (SaleCheckoutReasonCodes.normalize(reasonCode)) {
      case SaleCheckoutReasonCodes.unauthorized:
        return 'Your account no longer has access to sell.';
      case SaleCheckoutReasonCodes.branchRequired:
        return 'Select an active branch before continuing.';
      case SaleCheckoutReasonCodes.branchFrozen:
        return 'This branch is frozen. Sale writes are currently blocked.';
      case SaleCheckoutReasonCodes.cashSessionRequired:
        return 'Open a cash session before continuing.';
      case SaleCheckoutReasonCodes.payLaterDisabled:
        return 'Pay-later is currently disabled for this branch.';
      case SaleCheckoutReasonCodes.khqrBranchReceiverNotConfigured:
        return 'Configure a Bakong receiver account for this branch before generating KHQR.';
      case SaleCheckoutReasonCodes.khqrNotConfirmed:
        return 'KHQR payment is not confirmed yet.';
      case SaleCheckoutReasonCodes.idempotencyConflict:
      case SaleCheckoutReasonCodes.duplicateOperation:
        return 'This request is already processing. Please wait before retrying.';
      case SaleCheckoutReasonCodes.offlineUnreachable:
        return 'This action requires online connectivity.';
      case SaleCheckoutReasonCodes.invalidRequest:
        return fallback?.trim().isNotEmpty == true
            ? fallback!.trim()
            : 'Please review the cart details and try again.';
      case SaleCheckoutReasonCodes.unknownError:
      case null:
        return fallback?.trim().isNotEmpty == true ? fallback!.trim() : '';
      default:
        return fallback?.trim().isNotEmpty == true ? fallback!.trim() : '';
    }
  }
}
