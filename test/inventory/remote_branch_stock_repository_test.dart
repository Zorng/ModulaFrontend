import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_aggregate_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/branch_stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/on_hand_record_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/data/inventory_paginated_result.dart';
import 'package:modular_pos/features/inventory/data/remote_branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_status.dart';

class _MockInventoryApi extends Mock implements InventoryApi {}

void main() {
  test(
    'fetchStockItems uses aggregate endpoint when branchId is not provided',
    () async {
      final api = _MockInventoryApi();
      final repository = RemoteBranchStockRepository(api);

      when(
        () => api.fetchStockItems(
          status: 'all',
          search: any(named: 'search'),
          categoryId: any(named: 'categoryId'),
          limit: 1000,
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => const InventoryPaginatedResult(
          items: [
            StockItemDto(
              id: 'item-1',
              tenantId: 'tenant-1',
              categoryId: 'cat-1',
              name: 'Whole Milk',
              baseUnit: 'ml',
              imageUrl: null,
              lowStockThreshold: 300,
              status: InventoryStatus.active,
              createdAt: '2026-03-03T00:00:00.000Z',
              updatedAt: '2026-03-03T00:00:00.000Z',
            ),
          ],
          limit: 200,
          offset: 0,
          total: 1,
          hasMore: false,
        ),
      );
      when(
        () => api.fetchAggregateStock(
          includeArchivedItems: true,
          limit: 50,
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => const InventoryPaginatedResult(
          items: [
            StockAggregateItemDto(
              stockItemId: 'item-1',
              stockItemName: 'Whole Milk',
              baseUnit: 'ml',
              totalOnHandInBaseUnit: 5400,
              branchCount: 3,
            ),
          ],
          limit: 50,
          offset: 0,
          total: 1,
          hasMore: false,
        ),
      );

      final rows = await repository.fetchStockItems();

      verify(
        () => api.fetchAggregateStock(
          includeArchivedItems: true,
          limit: 50,
          offset: 0,
        ),
      ).called(1);
      expect(rows.items, hasLength(1));
      expect(rows.total, 1);
      expect(rows.items.first.id, 'item-1');
      expect(rows.items.first.branchId, 'all');
      expect(rows.items.first.branchName, 'All Branches');
      expect(rows.items.first.onHand, 5400);
    },
  );

  test(
    'fetchStockItems maps stock/branch payload with master hydration',
    () async {
      final api = _MockInventoryApi();
      final repository = RemoteBranchStockRepository(api);

      when(
        () => api.fetchStockItems(
          status: 'all',
          search: any(named: 'search'),
          categoryId: any(named: 'categoryId'),
          limit: 1000,
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => const InventoryPaginatedResult(
          items: [
            StockItemDto(
              id: 'item-1',
              tenantId: 'tenant-1',
              categoryId: 'cat-1',
              name: 'Whole Milk',
              baseUnit: 'ml',
              imageUrl: null,
              lowStockThreshold: 300,
              status: InventoryStatus.active,
              createdAt: '2026-03-03T00:00:00.000Z',
              updatedAt: '2026-03-03T00:00:00.000Z',
            ),
          ],
          limit: 200,
          offset: 0,
          total: 1,
          hasMore: false,
        ),
      );
      when(
        () => api.fetchAggregateStock(
          includeArchivedItems: true,
          limit: 50,
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => const InventoryPaginatedResult(
          items: [],
          limit: 50,
          offset: 0,
          total: 0,
          hasMore: false,
        ),
      );
      when(
        () => api.fetchBranchStockItems(
          branchId: 'branch-1',
          includeArchivedItems: true,
          limit: 50,
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => const InventoryPaginatedResult(
          items: [
            BranchStockItemDto(
              stockItemId: 'item-1',
              stockItemName: 'Whole Milk',
              baseUnit: 'ml',
              branchId: 'branch-1',
              onHand: 1200,
              minThreshold: 300,
              isLowStock: false,
              updatedAt: '2026-03-03T00:00:00.000Z',
              stockItem: StockItemDto(
                id: 'item-1',
                tenantId: '',
                categoryId: null,
                name: 'Whole Milk',
                baseUnit: 'ml',
                imageUrl: null,
                lowStockThreshold: 300,
                status: InventoryStatus.active,
                createdAt: '',
                updatedAt: '',
              ),
            ),
          ],
          limit: 50,
          offset: 0,
          total: 1,
          hasMore: false,
        ),
      );

      final rows = await repository.fetchStockItems(branchId: 'branch-1');

      verify(
        () => api.fetchBranchStockItems(
          branchId: 'branch-1',
          includeArchivedItems: true,
          limit: 50,
          offset: 0,
        ),
      ).called(1);
      expect(rows.items, hasLength(1));
      expect(rows.items.first.id, 'item-1');
      expect(rows.items.first.branchId, 'branch-1');
      expect(rows.items.first.onHand, 1200);
    },
  );

  test(
    'fetchStockItems prefers branch assignment imageUrl when master stock item imageUrl is stale',
    () async {
      final api = _MockInventoryApi();
      final repository = RemoteBranchStockRepository(api);

      when(
        () => api.fetchStockItems(
          status: 'all',
          search: any(named: 'search'),
          categoryId: any(named: 'categoryId'),
          limit: 1000,
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => const InventoryPaginatedResult(
          items: [
            StockItemDto(
              id: 'item-1',
              tenantId: 'tenant-1',
              categoryId: 'cat-1',
              name: 'Whole Milk',
              baseUnit: 'ml',
              imageUrl: 'https://cdn.example.com/stale.jpg',
              lowStockThreshold: 300,
              status: InventoryStatus.active,
              createdAt: '2026-03-03T00:00:00.000Z',
              updatedAt: '2026-03-03T00:00:00.000Z',
            ),
          ],
          limit: 200,
          offset: 0,
          total: 1,
          hasMore: false,
        ),
      );
      when(
        () => api.fetchBranchStockItems(
          branchId: 'branch-1',
          includeArchivedItems: true,
          limit: 50,
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => const InventoryPaginatedResult(
          items: [
            BranchStockItemDto(
              stockItemId: 'item-1',
              stockItemName: 'Whole Milk',
              baseUnit: 'ml',
              branchId: 'branch-1',
              onHand: 1200,
              minThreshold: 300,
              isLowStock: false,
              updatedAt: '2026-03-03T00:00:00.000Z',
              stockItem: StockItemDto(
                id: 'item-1',
                tenantId: 'tenant-1',
                categoryId: 'cat-1',
                name: 'Whole Milk',
                baseUnit: 'ml',
                imageUrl: 'https://cdn.example.com/fresh.jpg',
                lowStockThreshold: 300,
                status: InventoryStatus.active,
                createdAt: '2026-03-03T00:00:00.000Z',
                updatedAt: '2026-03-03T00:00:00.000Z',
              ),
            ),
          ],
          limit: 50,
          offset: 0,
          total: 1,
          hasMore: false,
        ),
      );

      final rows = await repository.fetchStockItems(branchId: 'branch-1');

      expect(rows.items, hasLength(1));
      expect(rows.items.first.imageUrl, 'https://cdn.example.com/fresh.jpg');
    },
  );

  test('fetchOnHand filters records by branchId when provided', () async {
    final api = _MockInventoryApi();
    final repository = RemoteBranchStockRepository(api);

    when(
      () => api.fetchOnHand(branchId: 'branch-1', includeArchivedItems: true),
    ).thenAnswer(
      (_) async => const [
        OnHandRecordDto(
          stockItemId: 'item-1',
          branchId: 'branch-1',
          onHand: 1200,
          minThreshold: 300,
        ),
        OnHandRecordDto(
          stockItemId: 'item-2',
          branchId: 'branch-2',
          onHand: 400,
          minThreshold: 200,
        ),
      ],
    );

    final rows = await repository.fetchOnHand(branchId: 'branch-1');

    verify(
      () => api.fetchOnHand(branchId: 'branch-1', includeArchivedItems: true),
    ).called(1);
    expect(rows, hasLength(1));
    expect(rows.first.branchId, 'branch-1');
    expect(rows.first.stockItemId, 'item-1');
  });
}
