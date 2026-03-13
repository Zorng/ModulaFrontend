import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
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

      await repository.finalizeSale(
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
}

SaleCashCheckoutResponseDto _cashCheckoutResponse() {
  return SaleCashCheckoutResponseDto.fromJson({
    'sale': {
      'id': 'sale-1',
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
    },
  });
}
