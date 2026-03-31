import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
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

import '../inventory/inventory_test_fakes.dart';
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

class _RecordingMenuViewModel extends MenuViewModel {
  _RecordingMenuViewModel(this._state);

  final MenuState _state;
  int updateCalls = 0;
  int compositionUpsertCalls = 0;
  List<MenuComponent> lastCompositionPayload = const [];

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
    return state.detailByItemId[menuItemId]!;
  }

  @override
  Future<MenuItem> updateMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    updateCalls += 1;
    return item;
  }

  @override
  Future<void> upsertItemComposition({
    required String menuItemId,
    required List<MenuComponent> baseComponents,
  }) async {
    compositionUpsertCalls += 1;
    lastCompositionPayload = baseComponents;
  }
}

void main() {
  testWidgets(
    'MenuItemFormPage first edit open uses hydrated item baseline before composition-only save',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const partialItem = MenuItem(
        id: 'item-1',
        name: 'Latte',
        categoryId: 'cat-1',
        price: 2.5,
        basePrice: 2.5,
      );
      const hydratedItem = MenuItem(
        id: 'item-1',
        name: 'Latte',
        categoryId: 'cat-1',
        price: 2.5,
        basePrice: 2.5,
        branchIds: ['branch-1'],
        visibleBranchIds: ['branch-1'],
      );
      const detail = MenuItemDetail(
        item: hydratedItem,
        categoryName: 'Coffee',
        modifierGroups: [],
        baseComponents: [
          MenuComponent(
            stockItemId: 'stock-1',
            quantityInBaseUnit: 250,
            trackingMode: 'TRACKED',
          ),
        ],
        modifierOptionEffects: [],
      );
      final notifier = _RecordingMenuViewModel(
        const MenuState(
          isLoading: false,
          allItems: [partialItem],
          filteredItems: [partialItem],
          categories: [MenuCategory(id: 'cat-1', name: 'Coffee')],
          branches: [MenuBranch(id: 'branch-1', name: 'Main')],
          detailByItemId: {'item-1': detail},
          hydratedItems: {'item-1': hydratedItem},
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
        ),
      );

      await pumpApp(
        tester,
        const MenuItemFormPage(initialItem: partialItem),
        overrides: [
          menuViewModelProvider.overrideWith(() => notifier),
          stockItemRepositoryProvider.overrideWithValue(
            FakeStockItemRepository(const [
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
            ]),
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
                ],
              ),
            ),
          ),
          activeBranchContextIdProvider.overrideWithValue('branch-1'),
        ],
      );

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, '300');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(notifier.updateCalls, 0);
      expect(notifier.compositionUpsertCalls, 1);
      expect(notifier.lastCompositionPayload.first.quantityInBaseUnit, 300);
    },
  );

  testWidgets(
    'MenuItemFormPage renders base composition and item-scoped modifier effects from explicit state',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
                      priceDelta: 0.5,
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
          stockItemRepositoryProvider.overrideWithValue(
            FakeStockItemRepository(const [
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
            ]),
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
      await tester.pumpAndSettle();

      expect(find.text('Composition'), findsOneWidget);
      expect(find.text('Espresso (ml)'), findsOneWidget);
      expect(find.text('Quantity: 250'), findsOneWidget);
      expect(find.text('Modifier option pricing and effects'), findsOneWidget);
      await tester.tap(find.widgetWithText(ExpansionTile, 'Milk'));
      await tester.pumpAndSettle();
      expect(find.text('Oat Milk'), findsOneWidget);
      expect(find.text('Price delta: +\$0.50'), findsOneWidget);
      expect(find.text('Delta: +50'), findsOneWidget);
    },
  );

  testWidgets(
    'MenuItemFormPage resolves composition stock items beyond the first stock catalog page',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const item = MenuItem(
        id: 'item-1',
        name: 'Latte',
        categoryId: 'cat-1',
        price: 2.5,
        basePrice: 2.5,
      );
      const detail = MenuItemDetail(
        item: item,
        categoryName: 'Coffee',
        modifierGroups: [],
        baseComponents: [
          MenuComponent(
            stockItemId: 'stock-201',
            quantityInBaseUnit: 30,
            trackingMode: 'TRACKED',
          ),
        ],
        modifierOptionEffects: [],
      );
      final stockCatalog = List<StockItem>.generate(
        201,
        (index) => StockItem(
          id: 'stock-${index + 1}',
          name: index == 200 ? 'Reserve Matcha' : 'Stock ${index + 1}',
          baseUnit: 'g',
          pieceSize: 1,
          branchId: '',
          branchName: '',
          onHand: 0,
          minThreshold: 0,
          isActive: true,
        ),
        growable: false,
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
                detailByItemId: {'item-1': detail},
                compositionLoadedByItem: {'item-1': true},
                compositionByItem: {
                  'item-1': [
                    MenuComponent(
                      stockItemId: 'stock-201',
                      quantityInBaseUnit: 30,
                      trackingMode: 'TRACKED',
                    ),
                  ],
                },
                baseCompositionByItemId: {
                  'item-1': [
                    MenuComponent(
                      stockItemId: 'stock-201',
                      quantityInBaseUnit: 30,
                      trackingMode: 'TRACKED',
                    ),
                  ],
                },
              ),
            ),
          ),
          stockItemRepositoryProvider.overrideWithValue(
            FakeStockItemRepository(stockCatalog),
          ),
          stockInventoryControllerProvider.overrideWith(
            () => _StaticStockInventoryController(const StockInventoryState()),
          ),
        ],
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Reserve Matcha (g)'), findsOneWidget);
      expect(find.text('Unknown stock item'), findsNothing);
    },
  );

  testWidgets(
    'MenuItemFormPage create mode gates deferred composition sections until after create',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
          stockItemRepositoryProvider.overrideWithValue(
            FakeStockItemRepository(const []),
          ),
          stockInventoryControllerProvider.overrideWith(
            () => _StaticStockInventoryController(const StockInventoryState()),
          ),
        ],
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Base components become available after you save this item and reopen it.',
        ),
        findsOneWidget,
      );
      final compositionTitleBottom = tester
          .getBottomLeft(find.text('Composition'))
          .dy;
      final compositionMessageTop = tester
          .getTopLeft(
            find.text(
              'Base components become available after you save this item and reopen it.',
            ),
          )
          .dy;
      expect(compositionMessageTop - compositionTitleBottom, lessThan(4));
      expect(find.text('Modifier option pricing and effects'), findsNothing);
      expect(find.text('Add component'), findsNothing);
      expect(
        find.text(
          'Save the item first, then reopen it to configure base components for this menu item.',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Base components become available after the item is created.',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'No stock items available. Add stock items in Inventory before configuring composition.',
        ),
        findsNothing,
      );
    },
  );
}
