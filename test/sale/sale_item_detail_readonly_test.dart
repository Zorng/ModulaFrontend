import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail_page.dart';
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
  Future<void> loadMenu({String? branchId}) async {}

  @override
  Future<(MenuItem, List<ModifierGroup>)> loadItemWithModifiers(
    String menuItemId, {
    int retries = 2,
    Duration retryDelay = const Duration(milliseconds: 200),
  }) async {
    return (item, groups);
  }
}

void main() {
  testWidgets('SaleItemDetailPage disables Add Item when blocked', (tester) async {
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
        pricingBehavior: 'addon',
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
              cashSessionOpen: false,
              cashSessionLoading: false,
            ),
          ),
        ],
        child: const MaterialApp(
          home: SaleItemDetailPage(item: item),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final addButton = find.widgetWithText(FilledButton, 'Add Item');
    expect(addButton, findsOneWidget);
    expect(tester.widget<FilledButton>(addButton).onPressed, isNull);
    expect(find.textContaining('Cash session required'), findsOneWidget);
  });
}
