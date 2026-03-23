import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_pricing.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SaleCartContent shows discount summary and discounted line', (
    tester,
  ) async {
    final usdController = TextEditingController();
    final khrController = TextEditingController();
    addTearDown(usdController.dispose);
    addTearDown(khrController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaleCartContent(
            items: const [
              CartLine(
                item: MenuItem(
                  id: 'menu-1',
                  name: 'Latte',
                  categoryId: 'cat-1',
                  price: 10,
                ),
                quantity: 2,
                selectedOptionIds: {},
              ),
            ],
            groupLookup: const {},
            linePricings: const [
              SaleCartLinePricing(
                menuItemId: 'menu-1',
                quantity: 2,
                baseUnitPriceUsd: 10,
                addonUnitTotalUsd: 0,
                preDiscountUnitPriceUsd: 10,
                preDiscountLineTotalUsd: 20,
                itemDiscountUsd: 2,
                discountedUnitPriceUsd: 9,
                lineTotalUsd: 18,
                appliedItemRules: [],
              ),
            ],
            onIncrement: (_, __) {},
            onDecrement: (_, __) {},
            paymentMethod: 'cash',
            tenderCurrency: 'USD',
            onPaymentMethodChanged: (_) {},
            onTenderCurrencyChanged: (_) {},
            usdController: usdController,
            khrController: khrController,
            subtotal: 20,
            discountUsd: 2.9,
            taxUsd: 1.71,
            showTaxBreakdown: true,
            grandTotalUsd: 18.81,
            grandTotalKhr: 75240,
            fxRate: 4000,
            readOnly: false,
            onAmountsChanged: () {},
            khqrStatus: SaleKhqrUiStates.readyToGenerate,
            khqrErrorCode: null,
            khqrReceiverConfigured: true,
          ),
        ),
      ),
    );

    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('-\$2.90'), findsOneWidget);
    expect(find.text('Auto discount applied'), findsOneWidget);
    expect(find.text('\$18.00'), findsOneWidget);
  });
}
