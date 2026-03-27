import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/sale_cart_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/fakes/fake_auth_repository.dart';
import '../test_utils/riverpod_test_utils.dart';

class _MockSaleRepository extends Mock implements SaleRepository {}

class _StaticPolicyNotifier extends PolicyNotifier {
  @override
  PolicyState build() {
    return const PolicyState(
      isLoading: false,
      branchPolicy: BranchPolicy(
        saleFxRateKhrPerUsd: 4000,
        saleAllowPayLater: true,
        saleAllowManualExternalPaymentClaim: true,
      ),
    );
  }
}

class _VatPolicyNotifier extends PolicyNotifier {
  @override
  PolicyState build() {
    return const PolicyState(
      isLoading: false,
      branchPolicy: BranchPolicy(
        saleVatEnabled: true,
        saleVatRatePercent: 10,
        saleFxRateKhrPerUsd: 4000,
        saleAllowPayLater: true,
      ),
    );
  }
}

class _ManualClaimDisabledPolicyNotifier extends PolicyNotifier {
  @override
  PolicyState build() {
    return const PolicyState(
      isLoading: false,
      branchPolicy: BranchPolicy(
        saleFxRateKhrPerUsd: 4000,
        saleAllowPayLater: true,
        saleAllowManualExternalPaymentClaim: false,
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
    String? status,
    MenuReadLane readLane = MenuReadLane.management,
  }) async {}
}

class _PrefilledCartNotifier extends SaleCartNotifier {
  _PrefilledCartNotifier(this._initial);

  final SaleCartState _initial;

  @override
  SaleCartState build() => _initial;
}

class _TestSaleAccessGateNotifier extends Notifier<SaleAccessGate> {
  @override
  SaleAccessGate build() {
    return const SaleAccessGate(
      branchId: 'branch-1',
      contextLoading: false,
      branchActive: true,
      branchFrozen: false,
      cashSessionOpen: true,
      canMutateCart: true,
      canCheckout: true,
      canPlacePayLater: true,
    );
  }

  void setGate(SaleAccessGate value) => state = value;
}

class _OfflineConnectivityNotifier extends AppConnectivityStatusController {
  @override
  AppConnectivityStatus build() => AppConnectivityStatus.offline;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Cart checkout becomes disabled when sale becomes read-only', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);

    final gateStateProvider =
        NotifierProvider<_TestSaleAccessGateNotifier, SaleAccessGate>(
          _TestSaleAccessGateNotifier.new,
        );

    const item = MenuItem(
      id: 'menu-1',
      name: 'Latte',
      categoryId: 'cat-1',
      price: 1.5,
    );

    final container = createTestContainer(
      overrides: [
        authSessionStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        saleRepositoryProvider.overrideWithValue(_MockSaleRepository()),
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(const MenuState(isLoading: false)),
        ),
        saleCartProvider.overrideWith(
          () => _PrefilledCartNotifier(
            const SaleCartState(
              saleId: 'sale-1',
              lines: [CartLine(item: item, quantity: 1, selectedOptionIds: {})],
            ),
          ),
        ),
        saleAccessGateProvider.overrideWith(
          (ref) => ref.watch(gateStateProvider),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SaleCartPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '100');
    await tester.pumpAndSettle();

    final checkoutButton = find.widgetWithText(FilledButton, 'Checkout');
    expect(checkoutButton, findsOneWidget);
    expect(tester.widget<FilledButton>(checkoutButton).onPressed, isNotNull);

    container.read(gateStateProvider.notifier).state = const SaleAccessGate(
      branchId: 'branch-1',
      contextLoading: false,
      branchActive: true,
      branchFrozen: true,
      cashSessionOpen: false,
      canMutateCart: false,
      canCheckout: false,
      canPlacePayLater: false,
      reasonCode: SaleCheckoutReasonCodes.branchFrozen,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Cash session required'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Cash session'), findsNothing);
    expect(tester.widget<FilledButton>(checkoutButton).onPressed, isNull);
  });

  testWidgets('Cash checkout shows KHR change only', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);

    const item = MenuItem(
      id: 'menu-1',
      name: 'Latte',
      categoryId: 'cat-1',
      price: 1.5,
    );

    final container = createTestContainer(
      overrides: [
        authSessionStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        saleRepositoryProvider.overrideWithValue(_MockSaleRepository()),
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(const MenuState(isLoading: false)),
        ),
        saleCartProvider.overrideWith(
          () => _PrefilledCartNotifier(
            const SaleCartState(
              saleId: 'sale-1',
              lines: [CartLine(item: item, quantity: 1, selectedOptionIds: {})],
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SaleCartPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Estimated payable'), findsNothing);
    expect(find.text('VAT'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '5');
    await tester.pumpAndSettle();

    expect(find.text('Change (៛)'), findsOneWidget);
    expect(find.text('KHR 14,000'), findsOneWidget);
  });

  testWidgets(
    'offline cash flow uses Queue Cash Checkout primary action without requiring tendered cash',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);

      const item = MenuItem(
        id: 'menu-1',
        name: 'Latte',
        categoryId: 'cat-1',
        price: 1.5,
      );

      final container = createTestContainer(
        overrides: [
          authSessionStoreProvider.overrideWithValue(store),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          saleRepositoryProvider.overrideWithValue(_MockSaleRepository()),
          appConnectivityStatusProvider.overrideWith(
            _OfflineConnectivityNotifier.new,
          ),
          policyNotifierProvider.overrideWith(
            _ManualClaimDisabledPolicyNotifier.new,
          ),
          menuViewModelProvider.overrideWith(
            () => _StaticMenuViewModel(const MenuState(isLoading: false)),
          ),
          saleCartProvider.overrideWith(
            () => _PrefilledCartNotifier(
              const SaleCartState(
                saleId: 'sale-1',
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
              canMutateCart: false,
              canCheckout: false,
              canPlacePayLater: false,
              reasonCode: SaleCheckoutReasonCodes.cashSessionRequired,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SaleCartPage()),
        ),
      );

      await tester.pumpAndSettle();

      final captureButton = find.widgetWithText(
        FilledButton,
        'Queue Cash Checkout',
      );
      expect(captureButton, findsOneWidget);
      expect(tester.widget<FilledButton>(captureButton).onPressed, isNotNull);
      expect(find.widgetWithText(FilledButton, 'Checkout'), findsNothing);
    },
  );

  testWidgets(
    'offline QR flow disables KHQR checkout and asks the operator to reconnect',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);

      const item = MenuItem(
        id: 'menu-1',
        name: 'Latte',
        categoryId: 'cat-1',
        price: 1.5,
      );

      final container = createTestContainer(
        overrides: [
          authSessionStoreProvider.overrideWithValue(store),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          saleRepositoryProvider.overrideWithValue(_MockSaleRepository()),
          appConnectivityStatusProvider.overrideWith(
            _OfflineConnectivityNotifier.new,
          ),
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          menuViewModelProvider.overrideWith(
            () => _StaticMenuViewModel(const MenuState(isLoading: false)),
          ),
          saleCartProvider.overrideWith(
            () => _PrefilledCartNotifier(
              const SaleCartState(
                saleId: 'sale-1',
                paymentMethod: 'qr',
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
              canMutateCart: false,
              canCheckout: false,
              canPlacePayLater: false,
              reasonCode: SaleCheckoutReasonCodes.cashSessionRequired,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SaleCartPage()),
        ),
      );

      await tester.pumpAndSettle();

      final captureButton = find.widgetWithText(FilledButton, 'Generate Code');
      expect(captureButton, findsOneWidget);
      expect(tester.widget<FilledButton>(captureButton).onPressed, isNull);
      expect(
        find.text(
          'KHQR checkout is unavailable while offline. Reconnect to continue.',
        ),
        findsOneWidget,
      );
      expect(find.text('Capture KHQR Claim'), findsNothing);
    },
  );

  testWidgets('dine-in selection stays on pay-first checkout', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);

    const item = MenuItem(
      id: 'menu-1',
      name: 'Latte',
      categoryId: 'cat-1',
      price: 1.5,
    );

    final container = createTestContainer(
      overrides: [
        authSessionStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        saleRepositoryProvider.overrideWithValue(_MockSaleRepository()),
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(const MenuState(isLoading: false)),
        ),
        saleCartProvider.overrideWith(
          () => _PrefilledCartNotifier(
            const SaleCartState(
              saleId: 'sale-1',
              saleType: 'dine_in',
              lines: [CartLine(item: item, quantity: 1, selectedOptionIds: {})],
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SaleCartPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '5');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Checkout'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Place Order'), findsNothing);
  });

  testWidgets(
    'Cart shows tax row and tax-inclusive change when VAT is enabled',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);

      const item = MenuItem(
        id: 'menu-1',
        name: 'Latte',
        categoryId: 'cat-1',
        price: 1.5,
      );

      final container = createTestContainer(
        overrides: [
          authSessionStoreProvider.overrideWithValue(store),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          saleRepositoryProvider.overrideWithValue(_MockSaleRepository()),
          policyNotifierProvider.overrideWith(_VatPolicyNotifier.new),
          menuViewModelProvider.overrideWith(
            () => _StaticMenuViewModel(const MenuState(isLoading: false)),
          ),
          saleCartProvider.overrideWith(
            () => _PrefilledCartNotifier(
              const SaleCartState(
                saleId: 'sale-1',
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

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SaleCartPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tax'), findsOneWidget);
      expect(find.text('\$0.15'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '5');
      await tester.pumpAndSettle();

      expect(find.text('Change (៛)'), findsOneWidget);
      expect(find.text('KHR 13,400'), findsOneWidget);
    },
  );

  testWidgets('KHQR waiting state shows cancel action and lifecycle guidance', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);

    const item = MenuItem(
      id: 'menu-1',
      name: 'Latte',
      categoryId: 'cat-1',
      price: 1.5,
    );

    final container = createTestContainer(
      overrides: [
        authSessionStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        saleRepositoryProvider.overrideWithValue(_MockSaleRepository()),
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(const MenuState(isLoading: false)),
        ),
        saleCartProvider.overrideWith(
          () => _PrefilledCartNotifier(
            const SaleCartState(
              saleId: 'sale-1',
              paymentMethod: 'qr',
              tenderCurrency: 'USD',
              khqrStatus: 'WAITING_FOR_PAYMENT',
              khqrAttemptId: 'intent-1',
              khqrMd5: 'md5-1',
              khqrQrPayload: 'KHQR:md5-1',
              lines: [CartLine(item: item, quantity: 1, selectedOptionIds: {})],
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SaleCartPage()),
      ),
    );

    await tester.pumpAndSettle();

    final openPopupButton = find.widgetWithText(FilledButton, 'View Code');
    expect(openPopupButton, findsOneWidget);
    await tester.ensureVisible(openPopupButton);
    await tester.tap(openPopupButton);
    await tester.pumpAndSettle();

    expect(find.text('Waiting for payment'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancel KHQR'), findsOneWidget);
    expect(
      find.text(
        'Customer can scan and pay now. Keep checking for confirmation.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Finalized sale shows receipt-aware success banner', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);

    final container = createTestContainer(
      overrides: [
        authSessionStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        saleRepositoryProvider.overrideWithValue(_MockSaleRepository()),
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(const MenuState(isLoading: false)),
        ),
        saleCartProvider.overrideWith(
          () => _PrefilledCartNotifier(
            SaleCartState(
              lastFinalizedSaleId: 'sale-1',
              lastFinalizedOrderId: 'order-1',
              lastReceiptId: 'receipt-1',
              lastReceipt: SaleImmediateReceiptDto(
                receiptId: 'receipt-1',
                saleId: 'sale-1',
                statusDisplay: 'ISSUED',
                issuedAt: DateTime(2026, 3, 7),
              ),
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SaleCartPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale finalized successfully.'), findsOneWidget);
    expect(find.text('Order #: order-1'), findsOneWidget);
    expect(find.text('Receipt #: receipt-1'), findsOneWidget);
    expect(find.text('Receipt status: ISSUED'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Receipt'), findsOneWidget);
  });

  testWidgets('Checkout error banner uses deterministic reason-code message', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);

    const item = MenuItem(
      id: 'menu-1',
      name: 'Latte',
      categoryId: 'cat-1',
      price: 1.5,
    );

    final container = createTestContainer(
      overrides: [
        authSessionStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        saleRepositoryProvider.overrideWithValue(_MockSaleRepository()),
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(const MenuState(isLoading: false)),
        ),
        saleCartProvider.overrideWith(
          () => _PrefilledCartNotifier(
            const SaleCartState(
              saleId: 'sale-1',
              lines: [CartLine(item: item, quantity: 1, selectedOptionIds: {})],
              checkoutErrorCode: SaleCheckoutReasonCodes.offlineUnreachable,
              checkoutErrorMessage: 'Raw backend text should not leak.',
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SaleCartPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('This action requires online connectivity.'),
      findsOneWidget,
    );
    expect(find.text('Raw backend text should not leak.'), findsNothing);
  });
}
