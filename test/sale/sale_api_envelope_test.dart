import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/sale/data/dto/sale_api_envelope.dart';
import 'package:modular_pos/features/sale/data/dto/sale_dto.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';

void main() {
  test('unwraps sale success envelope', () {
    final data = SaleApiEnvelope.unwrapDataMap({
      'success': true,
      'data': {'id': 'sale-1'},
    }, fallbackMessage: 'fallback');

    expect(data['id'], 'sale-1');
  });

  test('normalizes failure code to cash session required', () {
    expect(
      () => SaleApiEnvelope.unwrapDataMap({
        'success': false,
        'error': 'Cash session required.',
        'code': 'SALE_FINALIZE_REQUIRES_OPEN_CASH_SESSION',
      }, fallbackMessage: 'fallback'),
      throwsA(
        isA<ApiClientException>()
            .having(
              (error) => error.code,
              'code',
              SaleCheckoutReasonCodes.cashSessionRequired,
            )
            .having(
              (error) => error.message,
              'message',
              'Cash session required.',
            ),
      ),
    );
  });

  test('normalizes khqr failure code', () {
    expect(
      SaleCheckoutReasonCodes.normalize(
        'SALE_FINALIZE_KHQR_CONFIRMATION_REQUIRED',
      ),
      SaleCheckoutReasonCodes.khqrNotConfirmed,
    );
  });

  test('normalizes contract reason-code variants', () {
    expect(
      SaleCheckoutReasonCodes.normalize('branch context required'),
      SaleCheckoutReasonCodes.branchRequired,
    );
    expect(
      SaleCheckoutReasonCodes.normalize('payment-intent-not-found'),
      SaleCheckoutReasonCodes.khqrNotConfirmed,
    );
    expect(
      SaleCheckoutReasonCodes.normalize('idempotency in progress'),
      SaleCheckoutReasonCodes.idempotencyConflict,
    );
  });

  test('normalizes khqr reason code from successful payloads', () {
    final dto = SaleKhqrIntentStateDto.fromJson({
      'paymentIntentId': 'intent-1',
      'status': 'WAITING_FOR_PAYMENT',
      'reasonCode': 'payment already confirmed',
    });

    expect(dto.reasonCode, SaleCheckoutReasonCodes.khqrNotConfirmed);
  });
}
