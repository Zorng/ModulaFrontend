import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  test(
    'fetchJournal uses /journal endpoint with contract query params',
    () async {
      final dio = _MockDio();
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/inventory/journal'),
          data: {
            'success': true,
            'data': [
              {
                'id': 'je-1',
                'tenantId': 'tenant-1',
                'branchId': 'branch-1',
                'stockItemId': 'item-1',
                'direction': 'OUT',
                'quantityInBaseUnit': 250,
                'reasonCode': 'SALE_DEDUCTION',
                'sourceType': 'SALE_ORDER',
                'sourceId': 'sale-1',
                'idempotencyKey': 'idem-1',
                'occurredAt': '2026-02-20T00:00:00.000Z',
                'actorAccountId': 'acct-1',
                'note': 'Sale consumed',
                'createdAt': '2026-02-20T00:00:00.000Z',
              },
            ],
          },
        ),
      );

      final api = InventoryApi(dio);
      final rows = await api.fetchJournal(
        stockItemId: 'item-1',
        reasonCode: 'sale',
        limit: 100,
        offset: 20,
      );

      verify(
        () => dio.get<Map<String, dynamic>>(
          '/v0/inventory/journal',
          queryParameters: {
            'stockItemId': 'item-1',
            'reasonCode': 'SALE_DEDUCTION',
            'limit': 100,
            'offset': 20,
          },
        ),
      ).called(1);
      expect(rows, hasLength(1));
      expect(rows.first.id, 'je-1');
      expect(rows.first.delta, -250);
    },
  );

  test('fetchJournal normalizes unknown reasonCode to OTHER', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/journal'),
        data: {'success': true, 'data': const []},
      ),
    );

    final api = InventoryApi(dio);
    await api.fetchJournal(reasonCode: 'invalid-reason');

    verify(
      () => dio.get<Map<String, dynamic>>(
        '/v0/inventory/journal',
        queryParameters: {'reasonCode': 'OTHER', 'limit': 50, 'offset': 0},
      ),
    ).called(1);
  });

  test('fetchJournal normalizes reason aliases to contract enums', () async {
    final cases = <(String, String)>[
      ('receive', 'RESTOCK'),
      ('sale', 'SALE_DEDUCTION'),
      ('voided', 'VOID_REVERSAL'),
      ('remove', 'ADJUSTMENT'),
      ('reopen', 'OTHER'),
    ];

    for (final (inputReason, expectedReason) in cases) {
      final dio = _MockDio();
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/inventory/journal'),
          data: {'success': true, 'data': const []},
        ),
      );

      final api = InventoryApi(dio);
      await api.fetchJournal(reasonCode: inputReason);

      verify(
        () => dio.get<Map<String, dynamic>>(
          '/v0/inventory/journal',
          queryParameters: {
            'reasonCode': expectedReason,
            'limit': 50,
            'offset': 0,
          },
        ),
      ).called(1);
    }
  });

  test('receiveStock includes idempotency metadata', () async {
    final dio = _MockDio();
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/journal/receive'),
        data: {
          'success': true,
          'data': {
            'id': 'je-1',
            'branchId': 'branch-1',
            'stockItemId': 'item-1',
            'reasonCode': 'RESTOCK',
            'direction': 'IN',
            'quantityInBaseUnit': 100,
            'createdAt': '2026-03-03T00:00:00.000Z',
            'occurredAt': '2026-03-03T00:00:00.000Z',
          },
        },
      ),
    );

    final api = InventoryApi(dio);
    await api.receiveStock(
      branchId: 'branch-1',
      stockItemId: 'item-1',
      qty: 100,
      note: 'Receive',
      occurredAt: '2026-03-03T00:00:00.000Z',
    );

    verify(
      () => dio.post<Map<String, dynamic>>(
        '/v0/inventory/journal/receive',
        data: {
          'stockItemId': 'item-1',
          'qty': 100,
          'note': 'Receive',
          'occurredAt': '2026-03-03T00:00:00.000Z',
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
                  'inventory.journal.receive',
                )
                .having((r) => r.payload, 'payload', {
                  'stockItemId': 'item-1',
                  'qty': 100,
                  'note': 'Receive',
                  'occurredAt': '2026-03-03T00:00:00.000Z',
                }),
          ),
        ),
      ),
    ).called(1);
  });

  test('wasteStock includes idempotency metadata', () async {
    final dio = _MockDio();
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/journal/waste'),
        data: {
          'success': true,
          'data': {
            'id': 'je-2',
            'branchId': 'branch-1',
            'stockItemId': 'item-1',
            'reasonCode': 'ADJUSTMENT',
            'direction': 'OUT',
            'quantityInBaseUnit': 25,
            'createdAt': '2026-03-03T00:00:00.000Z',
            'occurredAt': '2026-03-03T00:00:00.000Z',
          },
        },
      ),
    );

    final api = InventoryApi(dio);
    await api.wasteStock(
      branchId: 'branch-1',
      stockItemId: 'item-1',
      qty: 25,
      note: 'Spoiled',
      occurredAt: '2026-03-03T00:00:00.000Z',
    );

    verify(
      () => dio.post<Map<String, dynamic>>(
        '/v0/inventory/journal/waste',
        data: {
          'stockItemId': 'item-1',
          'qty': 25,
          'note': 'Spoiled',
          'occurredAt': '2026-03-03T00:00:00.000Z',
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
                  'inventory.journal.waste',
                )
                .having((r) => r.payload, 'payload', {
                  'stockItemId': 'item-1',
                  'qty': 25,
                  'note': 'Spoiled',
                  'occurredAt': '2026-03-03T00:00:00.000Z',
                }),
          ),
        ),
      ),
    ).called(1);
  });

  test('correctStock includes idempotency metadata', () async {
    final dio = _MockDio();
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v0/inventory/journal/correct'),
        data: {
          'success': true,
          'data': {
            'id': 'je-3',
            'branchId': 'branch-1',
            'stockItemId': 'item-1',
            'reasonCode': 'ADJUSTMENT',
            'direction': 'IN',
            'quantityInBaseUnit': 15,
            'createdAt': '2026-03-03T00:00:00.000Z',
            'occurredAt': '2026-03-03T00:00:00.000Z',
          },
        },
      ),
    );

    final api = InventoryApi(dio);
    await api.correctStock(
      branchId: 'branch-1',
      stockItemId: 'item-1',
      delta: 15,
      note: 'Count correction',
      occurredAt: '2026-03-03T00:00:00.000Z',
    );

    verify(
      () => dio.post<Map<String, dynamic>>(
        '/v0/inventory/journal/correct',
        data: {
          'stockItemId': 'item-1',
          'delta': 15,
          'note': 'Count correction',
          'occurredAt': '2026-03-03T00:00:00.000Z',
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
                  'inventory.journal.correct',
                )
                .having((r) => r.payload, 'payload', {
                  'stockItemId': 'item-1',
                  'delta': 15,
                  'note': 'Count correction',
                  'occurredAt': '2026-03-03T00:00:00.000Z',
                }),
          ),
        ),
      ),
    ).called(1);
  });

  test('fetchLowStockAlerts does not send branch override query', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(
          path: '/v0/inventory/branch/alerts/low-stock',
        ),
        data: {'success': true, 'data': const []},
      ),
    );

    final api = InventoryApi(dio);
    await api.fetchLowStockAlerts(branchId: 'branch-1');

    verify(
      () => dio.get<Map<String, dynamic>>(
        '/v0/inventory/branch/alerts/low-stock',
        queryParameters: null,
      ),
    ).called(1);
  });
}
