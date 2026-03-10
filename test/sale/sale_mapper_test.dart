import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/sale/data/dto/sale_dto.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_mappers.dart';

void main() {
  test('maps SaleDto to checkout summary with default tender currency', () {
    final dto = SaleDto.fromJson({
      'id': 'sale-1',
      'clientUuid': 'client-1',
      'tenantId': 'tenant-1',
      'branchId': 'branch-1',
      'employeeId': 'user-1',
      'saleType': 'take_away',
      'state': 'FINALIZED',
      'fxRateUsed': 4100,
      'tenderCurrency': '',
      'paymentMethod': 'cash',
      'fulfillmentStatus': 'in_prep',
      'subtotalUsdExact': 5,
      'subtotalKhrExact': 20500,
      'totalUsdExact': 5,
      'totalKhrExact': 20500,
      'createdAt': '2026-03-07T10:00:00.000Z',
      'updatedAt': '2026-03-07T10:05:00.000Z',
      'items': const [],
    });

    final summary = SaleMappers.toCheckoutSummary(dto);

    expect(summary.saleId, 'sale-1');
    expect(summary.tenderCurrency, 'usd');
    expect(summary.totalUsdExact, 5);
    expect(summary.cashReceivedUsd, 0);
    expect(summary.paymentMethod, 'cash');
  });

  test('maps KHQR initiate response into checkout attempt dto', () {
    final attempt = SaleMappers.toKhqrAttempt(
      command: const SaleGenerateKhqrAttemptCommand(
        saleId: 'sale-1',
        tenderCurrency: 'KHR',
        clientOpId: 'op-1',
      ),
      response: SaleKhqrInitiateResponseDto.fromJson({
        'id': 'intent-root-1',
        'intent': {
          'paymentIntentId': '',
          'status': 'WAITING_FOR_PAYMENT',
          'reasonCode': 'payment intent not found',
        },
        'attempt': {
          'attemptId': 'attempt-1',
          'paymentIntentId': 'intent-1',
          'md5': 'md5-1',
          'status': 'WAITING_FOR_PAYMENT',
        },
        'paymentRequest': {
          'md5': 'md5-1',
          'payload': 'KHQR:payload',
          'payloadType': 'RAW',
          'deepLinkUrl': 'khqr://launch',
          'amount': 18.45,
          'currency': 'KHR',
          'toAccountId': 'bakong-001',
          'expiresAt': '2026-03-07T10:03:00.000Z',
        },
        'preview': {
          'itemCount': 1,
          'grandTotalUsd': 4.5,
          'grandTotalKhr': 18450,
        },
      }),
      expiresAt: DateTime.utc(2026, 3, 7, 10, 3),
    );

    expect(attempt.attemptId, 'intent-root-1');
    expect(attempt.amount, 18.45);
    expect(attempt.currency, 'KHR');
    expect(attempt.status, 'WAITING_FOR_PAYMENT');
    expect(attempt.qrPayload, 'KHQR:payload');
    expect(attempt.payloadType, 'RAW');
    expect(attempt.deepLinkUrl, 'khqr://launch');
    expect(attempt.toAccountId, 'bakong-001');
    expect(attempt.expiresAt, DateTime.parse('2026-03-07T10:03:00.000Z'));
    expect(attempt.reasonCode, SaleCheckoutReasonCodes.khqrNotConfirmed);
  });

  test('maps KHQR status with sale materialization to paid confirmed', () {
    final status = SaleMappers.toKhqrStatus(
      command: const SaleCheckKhqrStatusCommand(
        saleId: 'local-sale-1',
        md5: 'md5-1',
        intentId: 'intent-1',
      ),
      state: SaleKhqrIntentStateDto.fromJson({
        'paymentIntentId': 'intent-1',
        'status': 'paid-confirmed',
        'saleId': 'sale-1',
        'reasonCode': 'payment already confirmed',
      }),
    );

    expect(status.saleId, 'sale-1');
    expect(status.status, 'PAID_CONFIRMED');
    expect(status.reasonCode, SaleCheckoutReasonCodes.khqrNotConfirmed);
    expect(status.reasonMessage, isNull);
  });

  test('maps cash checkout response to finalize result', () {
    final result = SaleMappers.toFinalizeResultFromCashCheckout(
      SaleCashCheckoutResponseDto.fromJson({
        'sale': {
          'id': 'sale-1',
          'clientUuid': 'client-1',
          'tenantId': 'tenant-1',
          'branchId': 'branch-1',
          'employeeId': 'user-1',
          'saleType': 'take_away',
          'state': 'FINALIZED',
          'fxRateUsed': 4100,
          'tenderCurrency': 'USD',
          'paymentMethod': 'cash',
          'fulfillmentStatus': 'in_prep',
          'subtotalUsdExact': 5,
          'subtotalKhrExact': 20500,
          'totalUsdExact': 5,
          'totalKhrExact': 20500,
          'cashReceivedTenderAmount': 10,
          'cashChangeTenderAmount': 5,
          'createdAt': '2026-03-07T10:00:00.000Z',
          'updatedAt': '2026-03-07T10:05:00.000Z',
          'items': const [],
        },
        'receipt': {
          'receiptId': 'receipt-1',
          'saleId': 'sale-1',
          'statusDisplay': 'Paid',
          'issuedAt': '2026-03-07T10:05:00.000Z',
        },
      }),
    );

    expect(result.saleId, 'sale-1');
    expect(result.status, 'FINALIZED');
    expect(result.receiptId, 'receipt-1');
    expect(result.cashReceivedUsd, 10);
    expect(result.changeGivenUsd, 5);
    expect(result.idempotentReplay, isFalse);
  });

  test(
    'maps cash checkout response sale id from receipt when sale.id is blank',
    () {
      final result = SaleMappers.toFinalizeResultFromCashCheckout(
        SaleCashCheckoutResponseDto.fromJson({
          'sale': {
            'id': '',
            'clientUuid': 'client-1',
            'tenantId': 'tenant-1',
            'branchId': 'branch-1',
            'employeeId': 'user-1',
            'saleType': 'take_away',
            'state': 'FINALIZED',
            'fxRateUsed': 4100,
            'tenderCurrency': 'USD',
            'paymentMethod': 'cash',
            'fulfillmentStatus': 'in_prep',
            'subtotalUsdExact': 5,
            'subtotalKhrExact': 20500,
            'totalUsdExact': 5,
            'totalKhrExact': 20500,
            'cashReceivedTenderAmount': 10,
            'cashChangeTenderAmount': 5,
            'createdAt': '2026-03-07T10:00:00.000Z',
            'updatedAt': '2026-03-07T10:05:00.000Z',
            'items': const [],
          },
          'receipt': {
            'receiptId': 'sale-2',
            'saleId': 'sale-2',
            'statusDisplay': 'Paid',
            'issuedAt': '2026-03-07T10:05:00.000Z',
          },
        }),
      );

      expect(result.saleId, 'sale-2');
      expect(result.receiptId, 'sale-2');
    },
  );

  test('normalizes live and legacy sale lifecycle enums', () {
    expect(SaleMappers.normalizeSaleState('FINALIZED'), 'FINALIZED');
    expect(SaleMappers.normalizeSaleState('void_pending'), 'VOID_PENDING');
    expect(SaleMappers.normalizeSaleState('draft'), 'PENDING');
    expect(SaleMappers.normalizeSaleState('reopened'), 'PENDING');
    expect(SaleMappers.normalizeSaleState(''), 'PENDING');
    expect(SaleMappers.normalizePaymentMethod('cash'), 'CASH');
    expect(SaleMappers.normalizePaymentMethod('qr'), 'KHQR');
    expect(SaleMappers.normalizeTenderCurrency('khr'), 'KHR');
    expect(SaleMappers.toUiPaymentMethod('KHQR'), 'qr');
  });
}
