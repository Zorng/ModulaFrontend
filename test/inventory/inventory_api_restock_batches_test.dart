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

  test('fetchRestockBatches uses contract path and query params', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/restock-batches'),
        data: {
          'success': true,
          'data': {
            'items': [
              {
                'id': 'batch-1',
                'tenantId': 'tenant-1',
                'branchId': 'branch-1',
                'stockItemId': 'item-1',
                'quantityInBaseUnit': 2400,
                'status': 'ACTIVE',
                'receivedAt': '2026-02-20T00:00:00.000Z',
                'expiryDate': '2026-03-20',
                'supplierName': 'Supplier X',
                'purchaseCostUsd': 15.75,
                'note': 'Morning restock',
                'createdByAccountId': 'acct-1',
                'createdAt': '2026-02-20T00:00:00.000Z',
                'updatedAt': '2026-02-20T00:00:00.000Z',
              },
            ],
            'limit': 50,
            'offset': 0,
            'total': 1,
            'hasMore': false,
          },
        },
      ),
    );

    final api = InventoryApi(dio);
    final rows = await api.fetchRestockBatches(
      status: 'active',
      stockItemId: 'item-1',
      limit: 50,
      offset: 0,
    );

    verify(
      () => dio.get<Map<String, dynamic>>(
        '/v0/inventory/restock-batches',
        queryParameters: {
          'status': 'active',
          'stockItemId': 'item-1',
          'limit': 50,
          'offset': 0,
        },
      ),
    ).called(1);
    expect(rows.items, hasLength(1));
    expect(rows.items.first.id, 'batch-1');
    expect(rows.items.first.quantityInBaseUnit, 2400);
    expect(rows.limit, 50);
    expect(rows.offset, 0);
    expect(rows.total, 1);
    expect(rows.hasMore, isFalse);
  });

  test('fetchRestockBatches normalizes unknown status to all', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/restock-batches'),
        data: {
          'success': true,
          'data': {
            'items': const [],
            'limit': 50,
            'offset': 0,
            'total': 0,
            'hasMore': false,
          },
        },
      ),
    );

    final api = InventoryApi(dio);
    await api.fetchRestockBatches(status: 'invalid-status');

    verify(
      () => dio.get<Map<String, dynamic>>(
        '/v0/inventory/restock-batches',
        queryParameters: {'status': 'all'},
      ),
    ).called(1);
  });

  test(
    'createRestockBatch posts contract payload with idempotency metadata',
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
          requestOptions: RequestOptions(path: '/v0/inventory/restock-batches'),
          data: {
            'success': true,
            'data': {
              'id': 'batch-1',
              'tenantId': 'tenant-1',
              'branchId': 'branch-1',
              'stockItemId': 'item-1',
              'quantityInBaseUnit': 2400,
              'status': 'ACTIVE',
              'receivedAt': '2026-02-20T00:00:00.000Z',
              'expiryDate': '2026-03-20',
              'supplierName': 'Supplier X',
              'purchaseCostUsd': 15.75,
              'note': 'Morning restock',
              'createdByAccountId': 'acct-1',
              'createdAt': '2026-02-20T00:00:00.000Z',
              'updatedAt': '2026-02-20T00:00:00.000Z',
              'journalEntry': {
                'id': 'je-1',
                'branchId': 'branch-1',
                'branchName': 'Main Branch',
                'stockItemId': 'item-1',
                'stockItemName': 'Whole Milk',
                'reasonCode': 'RESTOCK',
                'direction': 'IN',
                'quantityInBaseUnit': 2400,
                'note': 'Morning restock',
                'actorAccountId': 'acct-1',
                'createdAt': '2026-02-20T00:00:00.000Z',
                'occurredAt': '2026-02-20T00:00:00.000Z',
              },
            },
          },
        ),
      );

      final api = InventoryApi(dio);
      final result = await api.createRestockBatch(
        branchId: 'branch-1',
        stockItemId: 'item-1',
        quantityInBaseUnit: 2400,
        receivedAt: '2026-02-20T00:00:00.000Z',
        expiryDate: '2026-03-20',
        supplierName: 'Supplier X',
        purchaseCostUsd: 15.75,
        note: 'Morning restock',
      );

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/v0/inventory/restock-batches',
          data: {
            'branchId': 'branch-1',
            'stockItemId': 'item-1',
            'quantityInBaseUnit': 2400,
            'receivedAt': '2026-02-20T00:00:00.000Z',
            'expiryDate': '2026-03-20',
            'supplierName': 'Supplier X',
            'purchaseCostUsd': 15.75,
            'note': 'Morning restock',
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
                    'inventory.restockBatches.create',
                  )
                  .having((r) => r.payload, 'payload', {
                    'branchId': 'branch-1',
                    'stockItemId': 'item-1',
                    'quantityInBaseUnit': 2400,
                    'receivedAt': '2026-02-20T00:00:00.000Z',
                    'expiryDate': '2026-03-20',
                    'supplierName': 'Supplier X',
                    'purchaseCostUsd': 15.75,
                    'note': 'Morning restock',
                  }),
            ),
          ),
        ),
      ).called(1);
      expect(result, isNotNull);
      expect(result!.id, 'je-1');
      expect(result.reason, 'RESTOCK');
      expect(result.delta, 2400);
    },
  );

  test(
    'createRestockBatch maps contract errors to ApiClientException',
    () async {
      final dio = _MockDio();
      when(
        () => dio.post<Map<String, dynamic>>(
          '/v0/inventory/restock-batches',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioError(
          requestOptions: RequestOptions(path: '/v0/inventory/restock-batches'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(
              path: '/v0/inventory/restock-batches',
            ),
            statusCode: 422,
            data: {
              'success': false,
              'error': 'Quantity is invalid',
              'code': 'INVENTORY_QUANTITY_INVALID',
            },
          ),
          error: 'unprocessable',
          type: DioErrorType.badResponse,
        ),
      );

      final api = InventoryApi(dio);
      await expectLater(
        () => api.createRestockBatch(
          branchId: 'branch-1',
          stockItemId: 'item-1',
          quantityInBaseUnit: 0,
        ),
        throwsA(
          isA<ApiClientException>()
              .having((e) => e.code, 'code', 'INVENTORY_QUANTITY_INVALID')
              .having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    },
  );

  test(
    'updateRestockBatchMetadata patches contract payload with idempotency metadata',
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
          requestOptions: RequestOptions(
            path: '/v0/inventory/restock-batches/batch-1',
          ),
          data: {
            'success': true,
            'data': {
              'id': 'batch-1',
              'tenantId': 'tenant-1',
              'branchId': 'branch-1',
              'stockItemId': 'item-1',
              'quantityInBaseUnit': 2400,
              'status': 'ACTIVE',
              'receivedAt': '2026-02-20T00:00:00.000Z',
              'expiryDate': '2026-03-25',
              'supplierName': 'Supplier X',
              'purchaseCostUsd': 16.25,
              'note': 'Updated note',
              'createdByAccountId': 'acct-1',
              'createdAt': '2026-02-20T00:00:00.000Z',
              'updatedAt': '2026-02-21T00:00:00.000Z',
            },
          },
        ),
      );

      final api = InventoryApi(dio);
      final result = await api.updateRestockBatchMetadata(
        batchId: 'batch-1',
        branchId: 'branch-1',
        expiryDate: '2026-03-25',
        supplierName: 'Supplier X',
        purchaseCostUsd: 16.25,
        note: 'Updated note',
      );

      verify(
        () => dio.patch<Map<String, dynamic>>(
          '/v0/inventory/restock-batches/batch-1',
          data: {
            'branchId': 'branch-1',
            'expiryDate': '2026-03-25',
            'supplierName': 'Supplier X',
            'purchaseCostUsd': 16.25,
            'note': 'Updated note',
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
                    'inventory.restockBatches.updateMeta',
                  )
                  .having((r) => r.payload, 'payload', {
                    'batchId': 'batch-1',
                    'branchId': 'branch-1',
                    'expiryDate': '2026-03-25',
                    'supplierName': 'Supplier X',
                    'purchaseCostUsd': 16.25,
                    'note': 'Updated note',
                  }),
            ),
          ),
        ),
      ).called(1);
      expect(result.id, 'batch-1');
      expect(result.expiryDate, '2026-03-25');
    },
  );

  test(
    'updateRestockBatchMetadata maps archived errors to ApiClientException',
    () async {
      final dio = _MockDio();
      when(
        () => dio.patch<Map<String, dynamic>>(
          '/v0/inventory/restock-batches/batch-1',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioError(
          requestOptions: RequestOptions(
            path: '/v0/inventory/restock-batches/batch-1',
          ),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(
              path: '/v0/inventory/restock-batches/batch-1',
            ),
            statusCode: 409,
            data: {
              'success': false,
              'error': 'Batch already archived',
              'code': 'INVENTORY_RESTOCK_BATCH_ARCHIVED',
            },
          ),
          error: 'conflict',
          type: DioErrorType.badResponse,
        ),
      );

      final api = InventoryApi(dio);
      await expectLater(
        () => api.updateRestockBatchMetadata(
          batchId: 'batch-1',
          branchId: 'branch-1',
          note: 'Updated note',
        ),
        throwsA(
          isA<ApiClientException>()
              .having((e) => e.code, 'code', 'INVENTORY_RESTOCK_BATCH_ARCHIVED')
              .having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    },
  );

  test(
    'archiveRestockBatch posts archive endpoint with idempotency metadata',
    () async {
      final dio = _MockDio();
      when(
        () => dio.post<void>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(
            path: '/v0/inventory/restock-batches/batch-1/archive',
          ),
        ),
      );

      final api = InventoryApi(dio);
      await api.archiveRestockBatch(batchId: 'batch-1', branchId: 'branch-1');

      verify(
        () => dio.post<void>(
          '/v0/inventory/restock-batches/batch-1/archive',
          queryParameters: {'branchId': 'branch-1'},
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having(
                    (r) => r.actionKey,
                    'actionKey',
                    'inventory.restockBatches.archive',
                  )
                  .having((r) => r.payload, 'payload', {
                    'batchId': 'batch-1',
                    'branchId': 'branch-1',
                  }),
            ),
          ),
        ),
      ).called(1);
    },
  );

  test(
    'archiveRestockBatch maps archived errors to ApiClientException',
    () async {
      final dio = _MockDio();
      when(
        () => dio.post<void>(
          '/v0/inventory/restock-batches/batch-1/archive',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioError(
          requestOptions: RequestOptions(
            path: '/v0/inventory/restock-batches/batch-1/archive',
          ),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(
              path: '/v0/inventory/restock-batches/batch-1/archive',
            ),
            statusCode: 409,
            data: {
              'success': false,
              'error': 'Batch already archived',
              'code': 'INVENTORY_RESTOCK_BATCH_ARCHIVED',
            },
          ),
          error: 'conflict',
          type: DioErrorType.badResponse,
        ),
      );

      final api = InventoryApi(dio);
      await expectLater(
        () => api.archiveRestockBatch(batchId: 'batch-1', branchId: 'branch-1'),
        throwsA(
          isA<ApiClientException>()
              .having((e) => e.code, 'code', 'INVENTORY_RESTOCK_BATCH_ARCHIVED')
              .having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    },
  );

  test(
    'applyAdjustment posts /adjustments with idempotency metadata and returns resulting on-hand',
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
          requestOptions: RequestOptions(path: '/v0/inventory/adjustments'),
          data: {
            'success': true,
            'data': {
              'adjustment': {'resultingOnHandInBaseUnit': 1750},
            },
          },
        ),
      );

      final api = InventoryApi(dio);
      final resultingOnHand = await api.applyAdjustment(
        branchId: 'branch-1',
        stockItemId: 'item-1',
        style: 'delta',
        deltaInBaseUnit: -250,
        reasonCode: 'waste',
        note: 'Spilled',
      );

      verify(
        () => dio.post<Map<String, dynamic>>(
          '/v0/inventory/adjustments',
          data: {
            'branchId': 'branch-1',
            'stockItemId': 'item-1',
            'style': 'DELTA',
            'reasonCode': 'WASTE',
            'note': 'Spilled',
            'deltaInBaseUnit': -250,
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
                    'inventory.adjustments.apply',
                  )
                  .having((r) => r.payload, 'payload', {
                    'branchId': 'branch-1',
                    'stockItemId': 'item-1',
                    'style': 'DELTA',
                    'reasonCode': 'WASTE',
                    'note': 'Spilled',
                    'deltaInBaseUnit': -250,
                  }),
            ),
          ),
        ),
      ).called(1);
      expect(resultingOnHand, 1750);
    },
  );

  test(
    'applyAdjustment falls back to branchStockProjection onHand when summary field is absent',
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
          requestOptions: RequestOptions(path: '/v0/inventory/adjustments'),
          data: {
            'success': true,
            'data': {
              'branchStockProjection': {
                'id': 'branch-1:item-1',
                'tenantId': 'tenant-1',
                'branchId': 'branch-1',
                'stockItemId': 'item-1',
                'onHandInBaseUnit': 1800,
                'lastMovementAt': '2026-03-03T00:00:00.000Z',
                'updatedAt': '2026-03-03T00:00:00.000Z',
              },
            },
          },
        ),
      );

      final api = InventoryApi(dio);
      final resultingOnHand = await api.applyAdjustment(
        branchId: 'branch-1',
        stockItemId: 'item-1',
        style: 'SET_TO_COUNT',
        countedOnHandInBaseUnit: 1800,
        reasonCode: 'COUNT_CORRECTION',
      );

      expect(resultingOnHand, 1800);
    },
  );

  test(
    'applyAdjustment maps invalid adjustments to ApiClientException',
    () async {
      final dio = _MockDio();
      when(
        () => dio.post<Map<String, dynamic>>(
          '/v0/inventory/adjustments',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioError(
          requestOptions: RequestOptions(path: '/v0/inventory/adjustments'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/v0/inventory/adjustments'),
            statusCode: 422,
            data: {
              'success': false,
              'error': 'Invalid adjustment',
              'code': 'INVENTORY_ADJUSTMENT_INVALID',
            },
          ),
          error: 'invalid',
          type: DioErrorType.badResponse,
        ),
      );

      final api = InventoryApi(dio);
      await expectLater(
        () => api.applyAdjustment(
          branchId: 'branch-1',
          stockItemId: 'item-1',
          style: 'DELTA',
          deltaInBaseUnit: 0,
          reasonCode: 'COUNT_CORRECTION',
        ),
        throwsA(
          isA<ApiClientException>()
              .having((e) => e.code, 'code', 'INVENTORY_ADJUSTMENT_INVALID')
              .having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    },
  );
}
