import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  test(
    'fetchBranchStockItems uses /stock/branch with includeArchivedItems query',
    () async {
      final dio = _MockDio();
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/inventory/stock/branch'),
          data: {
            'success': true,
            'data': {
              'items': [
                {
                  'stockItemId': 'item-1',
                  'stockItemName': 'Whole Milk',
                  'baseUnit': 'ml',
                  'onHandInBaseUnit': 1200,
                  'lowStockThreshold': 300,
                  'isLowStock': false,
                  'updatedAt': '2026-03-03T00:00:00.000Z',
                },
              ],
              'limit': 10,
              'offset': 0,
              'total': 1,
              'hasMore': false,
            },
          },
        ),
      );

      final api = InventoryApi(dio);
      final rows = await api.fetchBranchStockItems(
        branchId: 'branch-1',
        includeArchivedItems: false,
        limit: 10,
        offset: 0,
      );

      verify(
        () => dio.get<Map<String, dynamic>>(
          '/v0/inventory/stock/branch',
          queryParameters: {
            'branchId': 'branch-1',
            'includeArchivedItems': false,
            'limit': 10,
            'offset': 0,
          },
        ),
      ).called(1);
      expect(rows.items, hasLength(1));
      expect(rows.total, 1);
      expect(rows.items.first.stockItemId, 'item-1');
      expect(rows.items.first.onHand, 1200);
    },
  );

  test('fetchOnHand uses /stock/branch with explicit branchId query', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/stock/branch'),
        data: {
          'success': true,
          'data': {
            'items': [
              {
                'stockItemId': 'item-1',
                'stockItemName': 'Whole Milk',
                'baseUnit': 'ml',
                'onHandInBaseUnit': 1200,
                'lowStockThreshold': 300,
                'isLowStock': false,
                'updatedAt': '2026-03-03T00:00:00.000Z',
              },
            ],
            'limit': 200,
            'offset': 0,
            'total': 1,
            'hasMore': false,
          },
        },
      ),
    );

    final api = InventoryApi(dio);
    final rows = await api.fetchOnHand(branchId: 'branch-1');

    verify(
      () => dio.get<Map<String, dynamic>>(
        '/v0/inventory/stock/branch',
        queryParameters: {
          'branchId': 'branch-1',
          'includeArchivedItems': true,
          'limit': 200,
          'offset': 0,
        },
      ),
    ).called(1);
    expect(rows, hasLength(1));
    expect(rows.first.stockItemId, 'item-1');
    expect(rows.first.branchId, 'branch-1');
    expect(rows.first.onHand, 1200);
    expect(rows.first.minThreshold, 300);
  });

  test(
    'fetchAggregateStock uses /stock/aggregate with includeArchivedItems query',
    () async {
      final dio = _MockDio();
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/inventory/stock/aggregate'),
          data: {
            'success': true,
            'data': {
              'items': [
                {
                  'stockItemId': 'item-1',
                  'stockItemName': 'Whole Milk',
                  'baseUnit': 'ml',
                  'totalOnHandInBaseUnit': 5400,
                  'branchCount': 3,
                },
              ],
              'limit': 25,
              'offset': 0,
              'total': 1,
              'hasMore': false,
            },
          },
        ),
      );

      final api = InventoryApi(dio);
      final rows = await api.fetchAggregateStock(
        includeArchivedItems: false,
        limit: 25,
        offset: 0,
      );

      verify(
        () => dio.get<Map<String, dynamic>>(
          '/v0/inventory/stock/aggregate',
          queryParameters: {
            'includeArchivedItems': false,
            'limit': 25,
            'offset': 0,
          },
        ),
      ).called(1);
      expect(rows.items, hasLength(1));
      expect(rows.total, 1);
      expect(rows.items.first.stockItemId, 'item-1');
      expect(rows.items.first.totalOnHandInBaseUnit, 5400);
      expect(rows.items.first.branchCount, 3);
    },
  );

  test(
    'assignStockItemToBranch is quarantined under the new contract',
    () async {
      final dio = _MockDio();
      final api = InventoryApi(dio);

      await expectLater(
        api.assignStockItemToBranch(
          stockItemId: 'item-1',
          branchId: 'branch-1',
          minThreshold: 120,
        ),
        throwsA(isA<UnsupportedError>()),
      );

      verifyNever(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    },
  );

  test(
    'fetchBranchStockItems throws ApiClientException on failure envelope',
    () async {
      final dio = _MockDio();
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/inventory/stock/branch'),
          data: {
            'success': false,
            'error': 'Inventory item is inactive.',
            'reasonCode': 'INVENTORY_STOCK_ITEM_INACTIVE',
          },
        ),
      );

      final api = InventoryApi(dio);

      await expectLater(
        () => api.fetchBranchStockItems(
          branchId: 'branch-1',
          limit: 10,
          offset: 0,
        ),
        throwsA(
          isA<ApiClientException>().having(
            (e) => e.code,
            'code',
            'INVENTORY_STOCK_ITEM_INACTIVE',
          ),
        ),
      );
    },
  );
}
