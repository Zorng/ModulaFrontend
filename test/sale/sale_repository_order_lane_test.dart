import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/dto/sale_dto.dart';
import 'package:modular_pos/features/sale/data/sale_api.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';

class _MockSaleApi extends Mock implements SaleApi {}

void main() {
  test(
    'getOrders maps summaries directly from the expanded order list payload',
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

      when(
        () => api.listOrders(
          status: any(named: 'status'),
          view: any(named: 'view'),
          from: any(named: 'from'),
          to: any(named: 'to'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) async => SaleOrdersListResponseDto(
          items: [
            SaleOrderListItemResponseDto(
              orderId: 'order-open',
              status: 'OPEN',
              sourceMode: 'STANDARD',
              openedByAccountId: 'staff-1',
              openedByDisplayName: 'Staff One',
              fulfillmentStatus: null,
              totalUsdExact: 3.5,
              linesPreview: const [
                SaleOrderListLinePreviewResponseDto(
                  menuItemNameSnapshot: 'Iced Latte',
                  quantity: 1,
                  modifierLabels: ['Less ice'],
                ),
              ],
              checkedOutAt: null,
              paymentMethod: null,
              manualPaymentClaimId: null,
              manualPaymentClaimStatus: null,
              manualPaymentClaimRequestedByAccountId: null,
              manualPaymentClaimRequestedByDisplayName: null,
              manualPaymentClaimRequestedAt: null,
              createdAt: DateTime.utc(2026, 3, 18, 9, 0),
              updatedAt: DateTime.utc(2026, 3, 18, 9, 1),
            ),
            SaleOrderListItemResponseDto(
              orderId: 'order-paid',
              status: 'CHECKED_OUT',
              sourceMode: 'STANDARD',
              openedByAccountId: 'staff-2',
              openedByDisplayName: 'Staff Two',
              fulfillmentStatus: 'PREPARING',
              totalUsdExact: 5,
              linesPreview: const [
                SaleOrderListLinePreviewResponseDto(
                  menuItemNameSnapshot: 'Americano',
                  quantity: 1,
                  modifierLabels: [],
                ),
              ],
              checkedOutAt: DateTime.utc(2026, 3, 18, 9, 7),
              paymentMethod: 'CASH',
              manualPaymentClaimId: 'claim-1',
              manualPaymentClaimStatus: 'PENDING',
              manualPaymentClaimRequestedByAccountId: 'staff-3',
              manualPaymentClaimRequestedByDisplayName: 'Staff Three',
              manualPaymentClaimRequestedAt: DateTime.utc(2026, 3, 18, 9, 8),
              createdAt: DateTime.utc(2026, 3, 18, 9, 5),
              updatedAt: DateTime.utc(2026, 3, 18, 9, 6),
            ),
          ],
          limit: 20,
          offset: 20,
          total: 2,
          hasMore: false,
        ),
      );
      final result = await repository.getOrders(
        SaleOrdersQueryDto(page: 2, limit: 20),
      );

      expect(result.items, hasLength(2));
      expect(result.limit, 20);
      expect(result.total, 2);

      final open = result.items.firstWhere(
        (item) => item.orderId == 'order-open',
      );
      expect(open.saleId, isEmpty);
      expect(open.ticketStatus, 'UNPAID');
      expect(open.fulfillmentStatus, 'pending');
      expect(open.totalUsdExact, 3.5);
      expect(open.totalKhrExact, 14400);
      expect(open.linesPreview.single.name, 'Iced Latte');
      expect(open.openedByDisplayName, 'Staff One');

      final paid = result.items.firstWhere(
        (item) => item.orderId == 'order-paid',
      );
      expect(paid.saleId, isEmpty);
      expect(paid.ticketStatus, 'PAID');
      expect(paid.fulfillmentStatus, 'in_prep');
      expect(paid.totalUsdExact, 5);
      expect(paid.paymentMethod, 'CASH');
      expect(paid.openedByDisplayName, 'Staff Two');
      expect(paid.manualPaymentClaimRequestedByDisplayName, 'Staff Three');
      expect(
        paid.manualPaymentClaimRequestedAt,
        DateTime.utc(2026, 3, 18, 9, 8),
      );

      verify(
        () => api.listOrders(
          status: null,
          view: null,
          from: null,
          to: null,
          limit: 20,
          offset: 20,
        ),
      ).called(1);
      verifyNever(() => api.getOrderDetail(any()));
    },
  );

  test(
    'getOrders maps checked out orders without fulfillment batches to pending',
    () async {
      final api = _MockSaleApi();
      final repository = SaleRepository(api);

      when(
        () => api.listOrders(
          status: any(named: 'status'),
          view: any(named: 'view'),
          from: any(named: 'from'),
          to: any(named: 'to'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) async => SaleOrdersListResponseDto(
          items: [
            SaleOrderListItemResponseDto(
              orderId: 'order-direct-checkout',
              status: 'CHECKED_OUT',
              sourceMode: 'DIRECT_CHECKOUT',
              openedByAccountId: 'staff-1',
              openedByDisplayName: 'Staff One',
              fulfillmentStatus: null,
              totalUsdExact: 5,
              linesPreview: const [
                SaleOrderListLinePreviewResponseDto(
                  menuItemNameSnapshot: 'Americano',
                  quantity: 1,
                  modifierLabels: [],
                ),
              ],
              checkedOutAt: DateTime.utc(2026, 3, 19, 9, 7),
              paymentMethod: 'CASH',
              manualPaymentClaimId: null,
              manualPaymentClaimStatus: null,
              createdAt: DateTime.utc(2026, 3, 19, 9, 5),
              updatedAt: DateTime.utc(2026, 3, 19, 9, 6),
            ),
          ],
          limit: 50,
          offset: 0,
          total: 1,
          hasMore: false,
        ),
      );

      final result = await repository.getOrders(const SaleOrdersQueryDto());

      expect(result.items, hasLength(1));
      expect(result.items.single.ticketStatus, 'PAID');
      expect(result.items.single.fulfillmentStatus, 'pending');
      expect(result.items.single.paymentMethod, 'CASH');
    },
  );

  test(
    'getOrders treats direct checkout order summaries as paid fulfillment even when backend status is OPEN',
    () async {
      final api = _MockSaleApi();
      final repository = SaleRepository(api);

      when(
        () => api.listOrders(
          status: any(named: 'status'),
          view: any(named: 'view'),
          from: any(named: 'from'),
          to: any(named: 'to'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) async => SaleOrdersListResponseDto(
          items: [
            SaleOrderListItemResponseDto(
              orderId: 'order-direct-open',
              status: 'OPEN',
              sourceMode: 'DIRECT_CHECKOUT',
              openedByAccountId: 'staff-2',
              openedByDisplayName: 'Staff Two',
              fulfillmentStatus: 'PENDING',
              totalUsdExact: 5,
              linesPreview: const [
                SaleOrderListLinePreviewResponseDto(
                  menuItemNameSnapshot: 'Flat White',
                  quantity: 1,
                  modifierLabels: [],
                ),
              ],
              checkedOutAt: DateTime.utc(2026, 3, 19, 9, 7),
              paymentMethod: 'CASH',
              manualPaymentClaimId: null,
              manualPaymentClaimStatus: null,
              createdAt: DateTime.utc(2026, 3, 19, 9, 5),
              updatedAt: DateTime.utc(2026, 3, 19, 9, 6),
            ),
          ],
          limit: 50,
          offset: 0,
          total: 1,
          hasMore: false,
        ),
      );

      final result = await repository.getOrders(const SaleOrdersQueryDto());

      expect(result.items, hasLength(1));
      expect(result.items.single.ticketStatus, 'PAID');
      expect(result.items.single.fulfillmentStatus, 'pending');
      expect(result.items.single.paymentMethod, 'CASH');
    },
  );

  test(
    'getOrders maps pay-later queue status to the canonical OPEN filter',
    () async {
      final api = _MockSaleApi();
      final repository = SaleRepository(api);

      when(
        () => api.listOrders(
          status: any(named: 'status'),
          view: any(named: 'view'),
          from: any(named: 'from'),
          to: any(named: 'to'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) async => const SaleOrdersListResponseDto(
          items: [],
          limit: 50,
          offset: 0,
          total: 0,
          hasMore: false,
        ),
      );

      await repository.getOrders(const SaleOrdersQueryDto(status: 'open'));

      verify(
        () => api.listOrders(
          status: 'OPEN',
          view: null,
          from: null,
          to: null,
          limit: 50,
          offset: 0,
        ),
      ).called(1);
    },
  );

  test(
    'getOpenTicketDetail maps order detail to the live order lane',
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
          'updatedAt': '2026-03-19T10:05:00.000Z',
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

      final detail = await repository.getOpenTicketDetail(orderId: 'order-1');

      expect(detail.openTicketId, 'order-1');
      expect(detail.orderId, 'order-1');
      expect(detail.status, 'UNPAID');
      expect(detail.lineCount, 2);
      expect(detail.payableUsdExact, 8);
      expect(detail.payableKhrExact, 32800);
      expect(detail.batches, isEmpty);
      verify(() => api.getOrderDetail('order-1')).called(1);
    },
  );

  test(
    'getOrders maps order list summary without per-row detail enrichment',
    () async {
      final api = _MockSaleApi();
      final repository = SaleRepository(api);

      when(
        () => api.listOrders(
          status: any(named: 'status'),
          view: any(named: 'view'),
          from: any(named: 'from'),
          to: any(named: 'to'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) async => SaleOrdersListResponseDto(
          items: [
            SaleOrderListItemResponseDto(
              orderId: 'order-open',
              status: 'OPEN',
              sourceMode: 'STANDARD',
              openedByAccountId: 'staff-3',
              openedByDisplayName: 'Staff Three',
              fulfillmentStatus: 'PREPARING',
              totalUsdExact: 5,
              linesPreview: const [
                SaleOrderListLinePreviewResponseDto(
                  menuItemNameSnapshot: 'Iced Latte',
                  quantity: 2,
                  modifierLabels: ['Less ice'],
                ),
              ],
              checkedOutAt: null,
              paymentMethod: null,
              manualPaymentClaimId: 'claim-1',
              manualPaymentClaimStatus: 'PENDING',
              createdAt: DateTime.utc(2026, 3, 18, 9, 0),
              updatedAt: DateTime.utc(2026, 3, 18, 9, 1),
            ),
          ],
          limit: 50,
          offset: 0,
          total: 1,
          hasMore: false,
        ),
      );
      final result = await repository.getOrders(const SaleOrdersQueryDto());

      expect(result.items, hasLength(1));
      expect(result.items.single.orderId, 'order-open');
      expect(result.items.single.saleId, isEmpty);
      expect(result.items.single.ticketStatus, 'UNPAID');
      expect(result.items.single.fulfillmentStatus, 'in_prep');
      expect(result.items.single.totalUsdExact, 5);
      expect(result.items.single.manualPaymentClaimStatus, 'PENDING');
      expect(result.items.single.linesPreview.single.quantity, 2);
      verifyNever(() => api.getOrderDetail(any()));
    },
  );
}
