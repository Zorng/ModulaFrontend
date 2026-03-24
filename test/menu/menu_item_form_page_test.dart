import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_state.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item_detail.dart';
import 'package:modular_pos/features/menu/domain/models/menu_modifier_option_effect.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/menu_item_form_page.dart';
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
    String? status,
    MenuReadLane readLane = MenuReadLane.management,
  }) async {}

  @override
  Future<void> loadItemComposition(String menuItemId) async {}

  @override
  Future<MenuItemDetail> loadMenuItemDetail(
    String menuItemId, {
    int retries = 2,
    Duration retryDelay = const Duration(milliseconds: 200),
  }) async {
    return _state.detailByItemId[menuItemId]!;
  }
}

class _StaticStockInventoryController extends StockInventoryController {
  _StaticStockInventoryController(this._state);

  final StockInventoryState _state;

  @override
  StockInventoryState build() => _state;

  @override
  Future<void> loadStockItems({String status = 'all'}) async {}
}

void main() {
  testWidgets(
    'MenuItemFormPage renders base composition and item-scoped modifier effects from explicit state',
    (tester) async {
      const item = MenuItem(
        id: 'item-1',
        name: 'Latte',
        categoryId: 'cat-1',
        price: 2.5,
        basePrice: 2.5,
        modifierGroupIds: ['group-1'],
        branchIds: ['branch-1'],
        visibleBranchIds: ['branch-1'],
      );
      const modifierGroup = ModifierGroup(
        id: 'group-1',
        name: 'Milk',
        selectionType: 'single',
        pricingBehavior: 'addon',
        options: [
          ModifierOption(
            id: 'opt-1',
            groupId: 'group-1',
            name: 'Oat Milk',
            price: 0.5,
            priceDelta: 0.5,
          ),
        ],
      );

      await pumpApp(
        tester,
        const MenuItemFormPage(initialItem: item),
        overrides: [
          menuViewModelProvider.overrideWith(
            () => _StaticMenuViewModel(
              const MenuState(
                isLoading: false,
                allItems: [item],
                filteredItems: [item],
                categories: [MenuCategory(id: 'cat-1', name: 'Coffee')],
                modifierGroups: [modifierGroup],
                branches: [MenuBranch(id: 'branch-1', name: 'Main')],
                compositionLoadedByItem: {'item-1': true},
                compositionByItem: {
                  'item-1': [
                    MenuComponent(
                      stockItemId: 'stock-1',
                      quantityInBaseUnit: 250,
                      trackingMode: 'TRACKED',
                    ),
                  ],
                },
                baseCompositionByItemId: {
                  'item-1': [
                    MenuComponent(
                      stockItemId: 'stock-1',
                      quantityInBaseUnit: 250,
                      trackingMode: 'TRACKED',
                    ),
                  ],
                },
                modifierOptionEffectsByItemId: {
                  'item-1': [
                    MenuModifierOptionEffect(
                      modifierOptionId: 'opt-1',
                      components: [
                        ModifierDelta(
                          stockItemId: 'stock-2',
                          quantityDeltaInBaseUnit: 50,
                          trackingMode: 'TRACKED',
                        ),
                      ],
                    ),
                  ],
                },
              ),
            ),
          ),
          stockInventoryControllerProvider.overrideWith(
            () => _StaticStockInventoryController(
              const StockInventoryState(
                stockItems: [
                  StockItem(
                    id: 'stock-1',
                    name: 'Espresso',
                    baseUnit: 'ml',
                    pieceSize: 1,
                    branchId: '',
                    branchName: '',
                    onHand: 0,
                    minThreshold: 0,
                    isActive: true,
                  ),
                  StockItem(
                    id: 'stock-2',
                    name: 'Oat Milk',
                    baseUnit: 'ml',
                    pieceSize: 1,
                    branchId: '',
                    branchName: '',
                    onHand: 0,
                    minThreshold: 0,
                    isActive: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Composition'), findsOneWidget);
      expect(find.text('Espresso (ml)'), findsOneWidget);
      expect(find.text('Quantity: 250'), findsOneWidget);
      expect(find.text('Modifier option effects'), findsOneWidget);
      expect(find.text('Oat Milk'), findsAtLeastNWidgets(2));
      expect(find.text('Group: Milk'), findsOneWidget);
      expect(find.text('Delta: +50'), findsOneWidget);
    },
  );

  testWidgets(
    'MenuItemFormPage create mode shows gated helper text for composition and modifier effects',
    (tester) async {
      await pumpApp(
        tester,
        const MenuItemFormPage(),
        overrides: [
          menuViewModelProvider.overrideWith(
            () => _StaticMenuViewModel(
              const MenuState(
                isLoading: false,
                categories: [MenuCategory(id: 'cat-1', name: 'Coffee')],
                branches: [MenuBranch(id: 'branch-1', name: 'Main')],
              ),
            ),
          ),
          stockInventoryControllerProvider.overrideWith(
            () => _StaticStockInventoryController(const StockInventoryState()),
          ),
        ],
      );

      await tester.pump();

      expect(
        find.text(
          'Save the item first, then open it again to configure base components.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Save the item first, then open it again to configure item-scoped modifier effects.',
        ),
        findsOneWidget,
      );
    },
  );
}
