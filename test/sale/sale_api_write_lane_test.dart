import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/sale/data/sale_api.dart';

class _MockDio extends Mock implements Dio {}

class _FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeOptions());
  });

  group('SaleApi write idempotency', () {
    test('uploadManualPaymentProofImage sends area payment-proof', () async {
      final dio = _MockDio();
      when(
        () => dio.post<dynamic>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/v0/media/images/upload'),
          data: {
            'success': true,
            'data': {
              'imageUrl': 'https://cdn.example.com/payment-proof/proof-1.jpg',
            },
          },
        ),
      );

      final api = SaleApi(dio);
      final imageUrl = await api.uploadManualPaymentProofImage(
        imageBytes: const [0xFF, 0xD8, 0xFF, 0x00],
      );

      expect(imageUrl, 'https://cdn.example.com/payment-proof/proof-1.jpg');

      final captured =
          verify(
                () => dio.post<dynamic>(
                  '/v0/media/images/upload',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as FormData;
      expect(
        captured.fields,
        contains(
          isA<MapEntry<String, String>>()
              .having((entry) => entry.key, 'key', 'area')
              .having((entry) => entry.value, 'value', 'payment-proof'),
        ),
      );
      expect(captured.files, hasLength(1));
      expect(captured.files.single.key, 'image');
    });

    test('finalizeCashCheckout includes idempotency metadata', () async {
      final dio = _MockDio();
      final payload = {
        'items': [
          {'menuItemId': 'item-1', 'quantity': 2, 'modifierSelections': []},
        ],
        'saleType': 'TAKEAWAY',
        'tenderCurrency': 'USD',
        'cashReceivedTenderAmount': 10,
      };
      final request = IdempotencyRequest(
        actionKey: 'checkout.cash.finalize',
        intentId: 'sale-finalize-local-cart',
        payload: payload,
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/checkout/cash/finalize'),
          data: {
            'success': true,
            'data': {
              'id': 'sale-1',
              'orderId': 'order-1',
              'status': 'FINALIZED',
              'tenderCurrency': 'USD',
              'paymentMethod': 'CASH',
              'grandTotalUsd': 8,
              'grandTotalKhr': 32800,
              'createdAt': '2026-02-23T18:00:00.000Z',
              'updatedAt': '2026-02-23T18:00:00.000Z',
              'order': {
                'id': 'order-1',
                'status': 'CHECKED_OUT',
                'sourceMode': 'DIRECT_CHECKOUT',
              },
            },
          },
        ),
      );

      final api = SaleApi(dio);
      final result = await api.finalizeCashCheckout(
        payload,
        idempotency: request,
      );
      expect(result.orderId, 'order-1');

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/v0/checkout/cash/finalize',
          data: payload,
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having(
                    (r) => r.actionKey,
                    'actionKey',
                    'checkout.cash.finalize',
                  )
                  .having(
                    (r) => r.intentId,
                    'intentId',
                    'sale-finalize-local-cart',
                  )
                  .having((r) => r.payload, 'payload', payload),
            ),
          ),
        ),
      ).called(1);
    });

    test('initiateKhqrIntent includes idempotency metadata', () async {
      final dio = _MockDio();
      final payload = {
        'items': [
          {'menuItemId': 'item-1', 'quantity': 1, 'modifierSelections': []},
        ],
        'saleType': 'DINE_IN',
        'expiresInSeconds': 180,
      };
      final request = IdempotencyRequest(
        actionKey: 'checkout.khqr.initiate',
        intentId: 'khqr-generate-local-cart-1',
        payload: payload,
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/checkout/khqr/initiate'),
          data: {
            'success': true,
            'data': {
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
              },
              'preview': {
                'itemCount': 1,
                'grandTotalUsd': 3.5,
                'grandTotalKhr': 14350,
              },
            },
          },
        ),
      );

      final api = SaleApi(dio);
      await api.initiateKhqrIntent(payload, idempotency: request);

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/v0/checkout/khqr/initiate',
          data: payload,
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having(
                    (r) => r.actionKey,
                    'actionKey',
                    'checkout.khqr.initiate',
                  )
                  .having(
                    (r) => r.intentId,
                    'intentId',
                    'khqr-generate-local-cart-1',
                  )
                  .having((r) => r.payload, 'payload', payload),
            ),
          ),
        ),
      ).called(1);
    });

    test('finalizeSaleContract includes idempotency metadata', () async {
      final dio = _MockDio();
      final payload = {'paidAmount': 8, 'khqrMd5': 'khqr-md5'};
      final request = IdempotencyRequest(
        actionKey: 'sale.finalize',
        intentId: 'sale-finalize-sale-1',
        payload: {'saleId': 'sale-1', ...payload},
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/sales/sale-1/finalize'),
          data: {
            'success': true,
            'data': {
              'id': 'sale-1',
              'status': 'FINALIZED',
              'grandTotalUsd': 8,
              'grandTotalKhr': 32800,
              'createdAt': '2026-02-22T10:05:00.000Z',
              'updatedAt': '2026-02-22T10:10:01.000Z',
            },
          },
        ),
      );

      final api = SaleApi(dio);
      await api.finalizeSaleContract('sale-1', payload, idempotency: request);

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/v0/sales/sale-1/finalize',
          data: payload,
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having((r) => r.actionKey, 'actionKey', 'sale.finalize')
                  .having((r) => r.intentId, 'intentId', 'sale-finalize-sale-1')
                  .having((r) => r.payload, 'payload', {
                    'saleId': 'sale-1',
                    ...payload,
                  }),
            ),
          ),
        ),
      ).called(1);
    });

    test('checkoutOrder includes idempotency metadata', () async {
      final dio = _MockDio();
      final payload = {
        'paymentMethod': 'CASH',
        'tenderCurrency': 'USD',
        'tenderAmount': 8,
        'subtotalUsd': 8,
        'discountUsd': 0,
        'vatUsd': 0,
        'grandTotalUsd': 8,
        'saleFxRateKhrPerUsd': 4100,
        'cashReceivedTenderAmount': 10,
      };
      final request = IdempotencyRequest(
        actionKey: 'order.checkout',
        intentId: 'order-checkout-1',
        payload: {'orderId': 'order-1', ...payload},
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/orders/order-1/checkout'),
          data: {
            'success': true,
            'data': {
              'id': 'sale-1',
              'orderId': 'order-1',
              'status': 'FINALIZED',
              'saleType': 'DINE_IN',
              'tenderCurrency': 'USD',
              'paymentMethod': 'CASH',
              'grandTotalUsd': 8,
              'grandTotalKhr': 32800,
              'createdAt': '2026-03-19T10:00:00.000Z',
              'updatedAt': '2026-03-19T10:00:00.000Z',
              'order': {
                'id': 'order-1',
                'status': 'CHECKED_OUT',
                'sourceMode': 'STANDARD',
              },
              'lines': [],
            },
          },
        ),
      );

      final api = SaleApi(dio);
      final result = await api.checkoutOrder(
        'order-1',
        payload,
        idempotency: request,
      );
      expect(result.orderId, 'order-1');

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/v0/orders/order-1/checkout',
          data: payload,
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having((r) => r.actionKey, 'actionKey', 'order.checkout')
                  .having((r) => r.intentId, 'intentId', 'order-checkout-1')
                  .having((r) => r.payload, 'payload', {
                    'orderId': 'order-1',
                    ...payload,
                  }),
            ),
          ),
        ),
      ).called(1);
    });
  });
}
