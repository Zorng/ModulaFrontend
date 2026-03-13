import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/sale/data/sale_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  group('SaleApi read lane', () {
    test('getReceiptBySaleId reads the canonical receipt endpoint', () async {
      final dio = _MockDio();
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/receipts/sales/sale-1'),
          data: {
            'success': true,
            'data': {
              'receiptId': 'RCP-1001',
              'saleId': 'sale-1',
              'receiptNumber': 'RCP-20260310-0001',
              'statusDisplay': 'NORMAL',
              'issuedAt': '2026-03-10T08:30:00.000Z',
              'saleSnapshot': {
                'paymentMethod': 'CASH',
                'grandTotalUsd': 4.5,
                'grandTotalKhr': 18000,
              },
              'lines': [
                {
                  'menuItemNameSnapshot': 'Iced Latte',
                  'quantity': 2,
                  'unitPrice': 2.25,
                  'lineTotalAmount': 4.5,
                },
              ],
            },
          },
        ),
      );

      final api = SaleApi(dio);
      final receipt = await api.getReceiptBySaleId('sale-1');

      expect(receipt.saleId, 'sale-1');
      expect(receipt.receiptId, 'RCP-1001');
      expect(receipt.receiptNumber, 'RCP-20260310-0001');
      expect(receipt.saleSnapshot.paymentMethod, 'CASH');
      expect(receipt.lines, hasLength(1));
      expect(receipt.lines.single.name, 'Iced Latte');
      verify(
        () => dio.get<Map<String, dynamic>>('/v0/receipts/sales/sale-1'),
      ).called(1);
    });
  });
}
