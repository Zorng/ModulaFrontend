import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/sale/domain/models/sale_resolved_discount.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_payload_builder.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_pricing.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';

void main() {
  test('SaleCartPricingCalculator applies item and branch discounts', () {
    final pricing = SaleCartPricingCalculator.calculate(
      lines: const [
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
      branchPolicy: const BranchPolicy(
        saleVatEnabled: true,
        saleVatRatePercent: 10,
        saleFxRateKhrPerUsd: 4000,
        saleAllowPayLater: true,
      ),
      resolvedDiscounts: SaleResolvedDiscountSet(
        branchId: 'branch-1',
        occurredAt: DateTime.utc(2026, 3, 22, 9),
        rules: const [
          SaleResolvedDiscountRule(
            ruleId: 'item-10',
            percentage: 10,
            scope: 'ITEM',
            itemIds: <String>['menu-1'],
            stackingPolicy: 'MULTIPLICATIVE',
          ),
          SaleResolvedDiscountRule(
            ruleId: 'branch-5',
            percentage: 5,
            scope: 'BRANCH_WIDE',
            itemIds: <String>[],
            stackingPolicy: 'MULTIPLICATIVE',
          ),
        ],
      ),
    );

    expect(pricing.preDiscountSubtotalUsd, 20);
    expect(pricing.itemDiscountUsd, moreOrLessEquals(2));
    expect(pricing.branchWideDiscountUsd, moreOrLessEquals(0.9));
    expect(pricing.discountUsd, moreOrLessEquals(2.9));
    expect(pricing.subtotalUsd, moreOrLessEquals(17.1));
    expect(pricing.taxUsd, moreOrLessEquals(1.71));
    expect(pricing.grandTotalUsd, moreOrLessEquals(18.81));
    expect(
      pricing.pricingForIndex(0).discountedUnitPriceUsd,
      moreOrLessEquals(9),
    );
    expect(pricing.pricingForIndex(0).lineTotalUsd, moreOrLessEquals(18));
  });

  test('SaleCartPayloadBuilder embeds discount snapshot metadata', () {
    const line = CartLine(
      item: MenuItem(
        id: 'menu-1',
        name: 'Latte',
        categoryId: 'cat-1',
        price: 10,
      ),
      quantity: 2,
      selectedOptionIds: {},
    );

    final cartPricing = SaleCartPricingCalculator.calculate(
      lines: const [line],
      groupLookup: const {},
      branchPolicy: const BranchPolicy(
        saleVatEnabled: false,
        saleFxRateKhrPerUsd: 4000,
        saleAllowPayLater: true,
      ),
      resolvedDiscounts: SaleResolvedDiscountSet(
        branchId: 'branch-1',
        occurredAt: DateTime.utc(2026, 3, 22, 9),
        rules: const [
          SaleResolvedDiscountRule(
            ruleId: 'item-10',
            percentage: 10,
            scope: 'ITEM',
            itemIds: <String>['menu-1'],
            stackingPolicy: 'MULTIPLICATIVE',
          ),
        ],
      ),
    );

    final payload = SaleCartPayloadBuilder.fromLine(
      line,
      pricing: cartPricing.pricingForIndex(0),
      cartPricing: cartPricing,
    );
    final snapshot = payload.pricingSnapshot!.toJson();

    expect(payload.unitPriceUsd, moreOrLessEquals(9));
    expect(payload.lineTotalUsdExact, moreOrLessEquals(18));
    expect(snapshot['lineBaseAmountUsd'], 20.0);
    expect(snapshot['itemDiscountUsd'], moreOrLessEquals(2));
    expect(snapshot['discountResolutionBranchId'], 'branch-1');
    expect(snapshot['appliedItemDiscounts'], [
      {'ruleId': 'item-10', 'percentage': 10.0, 'scope': 'ITEM'},
    ]);
    expect(
      snapshot['cartDiscountSnapshot'],
      containsPair('discountUsd', moreOrLessEquals(2)),
    );
  });
}
