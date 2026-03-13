import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  test('fetchStockItemById uses /items/:id endpoint', () async {
    final dio = _MockDio();
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/items/item-1'),
        data: {
          'success': true,
          'data': {
            'id': 'item-1',
            'tenantId': 'tenant-1',
            'categoryId': 'cat-1',
            'name': 'Whole Milk',
            'baseUnit': 'ml',
            'lowStockThreshold': 1000,
            'status': 'ACTIVE',
            'createdAt': '2026-02-20T00:00:00.000Z',
            'updatedAt': '2026-02-21T00:00:00.000Z',
          },
        },
      ),
    );

    final api = InventoryApi(dio);
    final row = await api.fetchStockItemById('item-1');

    verify(
      () => dio.get<Map<String, dynamic>>('/v0/inventory/items/item-1'),
    ).called(1);
    expect(row.id, 'item-1');
    expect(row.name, 'Whole Milk');
  });

  test(
    'fetchStockItemById maps not-found response to ApiClientException',
    () async {
      final dio = _MockDio();
      when(() => dio.get<Map<String, dynamic>>(any())).thenThrow(
        DioError(
          requestOptions: RequestOptions(path: '/v0/inventory/items/item-404'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(
              path: '/v0/inventory/items/item-404',
            ),
            statusCode: 404,
            data: {
              'success': false,
              'error': 'Stock item not found',
              'code': 'INVENTORY_STOCK_ITEM_NOT_FOUND',
            },
          ),
          error: 'not-found',
          type: DioErrorType.badResponse,
        ),
      );

      final api = InventoryApi(dio);
      await expectLater(
        () => api.fetchStockItemById('item-404'),
        throwsA(
          isA<ApiClientException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.code, 'code', 'INVENTORY_STOCK_ITEM_NOT_FOUND'),
        ),
      );
    },
  );
}
