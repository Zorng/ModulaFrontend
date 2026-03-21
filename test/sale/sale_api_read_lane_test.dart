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

  group('SaleApi read lane', () {
    test('listOrders reads canonical order envelope items payload', () async {
      final dio = _MockDio();
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/orders'),
          data: {
            'success': true,
            'data': {
              'items': [
                {
                  'id': 'order-1',
                  'status': 'OPEN',
                  'sourceMode': 'STANDARD',
                  'fulfillmentStatus': 'PREPARING',
                  'totalUsdExact': 5,
                  'linesPreview': [
                    {
                      'menuItemNameSnapshot': 'Iced Latte',
                      'quantity': 2,
                      'modifierLabels': ['Less ice'],
                    },
                  ],
                  'checkedOutAt': null,
                  'paymentMethod': null,
                  'manualPaymentClaimId': null,
                  'manualPaymentClaimStatus': null,
                  'createdAt': '2026-03-10T08:30:00.000Z',
                  'updatedAt': '2026-03-10T08:31:00.000Z',
                },
              ],
              'limit': 20,
              'offset': 0,
              'total': 1,
              'hasMore': false,
            },
          },
        ),
      );

      final api = SaleApi(dio);
      final page = await api.listOrders(limit: 20, offset: 0, status: 'OPEN');

      expect(page.items, hasLength(1));
      expect(page.items.single.orderId, 'order-1');
      expect(page.items.single.status, 'OPEN');
      expect(page.items.single.sourceMode, 'STANDARD');
      expect(page.items.single.fulfillmentStatus, 'PREPARING');
      expect(page.items.single.totalUsdExact, 5);
      expect(
        page.items.single.linesPreview.single.menuItemNameSnapshot,
        'Iced Latte',
      );
      expect(page.total, 1);
      verify(
        () => dio.get<Map<String, dynamic>>(
          '/v0/orders',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });

    test('listSales reads canonical envelope items payload', () async {
      final dio = _MockDio();
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/sales'),
          data: {
            'success': true,
            'data': {
              'items': [
                {
                  'id': 'sale-1',
                  'status': 'FINALIZED',
                  'paymentMethod': 'CASH',
                  'tenderCurrency': 'USD',
                  'grandTotalUsd': 4.5,
                  'grandTotalKhr': 18000,
                  'createdAt': '2026-03-10T08:30:00.000Z',
                  'updatedAt': '2026-03-10T08:30:00.000Z',
                },
              ],
            },
          },
        ),
      );

      final api = SaleApi(dio);
      final sales = await api.listSales();

      expect(sales, hasLength(1));
      expect(sales.single.id, 'sale-1');
      expect(sales.single.state, 'FINALIZED');
      verify(
        () => dio.get<Map<String, dynamic>>(
          '/v0/sales',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });

    test('getReceiptBySaleId reads the canonical receipt endpoint', () async {
      final dio = _MockDio();
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/receipts/sales/sale-1'),
          data: {
            'success': true,
            'data': {
              'receiptId': 'RCP-1001',
              'saleId': 'sale-1',
              'receiptNumber': 'RCP-20260310-0001',
              'statusDisplay': 'NORMAL',
              'issuedAt': '2026-03-10T08:30:00.000Z',
              'saleSnapshot': {
                'paymentMethod': 'CASH',
                'grandTotalUsd': 4.5,
                'grandTotalKhr': 18000,
              },
              'lines': [
                {
                  'menuItemNameSnapshot': 'Iced Latte',
                  'quantity': 2,
                  'unitPrice': 2.25,
                  'lineTotalAmount': 4.5,
                },
              ],
            },
          },
        ),
      );

      final api = SaleApi(dio);
      final receipt = await api.getReceiptBySaleId('sale-1');

      expect(receipt.saleId, 'sale-1');
      expect(receipt.receiptId, 'RCP-1001');
      expect(receipt.receiptNumber, 'RCP-20260310-0001');
      expect(receipt.saleSnapshot.paymentMethod, 'CASH');
      expect(receipt.lines, hasLength(1));
      expect(receipt.lines.single.name, 'Iced Latte');
      verify(
        () => dio.get<Map<String, dynamic>>('/v0/receipts/sales/sale-1'),
      ).called(1);
    });

    test('getOrderDetail reads the canonical order detail endpoint', () async {
      final dio = _MockDio();
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/orders/order-1'),
          data: {
            'success': true,
            'data': {
              'id': 'order-1',
              'tenantId': 'tenant-1',
              'branchId': 'branch-1',
              'openedByAccountId': 'user-1',
              'status': 'OPEN',
              'sourceMode': 'STANDARD',
              'createdAt': '2026-03-10T08:30:00.000Z',
              'updatedAt': '2026-03-10T08:31:00.000Z',
              'lines': [
                {
                  'id': 'line-1',
                  'orderId': 'order-1',
                  'menuItemId': 'item-1',
                  'menuItemNameSnapshot': 'Iced Latte',
                  'unitPrice': 3.5,
                  'quantity': 1,
                  'lineSubtotal': 3.5,
                  'note': 'Less ice',
                },
              ],
              'fulfillmentBatches': [],
              'manualPaymentClaims': [],
            },
          },
        ),
      );

      final api = SaleApi(dio);
      final detail = await api.getOrderDetail('order-1');

      expect(detail.orderId, 'order-1');
      expect(detail.status, 'OPEN');
      expect(detail.lines.single.menuItemNameSnapshot, 'Iced Latte');
      verify(
        () => dio.get<Map<String, dynamic>>('/v0/orders/order-1'),
      ).called(1);
    });

    test(
      'updateOrderFulfillmentStatus uses the canonical order endpoint',
      () async {
        final dio = _MockDio();
        when(
          () => dio.patch<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(
              path: '/v0/orders/order-1/fulfillment',
            ),
            data: {
              'success': true,
              'data': {
                'id': 'batch-1',
                'orderId': 'order-1',
                'status': 'PREPARING',
                'note': 'Started by kitchen',
                'createdByAccountId': 'user-1',
                'completedAt': null,
                'createdAt': '2026-03-10T08:32:00.000Z',
                'updatedAt': '2026-03-10T08:32:00.000Z',
              },
            },
          ),
        );

        final api = SaleApi(dio);
        final updated = await api.updateOrderFulfillmentStatus(
          'order-1',
          status: 'PREPARING',
          note: 'Started by kitchen',
          idempotency: const IdempotencyRequest(
            actionKey: 'order.fulfillment.update',
            intentId: 'order-fulfillment-order-1-preparing',
            payload: {
              'orderId': 'order-1',
              'status': 'PREPARING',
              'note': 'Started by kitchen',
            },
          ),
        );

        expect(updated.orderId, 'order-1');
        expect(updated.status, 'PREPARING');
        expect(updated.note, 'Started by kitchen');
        verify(
          () => dio.patch<Map<String, dynamic>>(
            '/v0/orders/order-1/fulfillment',
            data: {'status': 'PREPARING', 'note': 'Started by kitchen'},
            options: any(
              named: 'options',
              that: isA<Options>().having(
                (o) => o.extra?[idempotencyRequestExtraKey],
                'idempotencyRequest',
                isA<IdempotencyRequest>()
                    .having(
                      (r) => r.actionKey,
                      'actionKey',
                      'order.fulfillment.update',
                    )
                    .having(
                      (r) => r.intentId,
                      'intentId',
                      'order-fulfillment-order-1-preparing',
                    ),
              ),
            ),
          ),
        ).called(1);
      },
    );
  });
}
