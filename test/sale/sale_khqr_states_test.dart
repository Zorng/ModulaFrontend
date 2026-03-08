import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';

void main() {
  test('maps checkout KHQR states to foundation terminology', () {
    expect(
      SaleKhqrUiStates.toFoundationStatus('waiting_for_payment'),
      SaleKhqrUiStates.waitingForPayment,
    );
    expect(
      SaleKhqrUiStates.toFoundationStatus('PENDING_CONFIRMATION'),
      SaleKhqrUiStates.pendingConfirmation,
    );
    expect(
      SaleKhqrUiStates.toFoundationStatus('paid_confirmed'),
      SaleKhqrUiStates.paidConfirmed,
    );
    expect(
      SaleKhqrUiStates.toFoundationStatus('cancelled'),
      SaleKhqrUiStates.cancelled,
    );
    expect(
      SaleKhqrUiStates.toFoundationStatus('expired'),
      SaleKhqrUiStates.expired,
    );
    expect(
      SaleKhqrUiStates.toFoundationStatus('superseded'),
      SaleKhqrUiStates.superseded,
    );
    expect(
      SaleKhqrUiStates.toFoundationStatus(SaleKhqrUiStates.readyToGenerate),
      isNull,
    );
  });

  test('identifies active KHQR attempt states correctly', () {
    expect(saleKhqrIsActiveAttempt(SaleKhqrUiStates.waitingForPayment), isTrue);
    expect(
      saleKhqrIsActiveAttempt(SaleKhqrUiStates.pendingConfirmation),
      isTrue,
    );
    expect(saleKhqrIsActiveAttempt(SaleKhqrUiStates.paidConfirmed), isTrue);
    expect(saleKhqrIsActiveAttempt(SaleKhqrUiStates.cancelled), isFalse);
    expect(saleKhqrIsActiveAttempt(SaleKhqrUiStates.expired), isFalse);
    expect(saleKhqrIsActiveAttempt(SaleKhqrUiStates.superseded), isFalse);
    expect(
      saleKhqrIsActiveAttempt(SaleKhqrUiStates.readyToGenerate),
      isFalse,
    );
  });
}
