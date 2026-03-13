import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpKhqrContent(
    WidgetTester tester, {
    required String khqrStatus,
    String? khqrErrorCode,
    bool? khqrReceiverConfigured,
  }) async {
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
                  price: 2.5,
                ),
                quantity: 1,
                selectedOptionIds: {},
              ),
            ],
            groupLookup: const {},
            onIncrement: (_, __) {},
            onDecrement: (_, __) {},
            paymentMethod: 'qr',
            tenderCurrency: 'USD',
            onPaymentMethodChanged: (_) {},
            onTenderCurrencyChanged: (_) {},
            usdController: usdController,
            khrController: khrController,
            subtotal: 2.5,
            taxUsd: 0,
            showTaxBreakdown: false,
            grandTotalUsd: 2.5,
            grandTotalKhr: 10000,
            fxRate: 4000,
            readOnly: false,
            onAmountsChanged: () {},
            khqrStatus: khqrStatus,
            khqrErrorCode: khqrErrorCode,
            khqrReceiverConfigured: khqrReceiverConfigured,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'receiver missing shows unavailable callout and disabled action',
    (tester) async {
      await pumpKhqrContent(
        tester,
        khqrStatus: SaleKhqrUiStates.readyToGenerate,
        khqrReceiverConfigured: false,
      );

      expect(find.text('KHQR unavailable for this branch.'), findsOneWidget);
      expect(
        find.textContaining('configure the Bakong receiver'),
        findsOneWidget,
      );
    },
  );

  testWidgets('superseded state asks operator to regenerate', (tester) async {
    await pumpKhqrContent(tester, khqrStatus: SaleKhqrUiStates.superseded);

    expect(find.text('Cart changed. Generate a new KHQR.'), findsOneWidget);
    expect(find.textContaining('Generate a fresh KHQR'), findsOneWidget);
  });
}
