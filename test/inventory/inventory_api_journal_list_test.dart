import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
        branchId: 'branch-1',
        stockItemId: 'item-1',
        reasonCode: 'sale',
        limit: 100,
        offset: 20,
      );

      verify(
        () => dio.get<Map<String, dynamic>>(
          '/v0/inventory/journal',
          queryParameters: {
            'branchId': 'branch-1',
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
    await api.fetchJournal(
      branchId: 'branch-1',
      reasonCode: 'invalid-reason',
    );

    verify(
      () => dio.get<Map<String, dynamic>>(
        '/v0/inventory/journal',
        queryParameters: {
          'branchId': 'branch-1',
          'reasonCode': 'OTHER',
          'limit': 50,
          'offset': 0,
        },
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
      await api.fetchJournal(branchId: 'branch-1', reasonCode: inputReason);

      verify(
        () => dio.get<Map<String, dynamic>>(
          '/v0/inventory/journal',
          queryParameters: {
            'branchId': 'branch-1',
            'reasonCode': expectedReason,
            'limit': 50,
            'offset': 0,
          },
        ),
      ).called(1);
    }
  });

  test(
    'fetchTenantJournal uses /journal/all with optional branch filter',
    () async {
      final dio = _MockDio();
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v0/inventory/journal/all'),
          data: {'success': true, 'data': const []},
        ),
      );

      final api = InventoryApi(dio);
      await api.fetchTenantJournal(
        branchId: 'branch-1',
        reasonCode: 'sale',
        limit: 20,
        offset: 0,
      );

      verify(
        () => dio.get<Map<String, dynamic>>(
          '/v0/inventory/journal/all',
          queryParameters: {
            'branchId': 'branch-1',
            'reasonCode': 'SALE_DEDUCTION',
            'limit': 20,
            'offset': 0,
          },
        ),
      ).called(1);
    },
  );

  test('receiveStock is quarantined under the new contract', () async {
    final dio = _MockDio();
    final api = InventoryApi(dio);
    await expectLater(
      api.receiveStock(
        branchId: 'branch-1',
        stockItemId: 'item-1',
        qty: 100,
        note: 'Receive',
        occurredAt: '2026-03-03T00:00:00.000Z',
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
  });

  test('wasteStock is quarantined under the new contract', () async {
    final dio = _MockDio();
    final api = InventoryApi(dio);
    await expectLater(
      api.wasteStock(
        branchId: 'branch-1',
        stockItemId: 'item-1',
        qty: 25,
        note: 'Spoiled',
        occurredAt: '2026-03-03T00:00:00.000Z',
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
  });

  test('correctStock is quarantined under the new contract', () async {
    final dio = _MockDio();
    final api = InventoryApi(dio);
    await expectLater(
      api.correctStock(
        branchId: 'branch-1',
        stockItemId: 'item-1',
        delta: 15,
        note: 'Count correction',
        occurredAt: '2026-03-03T00:00:00.000Z',
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
