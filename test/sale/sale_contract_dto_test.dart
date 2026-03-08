import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/sale/data/dto/sale_dto.dart';

void main() {
  test(
    'parses legacy draft sale dto without using live sale lifecycle dto',
    () {
      final dto = SaleDraftDto.fromJson({
        'id': 'draft-1',
        'paymentMethod': 'cash',
        'tenderCurrency': 'USD',
        'grandTotalUsd': 6,
        'grandTotalKhr': 24600,
        'cashReceivedTenderAmount': 10,
        'cashChangeTenderAmount': 4,
        'items': [
          {
            'id': 'draft-line-1',
            'saleId': 'draft-1',
            'menuItemId': 'item-1',
            'menuItemName': 'Americano',
            'quantity': 2,
            'modifiers': [],
          },
        ],
      });

      expect(dto.id, 'draft-1');
      expect(dto.totalUsdExact, 6);
      expect(dto.cashReceivedUsd, 10);
      expect(dto.changeGivenUsd, 4);
      expect(dto.items.single.menuItemName, 'Americano');
    },
  );

  test('parses cash checkout response with nested sale and receipt', () {
    final dto = SaleCashCheckoutResponseDto.fromJson({
      'sale': {
        'id': 'sale-1',
        'status': 'FINALIZED',
        'saleType': 'DINE_IN',
        'paymentMethod': 'CASH',
        'tenderCurrency': 'USD',
        'grandTotalUsd': 8,
        'grandTotalKhr': 32800,
        'cashReceivedTenderAmount': 10,
        'cashChangeTenderAmount': 2,
        'createdAt': '2026-02-23T18:00:00.000Z',
        'updatedAt': '2026-02-23T18:00:00.000Z',
      },
      'receipt': {
        'receiptId': 'receipt-1',
        'saleId': 'sale-1',
        'statusDisplay': 'NORMAL',
        'issuedAt': '2026-02-23T18:00:00.000Z',
      },
    });

    expect(dto.sale.id, 'sale-1');
    expect(dto.sale.state, 'FINALIZED');
    expect(dto.sale.totalUsdExact, 8);
    expect(dto.sale.cashReceivedUsd, 10);
    expect(dto.sale.changeGivenUsd, 2);
    expect(dto.receipt?.receiptId, 'receipt-1');
  });

  test('parses khqr initiate response', () {
    final dto = SaleKhqrInitiateResponseDto.fromJson({
      'id': 'intent-root',
      'intent': {
        'paymentIntentId': 'intent-1',
        'status': 'WAITING_FOR_PAYMENT',
        'saleId': null,
      },
      'attempt': {
        'attemptId': 'attempt-1',
        'paymentIntentId': 'intent-1',
        'saleId': null,
        'md5': 'khqr-md5',
        'status': 'WAITING_FOR_PAYMENT',
      },
      'paymentRequest': {
        'md5': 'khqr-md5',
        'payload': 'payload',
        'payloadType': 'EMV_KHQR_STRING',
        'deepLinkUrl': 'khqr://launch',
        'amount': 3.5,
        'currency': 'USD',
        'toAccountId': 'bakong-001',
        'expiresAt': '2026-02-21T10:30:00.000Z',
      },
      'preview': {'itemCount': 1, 'grandTotalUsd': 3.5, 'grandTotalKhr': 14350},
    });

    expect(dto.id, 'intent-root');
    expect(dto.intent.paymentIntentId, 'intent-1');
    expect(dto.attempt.md5, 'khqr-md5');
    expect(dto.paymentRequest.payloadType, 'EMV_KHQR_STRING');
    expect(dto.paymentRequest.deepLinkUrl, 'khqr://launch');
    expect(dto.paymentRequest.amount, 3.5);
    expect(dto.paymentRequest.currency, 'USD');
    expect(dto.paymentRequest.toAccountId, 'bakong-001');
    expect(dto.preview.grandTotalUsd, 3.5);
  });

  test('parses finalize sale response with embedded receipt', () {
    final dto = SaleFinalizeResponseDto.fromJson({
      'id': 'sale-2',
      'status': 'FINALIZED',
      'saleType': 'TAKE_AWAY',
      'paymentMethod': 'KHQR',
      'tenderCurrency': 'USD',
      'grandTotalUsd': 12,
      'grandTotalKhr': 49200,
      'cashReceivedTenderAmount': 0,
      'cashChangeTenderAmount': 0,
      'createdAt': '2026-02-22T10:05:00.000Z',
      'updatedAt': '2026-02-22T10:10:01.000Z',
      'receipt': {
        'receiptId': 'sale-2',
        'saleId': 'sale-2',
        'statusDisplay': 'NORMAL',
        'issuedAt': '2026-02-22T10:10:01.000Z',
      },
    });

    expect(dto.sale.id, 'sale-2');
    expect(dto.sale.state, 'FINALIZED');
    expect(dto.sale.cashReceivedUsd, 0);
    expect(dto.sale.changeGivenUsd, 0);
    expect(dto.receipt?.saleId, 'sale-2');
  });

  test('parses sale dto from list/detail contract fields', () {
    final dto = SaleDto.fromJson({
      'id': 'sale-3',
      'status': 'VOIDED',
      'paymentMethod': 'CASH',
      'tenderCurrency': 'USD',
      'grandTotalUsd': 5,
      'grandTotalKhr': 20500,
      'cashReceivedTenderAmount': 10,
      'cashChangeTenderAmount': 5,
      'createdAt': '2026-02-22T10:05:00.000Z',
      'updatedAt': '2026-02-22T10:15:00.000Z',
      'lines': [
        {
          'id': 'line-1',
          'saleId': 'sale-3',
          'menuItemId': 'item-1',
          'menuItemNameSnapshot': 'Iced Latte',
          'quantity': 2,
          'modifierSnapshot': [],
        },
      ],
    });

    expect(dto.state, 'VOIDED');
    expect(dto.totalUsdExact, 5);
    expect(dto.cashReceivedUsd, 10);
    expect(dto.changeGivenUsd, 5);
    expect(dto.items.single.menuItemName, 'Iced Latte');
  });
}
