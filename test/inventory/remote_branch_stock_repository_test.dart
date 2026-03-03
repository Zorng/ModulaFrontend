import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_aggregate_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/branch_stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/on_hand_record_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
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
          limit: 200,
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => const [
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
      );
      when(
        () => api.fetchAggregateStock(includeArchivedItems: true),
      ).thenAnswer(
        (_) async => const [
          StockAggregateItemDto(
            stockItemId: 'item-1',
            stockItemName: 'Whole Milk',
            baseUnit: 'ml',
            totalOnHandInBaseUnit: 5400,
            branchCount: 3,
          ),
        ],
      );

      final rows = await repository.fetchStockItems();

      verify(
        () => api.fetchAggregateStock(includeArchivedItems: true),
      ).called(1);
      expect(rows, hasLength(1));
      expect(rows.first.id, 'item-1');
      expect(rows.first.branchId, 'all');
      expect(rows.first.branchName, 'All Branches');
      expect(rows.first.onHand, 5400);
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
          limit: 200,
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => const [
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
      );
      when(
        () => api.fetchAggregateStock(includeArchivedItems: true),
      ).thenAnswer((_) async => const []);
      when(
        () => api.fetchBranchStockItems(includeArchivedItems: true),
      ).thenAnswer(
        (_) async => const [
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
      );

      final rows = await repository.fetchStockItems(branchId: 'branch-1');

      verify(
        () => api.fetchBranchStockItems(includeArchivedItems: true),
      ).called(1);
      expect(rows, hasLength(1));
      expect(rows.first.id, 'item-1');
      expect(rows.first.branchId, 'branch-1');
      expect(rows.first.onHand, 1200);
    },
  );

  test('fetchOnHand filters records by branchId when provided', () async {
    final api = _MockInventoryApi();
    final repository = RemoteBranchStockRepository(api);

    when(() => api.fetchOnHand(includeArchivedItems: true)).thenAnswer(
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

    expect(rows, hasLength(1));
    expect(rows.first.branchId, 'branch-1');
    expect(rows.first.stockItemId, 'item-1');
  });
}
