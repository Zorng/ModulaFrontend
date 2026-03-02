import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  test('fetchStockItems uses /items path with contract query params', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/items'),
        data: {
          'success': true,
          'data': [
            {
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
          ],
        },
      ),
    );

    final api = InventoryApi(dio);
    final rows = await api.fetchStockItems(
      status: 'active',
      categoryId: 'cat-1',
      search: 'milk',
      limit: 25,
      offset: 0,
    );

    verify(
      () => dio.get<Map<String, dynamic>>(
        '/v0/inventory/items',
        queryParameters: {
          'status': 'active',
          'search': 'milk',
          'categoryId': 'cat-1',
          'limit': 25,
          'offset': 0,
        },
      ),
    ).called(1);
    expect(rows, hasLength(1));
    expect(rows.first.id, 'item-1');
  });

  test('fetchStockItems normalizes unknown status to all', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/items'),
        data: {'success': true, 'data': const []},
      ),
    );

    final api = InventoryApi(dio);
    await api.fetchStockItems(status: 'invalid-status');

    verify(
      () => dio.get<Map<String, dynamic>>(
        '/v0/inventory/items',
        queryParameters: {'status': 'all'},
      ),
    ).called(1);
  });
}
