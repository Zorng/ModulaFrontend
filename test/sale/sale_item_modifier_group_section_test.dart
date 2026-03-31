import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/widgets/sale_item_modifier_group_section.dart';

void main() {
  testWidgets(
    'SaleItemModifierGroupSection enforces max selections for multiple groups',
    (tester) async {
      Set<String> selected = <String>{};

      const group = ModifierGroup(
        id: 'group-1',
        name: 'Toppings',
        selectionType: 'multiple',
        selectionMode: 'MULTI',
        pricingBehavior: 'none',
        minSelections: 0,
        maxSelections: 2,
        options: [
          ModifierOption(
            id: 'opt-1',
            name: 'Pearls',
            price: 0,
            priceDelta: 0,
            isPriceConfigured: true,
          ),
          ModifierOption(
            id: 'opt-2',
            name: 'Coconut Jelly',
            price: 0,
            priceDelta: 0,
            isPriceConfigured: true,
          ),
          ModifierOption(
            id: 'opt-3',
            name: 'Pudding',
            price: 0,
            priceDelta: 0,
            isPriceConfigured: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SaleItemModifierGroupSection(
                  group: group,
                  selectedOptionIds: selected,
                  onSelectionChanged: (nextSelection) {
                    setState(() {
                      selected = nextSelection;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pearls (Free)'));
      await tester.pumpAndSettle();
      expect(selected, {'opt-1'});

      await tester.tap(find.text('Coconut Jelly (Free)'));
      await tester.pumpAndSettle();
      expect(selected, {'opt-1', 'opt-2'});

      await tester.tap(find.text('Pudding (Free)'));
      await tester.pumpAndSettle();

      expect(selected, {'opt-1', 'opt-2'});
      expect(
        find.text('You can select up to 2 options for Toppings.'),
        findsOneWidget,
      );
    },
  );
}
