import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';

void main() {
  test(
    'SaleAccessGate allows add-to-cart but blocks checkout when no session',
    () {
      const gate = SaleAccessGate(
        branchId: 'branch-1',
        contextLoading: false,
        branchActive: true,
        branchFrozen: false,
        cashSessionOpen: false,
        canMutateCart: false,
        canCheckout: false,
        canPlacePayLater: false,
        reasonCode: SaleCheckoutReasonCodes.cashSessionRequired,
      );

      expect(gate.canCreateDraftSale, isTrue);
      expect(gate.canAddToCart, isTrue);
      expect(gate.canCheckout, isFalse);
      expect(gate.canMutateCart, isFalse);
      expect(gate.hasBlockingReason, isTrue);
      expect(gate.blockingMessage, isNotNull);
    },
  );

  test('SaleAccessGate allows mutations when session is open', () {
    const gate = SaleAccessGate(
      branchId: 'branch-1',
      contextLoading: false,
      branchActive: true,
      branchFrozen: false,
      cashSessionOpen: true,
      canMutateCart: true,
      canCheckout: true,
      canPlacePayLater: true,
    );

    expect(gate.canCreateDraftSale, isTrue);
    expect(gate.canAddToCart, isTrue);
    expect(gate.canCheckout, isTrue);
    expect(gate.canMutateCart, isTrue);
    expect(gate.blockingMessage, isNull);
  });

  test('SaleAccessGate allows add-to-cart while session status is loading', () {
    const gate = SaleAccessGate(
      branchId: 'branch-1',
      contextLoading: true,
      branchActive: true,
      branchFrozen: false,
      cashSessionOpen: true,
      canMutateCart: false,
      canCheckout: false,
      canPlacePayLater: false,
    );

    expect(gate.canMutateCart, isFalse);
    expect(gate.canAddToCart, isTrue);
  });
}
