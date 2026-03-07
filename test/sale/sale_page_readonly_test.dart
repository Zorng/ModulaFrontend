import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/ui/view/sale/sale_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/fakes/fake_auth_repository.dart';

class _StaticMenuViewModel extends MenuViewModel {
  _StaticMenuViewModel(this._state);

  final MenuState _state;

  @override
  MenuState build() => _state;

  @override
  Future<void> loadMenu({
    String? branchId,
    MenuReadLane readLane = MenuReadLane.management,
  }) async {
    // Intentionally no-op for widget tests.
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SalePage renders search even when session is required', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionStoreProvider.overrideWithValue(store),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          menuViewModelProvider.overrideWith(
            () => _StaticMenuViewModel(const MenuState(isLoading: false)),
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
              reasonMessage:
                  'Read-only: start a cash session to add items and checkout.',
            ),
          ),
        ],
        child: const MaterialApp(home: SalePage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Cash session is not open'), findsOneWidget);
    expect(
      find.text('Add items as normal. Open session to checkout.'),
      findsOneWidget,
    );
    expect(find.text('Search menu items'), findsOneWidget);
  });
}
