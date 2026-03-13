import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_sale_dto.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';

void main() {
  test('CashSessionSaleDto parses session sale row fields', () {
    final dto = CashSessionSaleDto.fromJson({
      'saleId': 'sale-1',
      'status': 'FINALIZED',
      'paymentMethod': 'CASH',
      'saleType': 'TAKEAWAY',
      'finalizedAt': '2026-03-09T09:10:00.000Z',
      'totalItems': 3,
      'grandTotalUsd': 7.5,
      'grandTotalKhr': 30750,
      'cashierAccountId': 'cashier-1',
      'cashierName': 'John Smith',
      'voidedAt': null,
    });

    expect(dto.saleId, 'sale-1');
    expect(dto.status, CashSessionSaleStatuses.finalized);
    expect(dto.paymentMethod, 'CASH');
    expect(dto.saleType, 'TAKEAWAY');
    expect(dto.totalItems, 3);
    expect(dto.grandTotalUsd, 7.5);
    expect(dto.grandTotalKhr, 30750);
    expect(dto.cashierName, 'John Smith');
    expect(dto.voidedAt, isNull);
  });

  test('CashSessionSaleDto normalizes sale status and maps to domain', () {
    final sale = CashSessionSaleDto.fromJson({
      'saleId': 'sale-2',
      'status': ' void_pending ',
      'paymentMethod': 'KHQR',
      'saleType': 'DINE_IN',
      'finalizedAt': '2026-03-09T10:00:00.000Z',
      'totalItems': 2,
      'grandTotalUsd': 12,
      'grandTotalKhr': 49200,
      'cashierAccountId': 'cashier-2',
      'cashierName': 'Jane Doe',
      'voidedAt': null,
    }).toDomain();

    expect(sale.status, CashSessionSaleStatuses.voidPending);
    expect(sale.paymentMethod, 'KHQR');
    expect(sale.saleType, 'DINE_IN');
    expect(sale.cashierName, 'Jane Doe');
    expect(sale.finalizedAt, isNotNull);
  });
}
