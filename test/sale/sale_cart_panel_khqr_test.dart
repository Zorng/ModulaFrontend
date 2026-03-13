import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';

import '../test_utils/riverpod_test_utils.dart';

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

class _StaticMenuViewModel extends MenuViewModel {
  _StaticMenuViewModel(this._state);

  final MenuState _state;

  @override
  MenuState build() => _state;

  @override
  Future<void> loadMenu({
    String? branchId,
    MenuReadLane readLane = MenuReadLane.management,
  }) async {}
}

class _KhqrCartNotifier extends SaleCartNotifier {
  _KhqrCartNotifier(this._initial);

  final SaleCartState _initial;
  int generateCallCount = 0;

  @override
  SaleCartState build() => _initial;

  @override
  Future<void> generateKhqrAttempt() async {
    generateCallCount += 1;
    state = state.copyWith(
      khqrStatus: SaleKhqrUiStates.waitingForPayment,
      khqrAttemptId: 'intent-1',
      khqrMd5: 'md5-1',
      khqrQrPayload: 'KHQR:payload',
      khqrPayloadType: 'EMV_KHQR_STRING',
      khqrToAccountId: 'bakong-001',
      khqrCurrency: 'USD',
    );
  }
}

class _CompletedKhqrCartNotifier extends SaleCartNotifier {
  _CompletedKhqrCartNotifier(this._initial);

  final SaleCartState _initial;
  int checkoutCallCount = 0;

  @override
  SaleCartState build() => _initial;

  @override
  Future<SaleCheckoutResult> checkout() async {
    checkoutCallCount += 1;
    state = const SaleCartState(lastFinalizedSaleId: 'sale-finalized-1');
    return const SaleCheckoutResult(
      summary: SaleCheckoutSummary(
        saleId: 'sale-finalized-1',
        tenderCurrency: 'usd',
        paymentMethod: 'qr',
        totalUsdExact: 2.5,
        totalKhrExact: 10000,
        cashReceivedUsd: 0,
        cashReceivedKhr: 0,
        changeGivenUsd: 0,
        changeGivenKhr: 0,
      ),
      idempotentReplay: false,
    );
  }
}

class _OrdersSpyNotifier extends OrdersNotifier {
  int loadCallCount = 0;

  @override
  List<Order> build() => const [];

  @override
  Future<void> load({DateTime? date}) async {
    loadCallCount += 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cart Generate Code action generates first and opens popup', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const item = MenuItem(
      id: 'menu-1',
      name: 'Latte',
      categoryId: 'cat-1',
      price: 2.5,
    );
    final notifier = _KhqrCartNotifier(
      const SaleCartState(
        saleId: 'sale-1',
        paymentMethod: 'qr',
        tenderCurrency: 'USD',
        khqrStatus: SaleKhqrUiStates.readyToGenerate,
        lines: [CartLine(item: item, quantity: 1, selectedOptionIds: {})],
      ),
    );

    final container = createTestContainer(
      overrides: [
        saleCartProvider.overrideWith(() => notifier),
        saleKhqrReceiverConfiguredProvider.overrideWithValue(true),
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(const MenuState(isLoading: false)),
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SaleCartPanel())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Generate Code'));
    await tester.pumpAndSettle();

    expect(notifier.generateCallCount, 1);
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Waiting for payment')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(FilledButton, 'Generate KHQR'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(OutlinedButton, 'Cancel KHQR'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('confirmed popup Done finalizes checkout and clears cart', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const item = MenuItem(
      id: 'menu-1',
      name: 'Latte',
      categoryId: 'cat-1',
      price: 2.5,
    );
    final notifier = _CompletedKhqrCartNotifier(
      const SaleCartState(
        saleId: 'sale-1',
        paymentMethod: 'qr',
        tenderCurrency: 'USD',
        khqrStatus: SaleKhqrUiStates.paidConfirmed,
        lines: [CartLine(item: item, quantity: 1, selectedOptionIds: {})],
      ),
    );
    final ordersSpy = _OrdersSpyNotifier();

    final container = createTestContainer(
      overrides: [
        saleCartProvider.overrideWith(() => notifier),
        ordersProvider.overrideWith(() => ordersSpy),
        saleKhqrReceiverConfiguredProvider.overrideWithValue(true),
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(const MenuState(isLoading: false)),
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SaleCartPanel())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'View Code'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();

    expect(notifier.checkoutCallCount, 1);
    expect(ordersSpy.loadCallCount, 1);
    expect(container.read(saleCartProvider).lines, isEmpty);
    expect(
      container.read(saleCartProvider).lastFinalizedSaleId,
      'sale-finalized-1',
    );
  });
}
