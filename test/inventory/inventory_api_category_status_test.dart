import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  test('fetchCategories sends status filter query', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/categories'),
        data: {
          'success': true,
          'data': [
            {
              'id': 'cat-1',
              'tenantId': 'tenant-1',
              'name': 'Dairy',
              'status': 'ACTIVE',
              'createdAt': '2026-02-20T00:00:00.000Z',
              'updatedAt': '2026-02-21T00:00:00.000Z',
            },
          ],
        },
      ),
    );

    final api = InventoryApi(dio);
    final rows = await api.fetchCategories(status: 'active');

    verify(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: {'status': 'active'},
      ),
    ).called(1);
    expect(rows, hasLength(1));
    expect(rows.first.id, 'cat-1');
  });

  test('fetchCategories normalizes unknown status to all', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/categories'),
        data: {'success': true, 'data': const []},
      ),
    );

    final api = InventoryApi(dio);
    await api.fetchCategories(status: 'invalid-status');

    verify(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: {'status': 'all'},
      ),
    ).called(1);
  });

  test('createCategory includes idempotency request metadata', () async {
    final dio = _MockDio();
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/categories'),
        data: {
          'success': true,
          'data': {
            'id': 'cat-1',
            'tenantId': 'tenant-1',
            'name': 'Dairy',
            'status': 'ACTIVE',
            'createdAt': '2026-02-20T00:00:00.000Z',
            'updatedAt': '2026-02-21T00:00:00.000Z',
          },
        },
      ),
    );

    final api = InventoryApi(dio);
    await api.createCategory({'name': 'Dairy'});

    verify(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: {'name': 'Dairy'},
        options: any(
          named: 'options',
          that: isA<Options>().having(
            (o) => o.extra?[idempotencyRequestExtraKey],
            'idempotencyRequest',
            isA<IdempotencyRequest>()
                .having(
                  (r) => r.actionKey,
                  'actionKey',
                  'inventory.categories.create',
                )
                .having((r) => r.payload, 'payload', {'name': 'Dairy'}),
          ),
        ),
      ),
    ).called(1);
  });

  test(
    'createCategory maps duplicate-name error to ApiClientException',
    () async {
      final dio = _MockDio();
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioError(
          requestOptions: RequestOptions(path: '/v0/inventory/categories'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/v0/inventory/categories'),
            statusCode: 409,
            data: {
              'success': false,
              'error': 'Duplicate category name',
              'code': 'INVENTORY_STOCK_CATEGORY_DUPLICATE_NAME',
            },
          ),
          error: 'conflict',
          type: DioErrorType.badResponse,
        ),
      );

      final api = InventoryApi(dio);

      await expectLater(
        () => api.createCategory({'name': 'Dairy'}),
        throwsA(
          isA<ApiClientException>()
              .having(
                (e) => e.code,
                'code',
                'INVENTORY_STOCK_CATEGORY_DUPLICATE_NAME',
              )
              .having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    },
  );

  test('updateCategory includes idempotency request metadata', () async {
    final dio = _MockDio();
    when(
      () => dio.patch<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/categories/cat-1'),
        data: {
          'success': true,
          'data': {
            'id': 'cat-1',
            'tenantId': 'tenant-1',
            'name': 'Dairy & Cheese',
            'status': 'ACTIVE',
            'createdAt': '2026-02-20T00:00:00.000Z',
            'updatedAt': '2026-02-21T00:00:00.000Z',
          },
        },
      ),
    );

    final api = InventoryApi(dio);
    await api.updateCategory('cat-1', {'name': 'Dairy & Cheese'});

    verify(
      () => dio.patch<Map<String, dynamic>>(
        any(),
        data: {'name': 'Dairy & Cheese'},
        options: any(
          named: 'options',
          that: isA<Options>().having(
            (o) => o.extra?[idempotencyRequestExtraKey],
            'idempotencyRequest',
            isA<IdempotencyRequest>()
                .having(
                  (r) => r.actionKey,
                  'actionKey',
                  'inventory.categories.update',
                )
                .having((r) => r.payload, 'payload', {
                  'categoryId': 'cat-1',
                  'name': 'Dairy & Cheese',
                }),
          ),
        ),
      ),
    ).called(1);
  });

  test(
    'updateCategory maps duplicate-name error to ApiClientException',
    () async {
      final dio = _MockDio();
      when(
        () => dio.patch<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioError(
          requestOptions: RequestOptions(
            path: '/v0/inventory/categories/cat-1',
          ),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(
              path: '/v0/inventory/categories/cat-1',
            ),
            statusCode: 409,
            data: {
              'success': false,
              'error': 'Duplicate category name',
              'code': 'INVENTORY_STOCK_CATEGORY_DUPLICATE_NAME',
            },
          ),
          error: 'conflict',
          type: DioErrorType.badResponse,
        ),
      );

      final api = InventoryApi(dio);

      await expectLater(
        () => api.updateCategory('cat-1', {'name': 'Dairy'}),
        throwsA(
          isA<ApiClientException>()
              .having(
                (e) => e.code,
                'code',
                'INVENTORY_STOCK_CATEGORY_DUPLICATE_NAME',
              )
              .having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    },
  );

  test(
    'deleteCategory archives via contract endpoint with idempotency metadata',
    () async {
      final dio = _MockDio();
      when(
        () => dio.post<void>(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(
            path: '/v0/inventory/categories/cat-1/archive',
          ),
        ),
      );

      final api = InventoryApi(dio);
      await api.deleteCategory('cat-1');

      verify(
        () => dio.post<void>(
          '/v0/inventory/categories/cat-1/archive',
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having(
                    (r) => r.actionKey,
                    'actionKey',
                    'inventory.categories.archive',
                  )
                  .having((r) => r.payload, 'payload', {'categoryId': 'cat-1'}),
            ),
          ),
        ),
      ).called(1);
    },
  );

  test('deleteCategory maps archive errors to ApiClientException', () async {
    final dio = _MockDio();
    when(() => dio.post<void>(any(), options: any(named: 'options'))).thenThrow(
      DioError(
        requestOptions: RequestOptions(
          path: '/v0/inventory/categories/cat-1/archive',
        ),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(
            path: '/v0/inventory/categories/cat-1/archive',
          ),
          statusCode: 404,
          data: {
            'success': false,
            'error': 'Category not found',
            'code': 'INVENTORY_STOCK_CATEGORY_NOT_FOUND',
          },
        ),
        error: 'not-found',
        type: DioErrorType.badResponse,
      ),
    );

    final api = InventoryApi(dio);
    await expectLater(
      () => api.deleteCategory('cat-1'),
      throwsA(
        isA<ApiClientException>()
            .having((e) => e.code, 'code', 'INVENTORY_STOCK_CATEGORY_NOT_FOUND')
            .having((e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });
}
