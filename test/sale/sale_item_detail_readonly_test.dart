import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';

class _StaticMenuViewModel extends MenuViewModel {
  _StaticMenuViewModel({
    required this.stateValue,
    required this.item,
    required this.groups,
  });

  final MenuState stateValue;
  final MenuItem item;
  final List<ModifierGroup> groups;

  @override
  MenuState build() => stateValue;

  @override
  Future<void> loadMenu({
    String? branchId,
    String? status,
    MenuReadLane readLane = MenuReadLane.management,
  }) async {}

  @override
  Future<(MenuItem, List<ModifierGroup>)> loadItemWithModifiers(
    String menuItemId, {
    int retries = 2,
    Duration retryDelay = const Duration(milliseconds: 200),
  }) async {
    return (item, groups);
  }

  @override
  Future<ModifierGroup> updateModifierGroup(
    ModifierGroup group, {
    ModifierGroup? previous,
  }) async {
    return group;
  }
}

class _RepairingMenuViewModel extends MenuViewModel {
  _RepairingMenuViewModel({required this.item, required this.group});

  final MenuItem item;
  ModifierGroup group;
  int updateCalls = 0;

  @override
  MenuState build() => const MenuState(isLoading: false);

  @override
  Future<void> loadMenu({
    String? branchId,
    String? status,
    MenuReadLane readLane = MenuReadLane.management,
  }) async {}

  @override
  Future<(MenuItem, List<ModifierGroup>)> loadItemWithModifiers(
    String menuItemId, {
    int retries = 2,
    Duration retryDelay = const Duration(milliseconds: 200),
  }) async {
    return (item, [group]);
  }

  @override
  Future<ModifierGroup> updateModifierGroup(
    ModifierGroup nextGroup, {
    ModifierGroup? previous,
  }) async {
    updateCalls += 1;
    group = nextGroup;
    return nextGroup;
  }
}

void main() {
  testWidgets('SaleItemDetailPage disables Add Item when branch is frozen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const item = MenuItem(
      id: 'menu-1',
      name: 'Latte',
      categoryId: 'cat-1',
      price: 1.5,
      modifierGroupIds: ['group-1'],
    );

    const groups = [
      ModifierGroup(
        id: 'group-1',
        name: 'Toppings',
        selectionType: 'multiple',
        selectionMode: 'MULTI',
        pricingBehavior: 'addon',
        maxSelections: 99,
        options: [],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuViewModelProvider.overrideWith(
            () => _StaticMenuViewModel(
              stateValue: const MenuState(isLoading: false),
              item: item,
              groups: groups,
            ),
          ),
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
        child: const MaterialApp(home: SaleItemDetailPage(item: item)),
      ),
    );

    await tester.pumpAndSettle();

    final addButton = find.widgetWithText(FilledButton, 'Add to Cart');
    expect(addButton, findsOneWidget);
    expect(tester.widget<FilledButton>(addButton).onPressed, isNull);
    expect(find.textContaining('branch is frozen'), findsOneWidget);
  });

  testWidgets(
    'SaleItemDetailPage blocks add to cart when selected modifier price is not configured',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const item = MenuItem(
        id: 'menu-1',
        name: 'Latte',
        categoryId: 'cat-1',
        price: 1.5,
        modifierGroupIds: ['group-1'],
      );

      const groups = [
        ModifierGroup(
          id: 'group-1',
          name: 'Size',
          selectionType: 'single',
          pricingBehavior: 'none',
          defaultOptionId: 'opt-1',
          options: [
            ModifierOption(
              id: 'opt-1',
              name: 'Medium',
              priceDelta: 0,
              isPriceConfigured: false,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            menuViewModelProvider.overrideWith(
              () => _StaticMenuViewModel(
                stateValue: const MenuState(isLoading: false),
                item: item,
                groups: groups,
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
          child: const MaterialApp(home: SaleItemDetailPage(item: item)),
        ),
      );

      await tester.pumpAndSettle();

      final addButton = find.widgetWithText(FilledButton, 'Add to Cart');
      expect(addButton, findsOneWidget);
      expect(tester.widget<FilledButton>(addButton).onPressed, isNull);
      expect(find.text('Medium (Price not configured)'), findsOneWidget);
      expect(
        find.text(
          'One or more selected modifier options do not have item-level prices configured yet.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SaleItemDetailPage blocks add to cart when required multi selection is missing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const item = MenuItem(
        id: 'menu-1',
        name: 'Milk Tea',
        categoryId: 'cat-1',
        price: 2.0,
        modifierGroupIds: ['group-1'],
      );

      const groups = [
        ModifierGroup(
          id: 'group-1',
          name: 'Toppings',
          selectionType: 'multiple',
          selectionMode: 'MULTI',
          pricingBehavior: 'none',
          minSelections: 1,
          maxSelections: 2,
          isRequired: true,
          options: [
            ModifierOption(
              id: 'opt-1',
              name: 'Pearls',
              priceDelta: 0,
              isPriceConfigured: true,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            menuViewModelProvider.overrideWith(
              () => _StaticMenuViewModel(
                stateValue: const MenuState(isLoading: false),
                item: item,
                groups: groups,
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
          child: const MaterialApp(home: SaleItemDetailPage(item: item)),
        ),
      );

      await tester.pumpAndSettle();

      final addButton = find.widgetWithText(FilledButton, 'Add to Cart');
      expect(addButton, findsOneWidget);
      expect(tester.widget<FilledButton>(addButton).onPressed, isNull);
      expect(
        find.text('Select at least 1 option for Toppings.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SaleItemDetailPage repairs legacy multi groups that were limited to one option',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const item = MenuItem(
        id: 'menu-1',
        name: 'Milk Tea',
        categoryId: 'cat-1',
        price: 2.0,
        modifierGroupIds: ['group-1'],
      );

      final notifier = _RepairingMenuViewModel(
        item: item,
        group: const ModifierGroup(
          id: 'group-1',
          name: 'Toppings',
          selectionType: 'multiple',
          selectionMode: 'MULTI',
          pricingBehavior: 'none',
          minSelections: 0,
          maxSelections: 1,
          options: [
            ModifierOption(
              id: 'opt-1',
              name: 'Pearls',
              priceDelta: 0,
              isPriceConfigured: true,
            ),
            ModifierOption(
              id: 'opt-2',
              name: 'Coconut Jelly',
              priceDelta: 0,
              isPriceConfigured: true,
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            menuViewModelProvider.overrideWith(() => notifier),
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
          child: const MaterialApp(home: SaleItemDetailPage(item: item)),
        ),
      );

      await tester.pumpAndSettle();

      expect(notifier.updateCalls, 1);
      expect(notifier.group.maxSelections, 99);

      await tester.tap(find.text('Pearls (Free)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coconut Jelly (Free)'));
      await tester.pumpAndSettle();

      final tiles = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(tiles.elementAt(0).value, isTrue);
      expect(tiles.elementAt(1).value, isTrue);
      expect(
        find.text('You can select up to 1 option for Toppings.'),
        findsNothing,
      );
    },
  );
}
