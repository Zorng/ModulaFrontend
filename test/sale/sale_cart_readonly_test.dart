import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _StaticMenuViewModel extends MenuViewModel {
  _StaticMenuViewModel(this._state);

  final MenuState _state;

  @override
  MenuState build() => _state;

  @override
  Future<void> loadMenu({String? branchId}) async {}
}

class _PrefilledCartNotifier extends SaleCartNotifier {
  _PrefilledCartNotifier(this._initial);

  final SaleCartState _initial;

  @override
  SaleCartState build() => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Cart checkout becomes disabled when sale becomes read-only',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);

    final gateStateProvider = StateProvider<SaleAccessGate>(
      (ref) => const SaleAccessGate(
        branchId: 'branch-1',
        cashSessionOpen: true,
        cashSessionLoading: false,
      ),
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
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        saleRepositoryProvider.overrideWithValue(_MockSaleRepository()),
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(const MenuState(isLoading: false)),
        ),
        saleCartProvider.overrideWith(
          () => _PrefilledCartNotifier(
            const SaleCartState(
              saleId: 'sale-1',
              lines: [
                CartLine(
                  item: item,
                  quantity: 1,
                  selectedOptionIds: {},
                ),
              ],
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
      cashSessionOpen: false,
      cashSessionLoading: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Cash session required'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Cash session'), findsOneWidget);
    expect(tester.widget<FilledButton>(checkoutButton).onPressed, isNull);
  });
}
