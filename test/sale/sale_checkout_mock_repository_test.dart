import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/cash_session/data/mock_cash_session_repository.dart';
import 'package:modular_pos/features/sale/data/mock_sale_repository.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';

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

  SaleDraftItemInputDto buildDraftItem({
    required String menuItemId,
    int quantity = 1,
    double unitPriceUsd = 2,
  }) {
    return SaleDraftItemInputDto(
      menuItemId: menuItemId,
      quantity: quantity,
      selectedOptionIds: const {},
      modifiers: const [],
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: unitPriceUsd,
    );
  }

  test('pay-first cash finalize succeeds and receipt is available', () async {
    final repo = MockSaleRepository();

    final saleId = await repo.ensureDraft(saleType: 'take_away');
    await repo.addItem(
      saleId: saleId,
      item: buildDraftItem(menuItemId: 'item-1', quantity: 2),
    );

    final result = await repo.finalizeSale(
      SaleFinalizeSaleCommand(
        saleId: saleId,
        paymentMethod: 'cash',
        tenderCurrency: 'USD',
        clientOpId: 'finalize-op-1',
        cashReceived: const SaleCashReceivedInputDto(usd: 10),
      ),
    );

    expect(result.status, 'FINALIZED');
    expect(result.totalUsdExact, greaterThan(0));
    expect(result.idempotentReplay, isFalse);

    final receipt = await repo.getReceipt(saleId: saleId);
    expect(receipt.saleId, saleId);
    expect(receipt.lines, isNotEmpty);
  });

  test(
    'idempotency returns replay for same key and conflicts for payload change',
    () async {
      final repo = MockSaleRepository();

      final saleId = await repo.ensureDraft(saleType: 'take_away');
      await repo.addItem(
        saleId: saleId,
        item: buildDraftItem(menuItemId: 'item-1', unitPriceUsd: 3),
      );

      final command = SaleFinalizeSaleCommand(
        saleId: saleId,
        paymentMethod: 'cash',
        tenderCurrency: 'USD',
        clientOpId: 'finalize-op-stable',
        cashReceived: const SaleCashReceivedInputDto(usd: 10),
      );

      final first = await repo.finalizeSale(command);
      final replay = await repo.finalizeSale(command);

      expect(first.idempotentReplay, isFalse);
      expect(replay.idempotentReplay, isTrue);
      expect(replay.saleId, first.saleId);
      expect(replay.totalUsdExact, first.totalUsdExact);

      expect(
        () => repo.finalizeSale(
          SaleFinalizeSaleCommand(
            saleId: saleId,
            paymentMethod: 'cash',
            tenderCurrency: 'KHR',
            clientOpId: 'finalize-op-stable',
            cashReceived: const SaleCashReceivedInputDto(khr: 10000),
          ),
        ),
        throwsA(
          isA<SaleCheckoutRepositoryException>().having(
            (e) => e.reasonCode,
            'reasonCode',
            SaleCheckoutReasonCodes.idempotencyConflict,
          ),
        ),
      );
    },
  );

  test(
    'KHQR state machine transitions and superseded attempt behavior',
    () async {
      final repo = MockSaleRepository();

      final saleId = await repo.ensureDraft(saleType: 'take_away');
      await repo.addItem(
        saleId: saleId,
        item: buildDraftItem(menuItemId: 'item-1', unitPriceUsd: 5),
      );

      final firstAttempt = await repo.generateKhqrAttempt(
        SaleGenerateKhqrAttemptCommand(
          saleId: saleId,
          tenderCurrency: 'USD',
          clientOpId: 'khqr-generate-1',
        ),
      );

      final firstPoll = await repo.checkKhqrStatus(
        SaleCheckKhqrStatusCommand(saleId: saleId, md5: firstAttempt.md5),
      );
      final secondPoll = await repo.checkKhqrStatus(
        SaleCheckKhqrStatusCommand(saleId: saleId, md5: firstAttempt.md5),
      );

      expect(firstPoll.status, 'WAITING_FOR_PAYMENT');
      expect(secondPoll.status, 'PAID_CONFIRMED');

      await repo.generateKhqrAttempt(
        SaleGenerateKhqrAttemptCommand(
          saleId: saleId,
          tenderCurrency: 'USD',
          clientOpId: 'khqr-generate-2',
        ),
      );

      final supersededStatus = await repo.checkKhqrStatus(
        SaleCheckKhqrStatusCommand(saleId: saleId, md5: firstAttempt.md5),
      );
      expect(supersededStatus.status, 'SUPERSEDED');
    },
  );

  test(
    'KHQR cancel returns cancelled state and supports idempotent replay',
    () async {
      final repo = MockSaleRepository();

      final saleId = await repo.ensureDraft(saleType: 'take_away');
      await repo.addItem(
        saleId: saleId,
        item: buildDraftItem(menuItemId: 'item-1', unitPriceUsd: 5),
      );

      final attempt = await repo.generateKhqrAttempt(
        SaleGenerateKhqrAttemptCommand(
          saleId: saleId,
          tenderCurrency: 'USD',
          clientOpId: 'khqr-generate-cancel-1',
        ),
      );

      final cancelled = await repo.cancelKhqrAttempt(
        SaleCancelKhqrAttemptCommand(
          saleId: saleId,
          md5: attempt.md5,
          intentId: attempt.attemptId,
          clientOpId: 'khqr-cancel-1',
        ),
      );

      final replay = await repo.cancelKhqrAttempt(
        SaleCancelKhqrAttemptCommand(
          saleId: saleId,
          md5: attempt.md5,
          intentId: attempt.attemptId,
          clientOpId: 'khqr-cancel-1',
        ),
      );

      expect(cancelled.status, 'CANCELLED');
      expect(replay.status, 'CANCELLED');
    },
  );

  test(
    'pay-later place/add/checkout happy path works with stable statuses',
    () async {
      final repo = MockSaleRepository();

      final placed = await repo.placeOrder(
        SalePlaceOrderCommand(
          saleId: 'sale-paylater-1',
          branchId: 'mock-branch-001',
          saleType: 'dine_in',
          clientOpId: 'place-op-1',
          cartLines: [buildLine(menuItemId: 'item-1', unitPriceUsd: 2)],
        ),
      );

      expect(placed.status, 'UNPAID');

      final added = await repo.addItemsToOpenTicket(
        SaleAddItemsToOpenTicketCommand(
          openTicketId: placed.openTicketId,
          clientOpId: 'add-op-1',
          cartLines: [buildLine(menuItemId: 'item-2', unitPriceUsd: 3)],
        ),
      );

      expect(added.idempotentReplay, isFalse);

      final detail = await repo.getOpenTicketDetail(saleId: placed.saleId);
      expect(detail.batches.length, 2);
      expect(detail.status, 'UNPAID');

      final settled = await repo.checkoutOpenTicket(
        SaleCheckoutOpenTicketCommand(
          openTicketId: placed.openTicketId,
          paymentMethod: 'cash',
          tenderCurrency: 'USD',
          clientOpId: 'checkout-op-1',
          cashReceived: const SaleCashReceivedInputDto(usd: 20),
        ),
      );

      expect(settled.status, 'PAID');
      expect(settled.idempotentReplay, isFalse);

      final receipt = await repo.getReceipt(saleId: placed.saleId);
      expect(receipt.lines, isNotEmpty);
    },
  );

  test(
    'cancel unpaid ticket requires reason and supports idempotent replay',
    () async {
      final repo = MockSaleRepository();

      final placed = await repo.placeOrder(
        SalePlaceOrderCommand(
          saleId: 'sale-paylater-2',
          branchId: 'mock-branch-001',
          saleType: 'take_away',
          clientOpId: 'place-op-2',
          cartLines: [buildLine(menuItemId: 'item-1')],
        ),
      );

      final cancelled = await repo.cancelOpenTicket(
        SaleCancelOpenTicketCommand(
          openTicketId: placed.openTicketId,
          reason: 'Customer left',
          clientOpId: 'cancel-op-1',
        ),
      );

      final replay = await repo.cancelOpenTicket(
        SaleCancelOpenTicketCommand(
          openTicketId: placed.openTicketId,
          reason: 'Customer left',
          clientOpId: 'cancel-op-1',
        ),
      );

      expect(cancelled.status, 'CANCELLED');
      expect(cancelled.idempotentReplay, isFalse);
      expect(replay.idempotentReplay, isTrue);
    },
  );

  test(
    'reason_code failures are returned for policy/session/online constraints',
    () async {
      final repo = MockSaleRepository();

      repo.configureContext(cashSessionOpen: false);
      expect(
        () => repo.placeOrder(
          SalePlaceOrderCommand(
            saleId: 'sale-guard-1',
            branchId: 'mock-branch-001',
            saleType: 'dine_in',
            clientOpId: 'place-guard-1',
            cartLines: [buildLine(menuItemId: 'item-1')],
          ),
        ),
        throwsA(
          isA<SaleCheckoutRepositoryException>().having(
            (e) => e.reasonCode,
            'reasonCode',
            SaleCheckoutReasonCodes.cashSessionRequired,
          ),
        ),
      );

      repo.configureContext(cashSessionOpen: true, online: false);
      expect(
        () => repo.placeOrder(
          SalePlaceOrderCommand(
            saleId: 'sale-guard-2',
            branchId: 'mock-branch-001',
            saleType: 'dine_in',
            clientOpId: 'place-guard-2',
            cartLines: [buildLine(menuItemId: 'item-1')],
          ),
        ),
        throwsA(
          isA<SaleCheckoutRepositoryException>().having(
            (e) => e.reasonCode,
            'reasonCode',
            SaleCheckoutReasonCodes.offlineUnreachable,
          ),
        ),
      );

      repo.configureContext(online: true, payLaterEnabled: false);
      expect(
        () => repo.placeOrder(
          SalePlaceOrderCommand(
            saleId: 'sale-guard-3',
            branchId: 'mock-branch-001',
            saleType: 'dine_in',
            clientOpId: 'place-guard-3',
            cartLines: [buildLine(menuItemId: 'item-1')],
          ),
        ),
        throwsA(
          isA<SaleCheckoutRepositoryException>().having(
            (e) => e.reasonCode,
            'reasonCode',
            SaleCheckoutReasonCodes.payLaterDisabled,
          ),
        ),
      );
    },
  );

  test('mock repository adopts incoming active branch context', () async {
    final repo = MockSaleRepository();

    final context = await repo.getSaleContext(branchId: 'branch-from-ui');
    expect(context.branchId, 'branch-from-ui');
    expect(context.reasonCode, isNull);

    final placed = await repo.placeOrder(
      SalePlaceOrderCommand(
        saleId: 'sale-branch-adopt-1',
        branchId: 'branch-from-ui',
        saleType: 'take_away',
        clientOpId: 'place-branch-adopt-1',
        cartLines: [buildLine(menuItemId: 'item-1')],
      ),
    );

    expect(placed.status, 'UNPAID');
  });

  test('mock sale context follows shared cash-session mock state', () async {
    final cashSessionRepo = MockCashSessionRepository();
    final saleRepo = MockSaleRepository(
      cashSessionOpenReader: () => cashSessionRepo.isSessionOpen,
    );

    final blockedContext = await saleRepo.getSaleContext(branchId: 'branch-1');
    expect(blockedContext.cashSessionOpen, isFalse);
    expect(
      blockedContext.reasonCode,
      SaleCheckoutReasonCodes.cashSessionRequired,
    );

    await cashSessionRepo.openSession(
      openingFloatUsd: 10,
      openingFloatKhr: 40000,
    );

    final openContext = await saleRepo.getSaleContext(branchId: 'branch-1');
    expect(openContext.cashSessionOpen, isTrue);
    expect(openContext.reasonCode, isNull);
    expect(openContext.canCheckout, isTrue);
  });
}
