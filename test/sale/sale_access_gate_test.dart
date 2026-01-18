import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';

void main() {
  test('SaleAccessGate blocks mutations when no session', () {
    const gate = SaleAccessGate(
      branchId: 'branch-1',
      cashSessionOpen: false,
      cashSessionLoading: false,
    );

    expect(gate.canCreateDraftSale, isFalse);
    expect(gate.canAddToCart, isFalse);
    expect(gate.canCheckout, isFalse);
    expect(gate.canMutateCart, isFalse);
    expect(gate.blockingMessage, isNotNull);
  });

  test('SaleAccessGate allows mutations when session is open', () {
    const gate = SaleAccessGate(
      branchId: 'branch-1',
      cashSessionOpen: true,
      cashSessionLoading: false,
    );

    expect(gate.canCreateDraftSale, isTrue);
    expect(gate.canAddToCart, isTrue);
    expect(gate.canCheckout, isTrue);
    expect(gate.canMutateCart, isTrue);
    expect(gate.blockingMessage, isNull);
  });

  test('SaleAccessGate blocks mutations while session is loading', () {
    const gate = SaleAccessGate(
      branchId: 'branch-1',
      cashSessionOpen: true,
      cashSessionLoading: true,
    );

    expect(gate.canMutateCart, isFalse);
  });
}
