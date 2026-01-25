import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';

import '../test_utils/riverpod_test_utils.dart';

class _MockSaleRepository extends Mock implements SaleRepository {}

class _StaticPolicyNotifier extends PolicyNotifier {
  @override
  PolicyState build() {
    return const PolicyState(
      isLoading: false,
      salesPolicy: SalesPolicy(saleFxRateKhrPerUsd: 4000),
      inventoryPolicy: InventoryPolicy(),
      cashSessionPolicy: CashSessionPolicy(),
    );
  }
}

void main() {
  setUpAll(() {
    // Used by mocktail when matching non-primitive arguments via `any(...)`.
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<String, dynamic>{});
  });

  test(
    'SaleCartNotifier.addSelection throws and does not call repository when blocked',
    () async {
      final repo = _MockSaleRepository();

      final container = createTestContainer(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              cashSessionOpen: false,
              cashSessionLoading: false,
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
                e.toString().contains('Cash session required'),
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
          menuItemId: any(named: 'menuItemId'),
          quantity: any(named: 'quantity'),
          modifiers: any(named: 'modifiers'),
          selectedOptionIds: any(named: 'selectedOptionIds'),
          unitPriceUsd: any(named: 'unitPriceUsd'),
          lineTotalUsdExact: any(named: 'lineTotalUsdExact'),
          addonTotalUsd: any(named: 'addonTotalUsd'),
          pricingSnapshot: any(named: 'pricingSnapshot'),
        ),
      );
    },
  );

  test(
    'SaleCartNotifier.addSelection creates draft + syncs item when allowed',
    () async {
      final repo = _MockSaleRepository();

      when(
        () => repo.ensureDraft(
          saleType: any(named: 'saleType'),
          fxRateUsed: any(named: 'fxRateUsed'),
        ),
      ).thenAnswer((_) async => 'sale-1');

      when(
        () => repo.addItem(
          saleId: any(named: 'saleId'),
          menuItemId: any(named: 'menuItemId'),
          quantity: any(named: 'quantity'),
          modifiers: any(named: 'modifiers'),
          selectedOptionIds: any(named: 'selectedOptionIds'),
          unitPriceUsd: any(named: 'unitPriceUsd'),
          lineTotalUsdExact: any(named: 'lineTotalUsdExact'),
          addonTotalUsd: any(named: 'addonTotalUsd'),
          pricingSnapshot: any(named: 'pricingSnapshot'),
        ),
      ).thenAnswer((_) async => 'sale-item-1');

      final container = createTestContainer(
        overrides: [
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          saleRepositoryProvider.overrideWithValue(repo),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              cashSessionOpen: true,
              cashSessionLoading: false,
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

      verify(
        () => repo.ensureDraft(
          saleType: any(named: 'saleType'),
          fxRateUsed: any(named: 'fxRateUsed'),
        ),
      ).called(1);
      verify(
        () => repo.addItem(
          saleId: any(named: 'saleId'),
          menuItemId: any(named: 'menuItemId'),
          quantity: any(named: 'quantity'),
          modifiers: any(named: 'modifiers'),
          selectedOptionIds: any(named: 'selectedOptionIds'),
          unitPriceUsd: any(named: 'unitPriceUsd'),
          lineTotalUsdExact: any(named: 'lineTotalUsdExact'),
          addonTotalUsd: any(named: 'addonTotalUsd'),
          pricingSnapshot: any(named: 'pricingSnapshot'),
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
    'SaleCartNotifier.addSelection creates draft + syncs item when session required but open',
    () async {
      final repo = _MockSaleRepository();

      when(
        () => repo.ensureDraft(
          saleType: any(named: 'saleType'),
          fxRateUsed: any(named: 'fxRateUsed'),
        ),
      ).thenAnswer((_) async => 'sale-1');

      when(
        () => repo.addItem(
          saleId: any(named: 'saleId'),
          menuItemId: any(named: 'menuItemId'),
          quantity: any(named: 'quantity'),
          modifiers: any(named: 'modifiers'),
          selectedOptionIds: any(named: 'selectedOptionIds'),
          unitPriceUsd: any(named: 'unitPriceUsd'),
          lineTotalUsdExact: any(named: 'lineTotalUsdExact'),
          addonTotalUsd: any(named: 'addonTotalUsd'),
          pricingSnapshot: any(named: 'pricingSnapshot'),
        ),
      ).thenAnswer((_) async => 'sale-item-1');

      final container = createTestContainer(
        overrides: [
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          saleRepositoryProvider.overrideWithValue(repo),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              cashSessionOpen: true,
              cashSessionLoading: false,
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

      verify(
        () => repo.ensureDraft(
          saleType: any(named: 'saleType'),
          fxRateUsed: any(named: 'fxRateUsed'),
        ),
      ).called(1);
      verify(
        () => repo.addItem(
          saleId: any(named: 'saleId'),
          menuItemId: any(named: 'menuItemId'),
          quantity: any(named: 'quantity'),
          modifiers: any(named: 'modifiers'),
          selectedOptionIds: any(named: 'selectedOptionIds'),
          unitPriceUsd: any(named: 'unitPriceUsd'),
          lineTotalUsdExact: any(named: 'lineTotalUsdExact'),
          addonTotalUsd: any(named: 'addonTotalUsd'),
          pricingSnapshot: any(named: 'pricingSnapshot'),
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
}
