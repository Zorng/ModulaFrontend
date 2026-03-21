import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/inventory/data/inventory_paginated_result.dart';

void main() {
  test('computes pagination metadata for a middle page', () {
    const result = InventoryPaginatedResult<String>(
      items: ['a', 'b', 'c'],
      limit: 10,
      offset: 20,
      total: 47,
      hasMore: true,
    );

    expect(result.currentPage, 3);
    expect(result.totalPages, 5);
    expect(result.hasPreviousPage, isTrue);
    expect(result.visibleRangeStart, 21);
    expect(result.visibleRangeEnd, 23);
  });

  test('handles an empty page safely', () {
    const result = InventoryPaginatedResult<String>(
      items: [],
      limit: 10,
      offset: 0,
      total: 0,
      hasMore: false,
    );

    expect(result.currentPage, 1);
    expect(result.totalPages, 0);
    expect(result.hasPreviousPage, isFalse);
    expect(result.visibleRangeStart, 0);
    expect(result.visibleRangeEnd, 0);
  });

  test('caps visible end range at total count', () {
    const result = InventoryPaginatedResult<String>(
      items: ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
      limit: 10,
      offset: 40,
      total: 45,
      hasMore: false,
    );

    expect(result.currentPage, 5);
    expect(result.totalPages, 5);
    expect(result.visibleRangeStart, 41);
    expect(result.visibleRangeEnd, 45);
  });
}
