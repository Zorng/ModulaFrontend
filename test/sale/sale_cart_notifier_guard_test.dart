import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/riverpod_test_utils.dart';

class _MockSaleRepository extends Mock implements SaleCheckoutRepository {}

class _StaticPolicyNotifier extends PolicyNotifier {
  @override
  PolicyState build() {
    return const PolicyState(
      isLoading: false,
      branchPolicy: BranchPolicy(
        saleFxRateKhrPerUsd: 4000,
        saleAllowPayLater: true,
      ),
    );
  }
}

class _PrefilledCartNotifier extends SaleCartNotifier {
  _PrefilledCartNotifier(this._initial);

  final SaleCartState _initial;

  @override
  SaleCartState build() => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Used by mocktail when matching non-primitive arguments via `any(...)`.
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(
      const SaleDraftItemInputDto(
        menuItemId: 'menu-1',
        quantity: 1,
        selectedOptionIds: {},
        modifiers: [],
      ),
    );
    registerFallbackValue(
      const SalePlaceOrderCommand(
        saleId: 'sale-1',
        branchId: 'branch-1',
        saleType: 'dine_in',
        clientOpId: 'op-1',
        cartLines: [],
      ),
    );
    registerFallbackValue(
      const SaleFinalizeSaleCommand(
        saleId: 'sale-1',
        paymentMethod: 'cash',
        tenderCurrency: 'USD',
        clientOpId: 'finalize-op-1',
      ),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'SaleCartNotifier.addSelection throws and does not call repository when branch is frozen',
    () async {
      final repo = _MockSaleRepository();

      final container = createTestContainer(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              contextLoading: false,
              branchActive: true,
              branchFrozen: true,
              cashSessionOpen: true,
              canMutateCart: false,
              canCheckout: false,
              canPlacePayLater: false,
              reasonCode: SaleCheckoutReasonCodes.branchFrozen,
            ),
          ),
        ],
      );

      final notifier = container.read(saleCartProvider.notifier);
      const item = MenuItem(
        id: 'menu-1',
        name: 'Item',
        categoryId: 'cat-1',
        price: 1.5,
      );
      const selection = SaleItemSelectionResult(
        item: item,
        quantity: 1,
        selectedOptionIds: {},
        selectedOptions: {},
        addonTotalUsd: 0,
        unitPriceUsd: 1.5,
        lineTotalUsd: 1.5,
      );

      await expectLater(
        notifier.addSelection(selection),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().toLowerCase().contains('branch is frozen'),
          ),
        ),
      );

      verifyNever(
        () => repo.ensureDraft(
          saleType: any(named: 'saleType'),
          fxRateUsed: any(named: 'fxRateUsed'),
        ),
      );
      verifyNever(
        () => repo.addItem(
          saleId: any(named: 'saleId'),
          item: any(named: 'item'),
        ),
      );
    },
  );

  test(
    'SaleCartNotifier.addSelection keeps pay-now cart local when allowed',
    () async {
      final repo = _MockSaleRepository();

      final container = createTestContainer(
        overrides: [
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          saleRepositoryProvider.overrideWithValue(repo),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              contextLoading: false,
              branchActive: true,
              branchFrozen: false,
              cashSessionOpen: true,
              canMutateCart: true,
              canCheckout: true,
              canPlacePayLater: true,
            ),
          ),
        ],
      );

      final notifier = container.read(saleCartProvider.notifier);
      const item = MenuItem(
        id: 'menu-1',
        name: 'Item',
        categoryId: 'cat-1',
        price: 1.5,
      );
      const selection = SaleItemSelectionResult(
        item: item,
        quantity: 1,
        selectedOptionIds: {},
        selectedOptions: {},
        addonTotalUsd: 0,
        unitPriceUsd: 1.5,
        lineTotalUsd: 1.5,
      );

      await notifier.addSelection(selection);

      verifyNever(
        () => repo.ensureDraft(
          saleType: any(named: 'saleType'),
          fxRateUsed: any(named: 'fxRateUsed'),
        ),
      );
      verifyNever(
        () => repo.addItem(
          saleId: any(named: 'saleId'),
          item: any(named: 'item'),
        ),
      );

      final state = container.read(saleCartProvider);
      expect(state.saleId, isNull);
      expect(state.lines, hasLength(1));
      expect(state.lines.first.item.id, 'menu-1');
      expect(state.lines.first.quantity, 1);
      expect(state.lines.first.saleItemId, isNull);
    },
  );

  test(
    'SaleCartNotifier.addSelection syncs remotely when cart already has a saleId',
    () async {
      final repo = _MockSaleRepository();

      when(
        () => repo.addItem(
          saleId: any(named: 'saleId'),
          item: any(named: 'item'),
        ),
      ).thenAnswer((_) async => 'sale-item-1');

      final container = createTestContainer(
        overrides: [
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          saleRepositoryProvider.overrideWithValue(repo),
          saleCartProvider.overrideWith(
            () => _PrefilledCartNotifier(const SaleCartState(saleId: 'sale-1')),
          ),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              contextLoading: false,
              branchActive: true,
              branchFrozen: false,
              cashSessionOpen: true,
              canMutateCart: true,
              canCheckout: true,
              canPlacePayLater: true,
            ),
          ),
        ],
      );

      final notifier = container.read(saleCartProvider.notifier);
      const item = MenuItem(
        id: 'menu-1',
        name: 'Item',
        categoryId: 'cat-1',
        price: 1.5,
      );
      const selection = SaleItemSelectionResult(
        item: item,
        quantity: 1,
        selectedOptionIds: {},
        selectedOptions: {},
        addonTotalUsd: 0,
        unitPriceUsd: 1.5,
        lineTotalUsd: 1.5,
      );

      await notifier.addSelection(selection);

      verifyNever(
        () => repo.ensureDraft(
          saleType: any(named: 'saleType'),
          fxRateUsed: any(named: 'fxRateUsed'),
        ),
      );
      verify(
        () => repo.addItem(
          saleId: any(named: 'saleId'),
          item: any(named: 'item'),
        ),
      ).called(1);

      final state = container.read(saleCartProvider);
      expect(state.saleId, 'sale-1');
      expect(state.lines, hasLength(1));
      expect(state.lines.first.item.id, 'menu-1');
      expect(state.lines.first.quantity, 1);
      expect(state.lines.first.saleItemId, 'sale-item-1');
    },
  );

  test(
    'SaleCartNotifier.placeOrder throws and does not call repository when pay-later is blocked',
    () async {
      final repo = _MockSaleRepository();
      const item = MenuItem(
        id: 'menu-1',
        name: 'Item',
        categoryId: 'cat-1',
        price: 2.0,
      );

      final container = createTestContainer(
        overrides: [
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          saleRepositoryProvider.overrideWithValue(repo),
          saleCartProvider.overrideWith(
            () => _PrefilledCartNotifier(
              const SaleCartState(
                saleId: 'sale-1',
                saleType: 'dine_in',
                lines: [
                  CartLine(item: item, quantity: 1, selectedOptionIds: {}),
                ],
              ),
            ),
          ),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              contextLoading: false,
              branchActive: true,
              branchFrozen: false,
              cashSessionOpen: true,
              canMutateCart: true,
              canCheckout: true,
              canPlacePayLater: false,
              reasonCode: SaleCheckoutReasonCodes.payLaterDisabled,
            ),
          ),
        ],
      );

      final notifier = container.read(saleCartProvider.notifier);
      await expectLater(
        notifier.placeOrder(),
        throwsA(
          isA<SaleCheckoutRepositoryException>().having(
            (e) => e.reasonCode,
            'reasonCode',
            SaleCheckoutReasonCodes.payLaterDisabled,
          ),
        ),
      );

      final state = container.read(saleCartProvider);
      expect(state.checkoutErrorCode, SaleCheckoutReasonCodes.payLaterDisabled);
      expect(state.isCheckoutDenied, isTrue);
      expect(state.isCheckoutOffline, isFalse);
      verifyNever(() => repo.placeOrder(any()));
    },
  );

  test(
    'SaleCartNotifier.checkout throws stable reason code when sale gate blocks checkout',
    () async {
      final repo = _MockSaleRepository();
      const item = MenuItem(
        id: 'menu-1',
        name: 'Item',
        categoryId: 'cat-1',
        price: 2.0,
      );

      final container = createTestContainer(
        overrides: [
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          saleRepositoryProvider.overrideWithValue(repo),
          saleCartProvider.overrideWith(
            () => _PrefilledCartNotifier(
              const SaleCartState(
                saleId: 'sale-1',
                paymentMethod: 'cash',
                lines: [
                  CartLine(item: item, quantity: 1, selectedOptionIds: {}),
                ],
              ),
            ),
          ),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              contextLoading: false,
              branchActive: true,
              branchFrozen: false,
              cashSessionOpen: false,
              canMutateCart: true,
              canCheckout: false,
              canPlacePayLater: false,
              reasonCode: SaleCheckoutReasonCodes.cashSessionRequired,
            ),
          ),
        ],
      );

      final notifier = container.read(saleCartProvider.notifier);
      await expectLater(
        notifier.checkout(),
        throwsA(
          isA<SaleCheckoutRepositoryException>().having(
            (e) => e.reasonCode,
            'reasonCode',
            SaleCheckoutReasonCodes.cashSessionRequired,
          ),
        ),
      );

      final state = container.read(saleCartProvider);
      expect(
        state.checkoutErrorCode,
        SaleCheckoutReasonCodes.cashSessionRequired,
      );
      expect(state.isCheckoutDenied, isTrue);
      expect(state.isCheckoutOffline, isFalse);
      verifyNever(() => repo.finalizeSale(any()));
    },
  );

  test(
    'SaleCartNotifier.placeOrder calls repository and clears cart on success',
    () async {
      final repo = _MockSaleRepository();
      const item = MenuItem(
        id: 'menu-1',
        name: 'Item',
        categoryId: 'cat-1',
        price: 2.0,
      );

      when(() => repo.placeOrder(any())).thenAnswer(
        (_) async => const SalePlaceOrderResultDto(
          openTicketId: 'ticket-1',
          saleId: 'sale-1',
          status: 'UNPAID',
          batchId: 'batch-1',
          idempotentReplay: false,
        ),
      );

      final container = createTestContainer(
        overrides: [
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          saleRepositoryProvider.overrideWithValue(repo),
          saleCartProvider.overrideWith(
            () => _PrefilledCartNotifier(
              const SaleCartState(
                saleId: 'sale-1',
                saleType: 'dine_in',
                lines: [
                  CartLine(item: item, quantity: 2, selectedOptionIds: {}),
                ],
              ),
            ),
          ),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              contextLoading: false,
              branchActive: true,
              branchFrozen: false,
              cashSessionOpen: true,
              canMutateCart: true,
              canCheckout: true,
              canPlacePayLater: true,
            ),
          ),
        ],
      );

      final notifier = container.read(saleCartProvider.notifier);
      final result = await notifier.placeOrder();

      verify(() => repo.placeOrder(any())).called(1);
      expect(result.openTicketId, 'ticket-1');

      final state = container.read(saleCartProvider);
      expect(state.lines, isEmpty);
      expect(state.saleId, isNull);
      expect(state.lastPlacedOpenTicketId, 'ticket-1');
      expect(state.lastPlacedSaleId, 'sale-1');
    },
  );

  test(
    'SaleCartNotifier.placeOrder preserves cart and exposes error on repository failure',
    () async {
      final repo = _MockSaleRepository();
      const item = MenuItem(
        id: 'menu-1',
        name: 'Item',
        categoryId: 'cat-1',
        price: 2.0,
      );

      when(() => repo.placeOrder(any())).thenThrow(
        const SaleCheckoutRepositoryException(
          reasonCode: SaleCheckoutReasonCodes.offlineUnreachable,
          message: 'Network unavailable.',
        ),
      );

      final container = createTestContainer(
        overrides: [
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          saleRepositoryProvider.overrideWithValue(repo),
          saleCartProvider.overrideWith(
            () => _PrefilledCartNotifier(
              const SaleCartState(
                saleId: 'sale-1',
                saleType: 'dine_in',
                lines: [
                  CartLine(item: item, quantity: 2, selectedOptionIds: {}),
                ],
              ),
            ),
          ),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              contextLoading: false,
              branchActive: true,
              branchFrozen: false,
              cashSessionOpen: true,
              canMutateCart: true,
              canCheckout: true,
              canPlacePayLater: true,
            ),
          ),
        ],
      );

      final notifier = container.read(saleCartProvider.notifier);
      await expectLater(
        notifier.placeOrder(),
        throwsA(isA<SaleCheckoutRepositoryException>()),
      );

      verify(() => repo.placeOrder(any())).called(1);

      final state = container.read(saleCartProvider);
      expect(state.saleId, 'sale-1');
      expect(state.lines, hasLength(1));
      expect(state.lines.first.quantity, 2);
      expect(state.isFinalizing, isFalse);
      expect(
        state.checkoutErrorMessage,
        'This action requires online connectivity.',
      );
      expect(
        state.checkoutErrorCode,
        SaleCheckoutReasonCodes.offlineUnreachable,
      );
      expect(state.isCheckoutOffline, isTrue);
      expect(state.isCheckoutDenied, isFalse);
      expect(state.isCheckoutIdempotencyIssue, isFalse);
      expect(state.lastPlacedOpenTicketId, isNull);
      expect(state.lastPlacedSaleId, isNull);
    },
  );

  test(
    'SaleCartNotifier.checkout stores deterministic idempotency failure state',
    () async {
      final repo = _MockSaleRepository();
      const item = MenuItem(
        id: 'menu-1',
        name: 'Item',
        categoryId: 'cat-1',
        price: 2.0,
      );

      when(() => repo.finalizeSale(any())).thenThrow(
        const SaleCheckoutRepositoryException(
          reasonCode: SaleCheckoutReasonCodes.idempotencyConflict,
          message: 'Backend idempotency lane is still running.',
        ),
      );

      final container = createTestContainer(
        overrides: [
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          saleRepositoryProvider.overrideWithValue(repo),
          saleCartProvider.overrideWith(
            () => _PrefilledCartNotifier(
              const SaleCartState(
                saleId: 'sale-1',
                paymentMethod: 'cash',
                cashUsd: 10,
                lines: [
                  CartLine(item: item, quantity: 1, selectedOptionIds: {}),
                ],
              ),
            ),
          ),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              contextLoading: false,
              branchActive: true,
              branchFrozen: false,
              cashSessionOpen: true,
              canMutateCart: true,
              canCheckout: true,
              canPlacePayLater: true,
            ),
          ),
        ],
      );

      final notifier = container.read(saleCartProvider.notifier);
      await expectLater(
        notifier.checkout(),
        throwsA(
          isA<SaleCheckoutRepositoryException>().having(
            (e) => e.reasonCode,
            'reasonCode',
            SaleCheckoutReasonCodes.idempotencyConflict,
          ),
        ),
      );

      final state = container.read(saleCartProvider);
      expect(
        state.checkoutErrorMessage,
        'This checkout is already processing. Please wait before retrying.',
      );
      expect(
        state.checkoutErrorCode,
        SaleCheckoutReasonCodes.idempotencyConflict,
      );
      expect(state.isCheckoutIdempotencyIssue, isTrue);
      expect(state.isCheckoutOffline, isFalse);
      expect(state.isCheckoutDenied, isFalse);
    },
  );
}
