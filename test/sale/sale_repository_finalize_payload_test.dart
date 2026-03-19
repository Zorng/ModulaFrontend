import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/dto/sale_dto.dart';
import 'package:modular_pos/features/sale/data/sale_api.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';

class _MockSaleApi extends Mock implements SaleApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(const IdempotencyRequest(actionKey: 'test'));
  });

  test(
    'finalizeSale normalizes multi-group modifier selections before cash checkout',
    () async {
      final api = _MockSaleApi();
      final repository = SaleRepository(api);

      when(
        () => api.finalizeCashCheckout(
          any(),
          idempotency: any(named: 'idempotency'),
        ),
      ).thenAnswer((_) async => _cashCheckoutResponse());

      final result = await repository.finalizeSale(
        const SaleFinalizeSaleCommand(
          saleId: 'sale-1',
          paymentMethod: 'cash',
          tenderCurrency: 'USD',
          clientOpId: 'client-op-1',
          saleType: 'take_away',
          cashReceived: SaleCashReceivedInputDto(usd: 10),
          cartLines: [
            SaleCartLineInputDto(
              menuItemId: 'item-1',
              quantity: 2,
              modifiers: [
                SaleCartModifierInputDto(
                  groupId: 'group-2',
                  optionIds: ['opt-3', 'opt-3', ''],
                ),
                SaleCartModifierInputDto(groupId: 'group-1', optionIds: []),
                SaleCartModifierInputDto(
                  groupId: 'group-1',
                  optionIds: [' opt-2 ', 'opt-1'],
                ),
                SaleCartModifierInputDto(
                  groupId: '   ',
                  optionIds: ['opt-ignore'],
                ),
                SaleCartModifierInputDto(
                  groupId: 'group-1',
                  optionIds: ['opt-2'],
                ),
              ],
            ),
          ],
        ),
      );

      expect(result.orderId, 'order-1');

      final payload =
          verify(
                () => api.finalizeCashCheckout(
                  captureAny(),
                  idempotency: any(named: 'idempotency'),
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(payload, {
        'items': [
          {
            'menuItemId': 'item-1',
            'quantity': 2,
            'modifiers': [
              {
                'groupId': 'group-1',
                'optionIds': ['opt-1', 'opt-2'],
              },
              {
                'groupId': 'group-2',
                'optionIds': ['opt-3'],
              },
            ],
          },
        ],
        'saleType': 'TAKEAWAY',
        'tenderCurrency': 'USD',
        'cashReceivedTenderAmount': 10,
      });
    },
  );

  test(
    'placeOrder uses the standard open-order lane without sourceMode',
    () async {
      final api = _MockSaleApi();
      final repository = SaleRepository(
        api,
        policyStateReader: () => const PolicyState(
          branchPolicy: BranchPolicy(
            branchId: 'branch-1',
            tenantId: 'tenant-1',
            saleAllowPayLater: true,
          ),
        ),
      );

      when(
        () => api.placeOrder(any(), idempotency: any(named: 'idempotency')),
      ).thenAnswer(
        (_) async => const SaleOrderPlacementResponseDto(
          orderId: 'order-1',
          saleId: 'sale-1',
          status: 'UNPAID',
          batchId: 'batch-1',
        ),
      );

      await repository.placeOrder(
        const SalePlaceOrderCommand(
          saleId: 'sale-1',
          branchId: 'branch-1',
          saleType: 'take_away',
          clientOpId: 'place-order-1',
          cartLines: [
            SaleCartLineInputDto(
              menuItemId: 'item-1',
              quantity: 2,
              modifiers: [],
            ),
          ],
        ),
      );

      final payload =
          verify(
                () => api.placeOrder(
                  captureAny(),
                  idempotency: any(named: 'idempotency'),
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(payload, {
        'items': [
          {'menuItemId': 'item-1', 'quantity': 2},
        ],
        'saleType': 'TAKEAWAY',
      });
    },
  );

  test(
    'finalizeSale rehydrates a finalized KHQR checkout from intent status',
    () async {
      final api = _MockSaleApi();
      final repository = SaleRepository(api);

      when(() => api.getKhqrIntentStatus('intent-1')).thenAnswer(
        (_) async => const SaleKhqrIntentStateDto(
          paymentIntentId: 'intent-1',
          status: 'PAID_CONFIRMED',
          saleId: 'sale-1',
        ),
      );
      when(() => api.getSaleDetail('sale-1')).thenAnswer(
        (_) async => SaleDto.fromJson({
          'id': 'sale-1',
          'orderId': 'order-1',
          'clientUuid': 'client-1',
          'tenantId': 'tenant-1',
          'branchId': 'branch-1',
          'employeeId': 'employee-1',
          'saleType': 'TAKEAWAY',
          'state': 'FINALIZED',
          'fxRateUsed': 4100,
          'tenderCurrency': 'USD',
          'paymentMethod': 'KHQR',
          'fulfillmentStatus': 'PREPARING',
          'subtotalUsdExact': 8,
          'subtotalKhrExact': 32800,
          'totalUsdExact': 8,
          'totalKhrExact': 32800,
          'createdAt': '2026-03-10T10:00:00.000Z',
          'updatedAt': '2026-03-10T10:00:00.000Z',
          'items': [],
        }),
      );
      when(() => api.getReceiptBySaleId('sale-1')).thenAnswer(
        (_) async => SaleReceiptReadDto.fromJson({
          'receiptId': 'receipt-1',
          'saleId': 'sale-1',
          'receiptNumber': 'R-1',
          'statusDisplay': 'NORMAL',
          'issuedAt': '2026-03-10T10:00:00.000Z',
          'saleSnapshot': {
            'paymentMethod': 'KHQR',
            'tenderCurrency': 'USD',
            'subtotalUsd': 8,
            'vatUsd': 0,
            'grandTotalUsd': 8,
            'grandTotalKhr': 32800,
          },
          'lines': [],
        }),
      );

      final result = await repository.finalizeSale(
        const SaleFinalizeSaleCommand(
          saleId: '',
          paymentMethod: 'khqr',
          tenderCurrency: 'USD',
          clientOpId: 'client-op-khqr-1',
          khqrIntentId: 'intent-1',
          khqrMd5: 'khqr-md5',
        ),
      );

      expect(result.saleId, 'sale-1');
      expect(result.orderId, 'order-1');
      expect(result.receiptId, 'receipt-1');
      verify(() => api.getKhqrIntentStatus('intent-1')).called(1);
      verify(() => api.getSaleDetail('sale-1')).called(1);
      verify(() => api.getReceiptBySaleId('sale-1')).called(1);
      verifyNever(
        () => api.confirmKhqrPayment(
          any(),
          idempotency: any(named: 'idempotency'),
        ),
      );
    },
  );

  test(
    'checkoutOpenTicket derives order totals from order detail before checkout',
    () async {
      final api = _MockSaleApi();
      final repository = SaleRepository(
        api,
        policyStateReader: () => const PolicyState(
          branchPolicy: BranchPolicy(
            branchId: 'branch-1',
            tenantId: 'tenant-1',
            saleFxRateKhrPerUsd: 4100,
            saleKhrRoundingEnabled: true,
          ),
        ),
      );

      when(() => api.getOrderDetail('order-1')).thenAnswer(
        (_) async => SaleOrderDetailResponseDto.fromJson({
          'id': 'order-1',
          'tenantId': 'tenant-1',
          'branchId': 'branch-1',
          'openedByAccountId': 'account-1',
          'status': 'OPEN',
          'sourceMode': 'STANDARD',
          'createdAt': '2026-03-19T10:00:00.000Z',
          'updatedAt': '2026-03-19T10:00:00.000Z',
          'lines': [
            {
              'id': 'line-1',
              'orderId': 'order-1',
              'menuItemId': 'item-1',
              'menuItemNameSnapshot': 'Iced Latte',
              'unitPrice': 5,
              'quantity': 1,
              'lineSubtotal': 5,
            },
            {
              'id': 'line-2',
              'orderId': 'order-1',
              'menuItemId': 'item-2',
              'menuItemNameSnapshot': 'Mocha',
              'unitPrice': 3,
              'quantity': 1,
              'lineSubtotal': 3,
            },
          ],
          'fulfillmentBatches': [],
          'manualPaymentClaims': [],
        }),
      );
      when(
        () => api.checkoutOrder(
          any(),
          any(),
          idempotency: any(named: 'idempotency'),
        ),
      ).thenAnswer((_) async => _cashCheckoutResponse());

      final result = await repository.checkoutOpenTicket(
        const SaleCheckoutOpenTicketCommand(
          openTicketId: 'order-1',
          paymentMethod: 'cash',
          tenderCurrency: 'USD',
          clientOpId: 'order-checkout-1',
          cashReceived: SaleCashReceivedInputDto(usd: 10),
        ),
      );

      expect(result.saleId, 'sale-1');
      expect(result.status, 'PAID');

      final captured = verify(
        () => api.checkoutOrder(
          captureAny(),
          captureAny(),
          idempotency: any(named: 'idempotency'),
        ),
      ).captured;
      expect(captured[0], 'order-1');
      expect(captured[1], {
        'paymentMethod': 'CASH',
        'tenderCurrency': 'USD',
        'tenderAmount': 8.0,
        'subtotalUsd': 8.0,
        'discountUsd': 0,
        'vatUsd': 0,
        'grandTotalUsd': 8.0,
        'saleFxRateKhrPerUsd': 4100.0,
        'cashReceivedTenderAmount': 10,
      });
    },
  );

  test('updateFulfillmentStatus includes idempotency metadata', () async {
    final api = _MockSaleApi();
    final repository = SaleRepository(api);

    when(
      () => api.updateOrderFulfillmentStatus(
        any(),
        status: any(named: 'status'),
        note: any(named: 'note'),
        idempotency: any(named: 'idempotency'),
      ),
    ).thenAnswer(
      (_) async => SaleOrderFulfillmentUpdateResponseDto(
        id: 'batch-1',
        orderId: 'order-1',
        status: 'READY',
        createdByAccountId: 'user-1',
        createdAt: DateTime.utc(2026, 3, 19, 10),
        updatedAt: DateTime.utc(2026, 3, 19, 10),
      ),
    );

    await repository.updateFulfillmentStatus(
      orderId: 'order-1',
      status: 'ready',
      note: 'Packed and ready',
    );

    verify(
      () => api.updateOrderFulfillmentStatus(
        'order-1',
        status: 'READY',
        note: 'Packed and ready',
        idempotency: any(
          named: 'idempotency',
          that: isA<IdempotencyRequest>()
              .having(
                (r) => r.actionKey,
                'actionKey',
                'order.fulfillment.update',
              )
              .having((r) => r.payload, 'payload', {
                'orderId': 'order-1',
                'status': 'READY',
                'note': 'Packed and ready',
              }),
        ),
      ),
    ).called(1);
  });
}

SaleCashCheckoutResponseDto _cashCheckoutResponse() {
  return SaleCashCheckoutResponseDto.fromJson({
    'id': 'sale-1',
    'orderId': 'order-1',
    'clientUuid': 'client-1',
    'tenantId': 'tenant-1',
    'branchId': 'branch-1',
    'employeeId': 'employee-1',
    'saleType': 'TAKEAWAY',
    'state': 'FINALIZED',
    'fxRateUsed': 4100,
    'tenderCurrency': 'USD',
    'paymentMethod': 'CASH',
    'fulfillmentStatus': 'COMPLETED',
    'subtotalUsdExact': 8,
    'subtotalKhrExact': 32800,
    'totalUsdExact': 8,
    'totalKhrExact': 32800,
    'cashReceivedUsd': 10,
    'changeGivenUsd': 2,
    'changeGivenKhr': 0,
    'createdAt': '2026-03-10T10:00:00.000Z',
    'updatedAt': '2026-03-10T10:00:00.000Z',
    'items': [],
    'order': {
      'id': 'order-1',
      'status': 'CHECKED_OUT',
      'sourceMode': 'DIRECT_CHECKOUT',
    },
  });
}
