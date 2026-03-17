import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/sync/sync_freshness.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/menu/menu_page.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

import '../test_utils/pump_app.dart';

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

void main() {
  testWidgets(
    'MenuPage keeps cached items visible and shows passive freshness banner',
    (tester) async {
      await pumpApp(
        tester,
        const MenuPage(),
        overrides: [
          menuViewModelProvider.overrideWith(
            () => _StaticMenuViewModel(
              const MenuState(
                isLoading: false,
                filteredItems: [
                  MenuItem(
                    id: 'item-1',
                    name: 'Latte',
                    categoryId: 'cat-1',
                    price: 2.5,
                  ),
                ],
                allItems: [
                  MenuItem(
                    id: 'item-1',
                    name: 'Latte',
                    categoryId: 'cat-1',
                    price: 2.5,
                  ),
                ],
                categories: [MenuCategory(id: 'cat-1', name: 'Coffee')],
                error: 'offline',
                errorCode: 'OFFLINE_UNREACHABLE',
              ),
            ),
          ),
          branchWorkspaceSyncFreshnessProvider.overrideWith(
            (ref) async => const SyncWorkspaceFreshness(
              kind: SyncWorkspaceFreshnessKind.staleUsable,
              message: 'Offline: showing last synced workspace data.',
            ),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Offline: showing last synced workspace data.'),
        findsOneWidget,
      );
      expect(find.text('Latte'), findsOneWidget);
      expect(find.text('Failed to load menu'), findsNothing);
    },
  );
}
