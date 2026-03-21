import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/inventory/data/inventory_api_envelope.dart';

void main() {
  test('unwrapPaginatedDataList parses paginated inventory envelope', () {
    final result = InventoryApiEnvelope.unwrapPaginatedDataList({
      'success': true,
      'data': {
        'items': [
          {'id': 'item-1', 'name': 'Milk'},
          {'id': 'item-2', 'name': 'Sugar'},
        ],
        'limit': 10,
        'offset': 20,
        'total': 37,
        'hasMore': true,
      },
    });

    expect(result.items, hasLength(2));
    expect(result.items.first['id'], 'item-1');
    expect(result.limit, 10);
    expect(result.offset, 20);
    expect(result.total, 37);
    expect(result.hasMore, isTrue);
    expect(result.currentPage, 3);
    expect(result.totalPages, 4);
  });

  test('unwrapPaginatedDataList handles empty paginated envelope', () {
    final result = InventoryApiEnvelope.unwrapPaginatedDataList({
      'success': true,
      'data': {
        'items': [],
        'limit': 50,
        'offset': 0,
        'total': 0,
        'hasMore': false,
      },
    });

    expect(result.items, isEmpty);
    expect(result.limit, 50);
    expect(result.offset, 0);
    expect(result.total, 0);
    expect(result.hasMore, isFalse);
  });

  test('unwrapPaginatedDataList falls back safely for raw list payloads', () {
    final result = InventoryApiEnvelope.unwrapPaginatedDataList({
      'success': true,
      'data': [
        {'id': 'entry-1'},
      ],
    });

    expect(result.items, hasLength(1));
    expect(result.limit, 1);
    expect(result.offset, 0);
    expect(result.total, 1);
    expect(result.hasMore, isFalse);
  });

  test(
    'unwrapPaginatedDataList throws ApiClientException on failure envelope',
    () {
      expect(
        () => InventoryApiEnvelope.unwrapPaginatedDataList({
          'success': false,
          'error': 'Forbidden',
          'code': 'FORBIDDEN',
        }),
        throwsA(
          isA<ApiClientException>()
              .having((e) => e.message, 'message', 'Forbidden')
              .having((e) => e.code, 'code', 'FORBIDDEN'),
        ),
      );
    },
  );
}
