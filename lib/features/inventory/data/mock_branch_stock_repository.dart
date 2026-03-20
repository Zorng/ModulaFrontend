import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/data/inventory_paginated_result.dart';
import 'package:modular_pos/features/inventory/data/mock_inventory_store.dart';
import 'package:modular_pos/features/inventory/domain/models/on_hand_record.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final mockBranchStockRepositoryProvider = Provider<BranchStockRepository>((
  ref,
) {
  final store = ref.watch(mockInventoryStoreProvider);
  return MockBranchStockRepository(store);
});

class MockBranchStockRepository extends BranchStockRepository {
  MockBranchStockRepository(this._store);

  final MockInventoryStore _store;

  @override
  Future<List<OnHandRecord>> fetchOnHand({
    String? branchId,
    String status = 'all',
  }) async {
    final targetBranch =
        (branchId == null || branchId.isEmpty || branchId == 'all')
        ? null
        : branchId;
    if (targetBranch == null) {
      return const <OnHandRecord>[];
    }
    return _store.fetchOnHand(branchId: targetBranch, status: status);
  }

  @override
  Future<InventoryPaginatedResult<StockItem>> fetchStockItems({
    String? branchId,
    String status = 'all',
    String? search,
    String? categoryId,
    String stockLevel = 'all',
    int pageSize = 50,
    int offset = 0,
  }) async {
    final targetBranch =
        (branchId == null || branchId.isEmpty || branchId == 'all')
        ? null
        : branchId;
    return _store.fetchInventoryStockItems(
      branchId: targetBranch,
      status: status,
      search: search,
      categoryId: categoryId,
      stockLevel: stockLevel,
      pageSize: pageSize,
      offset: offset,
    );
  }

  @override
  Future<void> assignToBranch({
    required String stockItemId,
    required String branchId,
    required int minThreshold,
  }) async {
    throw UnsupportedError(
      'Branch assignment is not supported by the current inventory contract.',
    );
  }
}
