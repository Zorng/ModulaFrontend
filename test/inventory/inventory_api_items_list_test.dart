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

  test(
    'createStockItem posts contract payload with idempotency metadata',
    () async {
      final dio = _MockDio();
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/inventory/items'),
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
      await api.createStockItem({
        'name': 'Whole Milk',
        'baseUnit': 'ml',
        'categoryId': 'cat-1',
        'lowStockThreshold': 1000,
      });

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/v0/inventory/items',
          data: {
            'name': 'Whole Milk',
            'baseUnit': 'ml',
            'categoryId': 'cat-1',
            'lowStockThreshold': 1000,
          },
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having(
                    (r) => r.actionKey,
                    'actionKey',
                    'inventory.items.create',
                  )
                  .having((r) => r.payload, 'payload', {
                    'name': 'Whole Milk',
                    'baseUnit': 'ml',
                    'categoryId': 'cat-1',
                    'lowStockThreshold': 1000,
                  }),
            ),
          ),
        ),
      ).called(1);
    },
  );

  test('createStockItem uploads image first and then posts imageUrl', () async {
    final dio = _MockDio();
    when(
      () => dio.post<dynamic>(
        '/v0/media/images/upload',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v0/media/images/upload'),
        data: {
          'success': true,
          'data': {'imageUrl': 'https://cdn.example.com/stock-item.jpg'},
        },
      ),
    );
    when(
      () => dio.post<Map<String, dynamic>>(
        '/v0/inventory/items',
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/items'),
        data: {
          'success': true,
          'data': {
            'id': 'item-1',
            'tenantId': 'tenant-1',
            'categoryId': 'cat-1',
            'name': 'Whole Milk',
            'baseUnit': 'ml',
            'imageUrl': 'https://cdn.example.com/stock-item.jpg',
            'status': 'ACTIVE',
            'createdAt': '2026-02-20T00:00:00.000Z',
            'updatedAt': '2026-02-21T00:00:00.000Z',
          },
        },
      ),
    );

    final api = InventoryApi(dio);
    await api.createStockItem(
      {'name': 'Whole Milk', 'baseUnit': 'ml', 'categoryId': 'cat-1'},
      imageBytes: [1, 2, 3],
    );

    final uploadCaptured =
        verify(
              () => dio.post<dynamic>(
                '/v0/media/images/upload',
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as FormData;
    expect(
      uploadCaptured.fields.any(
        (entry) => entry.key == 'area' && entry.value == 'inventory',
      ),
      isTrue,
    );
    expect(uploadCaptured.files.single.key, 'image');

    verify(
      () => dio.post<Map<String, dynamic>>(
        '/v0/inventory/items',
        data: {
          'name': 'Whole Milk',
          'baseUnit': 'ml',
          'categoryId': 'cat-1',
          'imageUrl': 'https://cdn.example.com/stock-item.jpg',
        },
        options: any(named: 'options'),
      ),
    ).called(1);
  });

  test(
    'createStockItem maps duplicate-name errors to ApiClientException',
    () async {
      final dio = _MockDio();
      when(
        () => dio.post<Map<String, dynamic>>(
          '/v0/inventory/items',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioError(
          requestOptions: RequestOptions(path: '/v0/inventory/items'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/v0/inventory/items'),
            statusCode: 409,
            data: {
              'success': false,
              'error': 'Duplicate stock item name',
              'code': 'INVENTORY_STOCK_ITEM_DUPLICATE_NAME',
            },
          ),
          error: 'conflict',
          type: DioErrorType.badResponse,
        ),
      );

      final api = InventoryApi(dio);
      await expectLater(
        () => api.createStockItem({'name': 'Whole Milk', 'baseUnit': 'ml'}),
        throwsA(
          isA<ApiClientException>()
              .having(
                (e) => e.code,
                'code',
                'INVENTORY_STOCK_ITEM_DUPLICATE_NAME',
              )
              .having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    },
  );

  test(
    'updateStockItem patches /items/:id with idempotency metadata',
    () async {
      final dio = _MockDio();
      when(
        () => dio.patch<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/inventory/items/item-1'),
          data: {
            'success': true,
            'data': {
              'id': 'item-1',
              'tenantId': 'tenant-1',
              'categoryId': 'cat-1',
              'name': 'Whole Milk Updated',
              'baseUnit': 'ml',
              'lowStockThreshold': 1200,
              'status': 'ACTIVE',
              'createdAt': '2026-02-20T00:00:00.000Z',
              'updatedAt': '2026-02-21T00:00:00.000Z',
            },
          },
        ),
      );

      final api = InventoryApi(dio);
      await api.updateStockItem('item-1', {
        'name': 'Whole Milk Updated',
        'categoryId': 'cat-1',
        'lowStockThreshold': 1200,
      });

      verify(
        () => dio.patch<Map<String, dynamic>>(
          '/v0/inventory/items/item-1',
          data: {
            'name': 'Whole Milk Updated',
            'categoryId': 'cat-1',
            'lowStockThreshold': 1200,
          },
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having(
                    (r) => r.actionKey,
                    'actionKey',
                    'inventory.items.update',
                  )
                  .having((r) => r.payload, 'payload', {
                    'stockItemId': 'item-1',
                    'name': 'Whole Milk Updated',
                    'categoryId': 'cat-1',
                    'lowStockThreshold': 1200,
                  }),
            ),
          ),
        ),
      ).called(1);
    },
  );

  test('updateStockItem uploads image first and patches imageUrl', () async {
    final dio = _MockDio();
    when(
      () => dio.post<dynamic>(
        '/v0/media/images/upload',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v0/media/images/upload'),
        data: {
          'success': true,
          'data': {
            'imageUrl': 'https://cdn.example.com/stock-item-updated.jpg',
          },
        },
      ),
    );
    when(
      () => dio.patch<Map<String, dynamic>>(
        '/v0/inventory/items/item-1',
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/items/item-1'),
        data: {
          'success': true,
          'data': {
            'id': 'item-1',
            'tenantId': 'tenant-1',
            'categoryId': 'cat-1',
            'name': 'Whole Milk Updated',
            'baseUnit': 'ml',
            'imageUrl': 'https://cdn.example.com/stock-item-updated.jpg',
            'status': 'ACTIVE',
            'createdAt': '2026-02-20T00:00:00.000Z',
            'updatedAt': '2026-02-21T00:00:00.000Z',
          },
        },
      ),
    );

    final api = InventoryApi(dio);
    await api.updateStockItem(
      'item-1',
      {'name': 'Whole Milk Updated', 'categoryId': 'cat-1'},
      imageBytes: [1, 2, 3],
    );

    final uploadCaptured =
        verify(
              () => dio.post<dynamic>(
                '/v0/media/images/upload',
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as FormData;
    expect(
      uploadCaptured.fields.any(
        (entry) => entry.key == 'area' && entry.value == 'inventory',
      ),
      isTrue,
    );
    expect(uploadCaptured.files.single.key, 'image');

    verify(
      () => dio.patch<Map<String, dynamic>>(
        '/v0/inventory/items/item-1',
        data: {
          'name': 'Whole Milk Updated',
          'categoryId': 'cat-1',
          'imageUrl': 'https://cdn.example.com/stock-item-updated.jpg',
        },
        options: any(named: 'options'),
      ),
    ).called(1);
  });

  test(
    'createStockItem surfaces upload helper errors as ApiClientException',
    () async {
      final dio = _MockDio();
      when(
        () => dio.post<dynamic>(
          '/v0/media/images/upload',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioError(
          requestOptions: RequestOptions(path: '/v0/media/images/upload'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/v0/media/images/upload'),
            statusCode: 422,
            data: {
              'success': false,
              'error': 'Unsupported image format',
              'code': 'UPLOAD_INVALID_TYPE',
            },
          ),
          error: 'upload failed',
          type: DioErrorType.badResponse,
        ),
      );

      final api = InventoryApi(dio);
      await expectLater(
        () => api.createStockItem(
          {'name': 'Whole Milk', 'baseUnit': 'ml'},
          imageBytes: [1, 2, 3],
        ),
        throwsA(
          isA<ApiClientException>()
              .having((e) => e.code, 'code', 'UPLOAD_INVALID_TYPE')
              .having((e) => e.statusCode, 'statusCode', 422),
        ),
      );

      verifyNever(
        () => dio.post<Map<String, dynamic>>(
          '/v0/inventory/items',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    },
  );

  test(
    'updateStockItem maps immutable base-unit error to ApiClientException',
    () async {
      final dio = _MockDio();
      when(
        () => dio.patch<Map<String, dynamic>>(
          '/v0/inventory/items/item-1',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioError(
          requestOptions: RequestOptions(path: '/v0/inventory/items/item-1'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/v0/inventory/items/item-1'),
            statusCode: 409,
            data: {
              'success': false,
              'error': 'Base unit is immutable',
              'code': 'INVENTORY_BASE_UNIT_IMMUTABLE',
            },
          ),
          error: 'conflict',
          type: DioErrorType.badResponse,
        ),
      );

      final api = InventoryApi(dio);
      await expectLater(
        () => api.updateStockItem('item-1', {'name': 'Whole Milk Updated'}),
        throwsA(
          isA<ApiClientException>()
              .having((e) => e.code, 'code', 'INVENTORY_BASE_UNIT_IMMUTABLE')
              .having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    },
  );

  test(
    'archiveStockItem posts /items/:id/archive with idempotency metadata',
    () async {
      final dio = _MockDio();
      when(
        () => dio.post<void>(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(
            path: '/v0/inventory/items/item-1/archive',
          ),
        ),
      );

      final api = InventoryApi(dio);
      await api.archiveStockItem('item-1');

      verify(
        () => dio.post<void>(
          '/v0/inventory/items/item-1/archive',
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having(
                    (r) => r.actionKey,
                    'actionKey',
                    'inventory.items.archive',
                  )
                  .having((r) => r.payload, 'payload', {
                    'stockItemId': 'item-1',
                  }),
            ),
          ),
        ),
      ).called(1);
    },
  );

  test('archiveStockItem maps failure to ApiClientException', () async {
    final dio = _MockDio();
    when(
      () => dio.post<void>(
        '/v0/inventory/items/item-1/archive',
        options: any(named: 'options'),
      ),
    ).thenThrow(
      DioError(
        requestOptions: RequestOptions(
          path: '/v0/inventory/items/item-1/archive',
        ),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(
            path: '/v0/inventory/items/item-1/archive',
          ),
          statusCode: 409,
          data: {
            'success': false,
            'error': 'Item already archived',
            'code': 'INVENTORY_STOCK_ITEM_ALREADY_ARCHIVED',
          },
        ),
        error: 'conflict',
        type: DioErrorType.badResponse,
      ),
    );

    final api = InventoryApi(dio);
    await expectLater(
      () => api.archiveStockItem('item-1'),
      throwsA(
        isA<ApiClientException>()
            .having(
              (e) => e.code,
              'code',
              'INVENTORY_STOCK_ITEM_ALREADY_ARCHIVED',
            )
            .having((e) => e.statusCode, 'statusCode', 409),
      ),
    );
  });

  test(
    'restoreStockItem posts /items/:id/restore with idempotency metadata',
    () async {
      final dio = _MockDio();
      when(
        () => dio.post<void>(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(
            path: '/v0/inventory/items/item-1/restore',
          ),
        ),
      );

      final api = InventoryApi(dio);
      await api.restoreStockItem('item-1');

      verify(
        () => dio.post<void>(
          '/v0/inventory/items/item-1/restore',
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having(
                    (r) => r.actionKey,
                    'actionKey',
                    'inventory.items.restore',
                  )
                  .having((r) => r.payload, 'payload', {
                    'stockItemId': 'item-1',
                  }),
            ),
          ),
        ),
      ).called(1);
    },
  );

  test('restoreStockItem maps failure to ApiClientException', () async {
    final dio = _MockDio();
    when(
      () => dio.post<void>(
        '/v0/inventory/items/item-1/restore',
        options: any(named: 'options'),
      ),
    ).thenThrow(
      DioError(
        requestOptions: RequestOptions(
          path: '/v0/inventory/items/item-1/restore',
        ),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(
            path: '/v0/inventory/items/item-1/restore',
          ),
          statusCode: 409,
          data: {
            'success': false,
            'error': 'Item already active',
            'code': 'INVENTORY_STOCK_ITEM_ALREADY_ACTIVE',
          },
        ),
        error: 'conflict',
        type: DioErrorType.badResponse,
      ),
    );

    final api = InventoryApi(dio);
    await expectLater(
      () => api.restoreStockItem('item-1'),
      throwsA(
        isA<ApiClientException>()
            .having(
              (e) => e.code,
              'code',
              'INVENTORY_STOCK_ITEM_ALREADY_ACTIVE',
            )
            .having((e) => e.statusCode, 'statusCode', 409),
      ),
    );
  });
}
