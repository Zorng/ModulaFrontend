import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/sale/data/mock_sale_repository.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

import '../test_utils/riverpod_test_utils.dart';

void main() {
  SaleCartLineInputDto buildLine({
    required String menuItemId,
    int quantity = 1,
    double unitPriceUsd = 2,
  }) {
    return SaleCartLineInputDto(
      menuItemId: menuItemId,
      quantity: quantity,
      modifiers: const [],
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: unitPriceUsd,
    );
  }

  test(
    'OrdersNotifier keeps unpaid open tickets visible and settleable when pay-later is disabled',
    () async {
      final repo = MockSaleRepository();
      final placed = await repo.placeOrder(
        SalePlaceOrderCommand(
          saleId: 'sale-open-ticket-1',
          branchId: 'mock-branch-001',
          saleType: 'dine_in',
          clientOpId: 'place-open-ticket-1',
          cartLines: [buildLine(menuItemId: 'item-1', unitPriceUsd: 3)],
        ),
      );
      repo.configureContext(payLaterEnabled: false);

      final container = createTestContainer(
        overrides: [saleRepositoryProvider.overrideWithValue(repo)],
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.load(date: DateTime.now());

      final pendingOrder = container
          .read(ordersProvider)
          .firstWhere((order) => order.openTicketId == placed.openTicketId);
      expect(pendingOrder.status, 'pending');
      expect(pendingOrder.ticketStatus, 'UNPAID');
      expect(pendingOrder.isSettleableOpenTicket, isTrue);

      await notifier.settleOpenTicket(pendingOrder, tenderCurrency: 'USD');

      final settledOrder = container
          .read(ordersProvider)
          .firstWhere((order) => order.saleId == placed.saleId);
      expect(settledOrder.ticketStatus, 'PAID');
      expect(settledOrder.status, 'in_prep');
      expect(settledOrder.isSettleableOpenTicket, isFalse);
    },
  );
}
