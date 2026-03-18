import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/mock_branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/data/inventory_paginated_result.dart';
import 'package:modular_pos/features/inventory/data/remote_branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart'
    show useMockInventoryRepositoryProvider;
import 'package:modular_pos/features/inventory/domain/models/on_hand_record.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final branchStockRepositoryProvider = Provider<BranchStockRepository>((ref) {
  final useMock = ref.watch(useMockInventoryRepositoryProvider);
  if (useMock) {
    return ref.watch(mockBranchStockRepositoryProvider);
  }
  return ref.watch(remoteBranchStockRepositoryProvider);
});

abstract class BranchStockRepository {
  const BranchStockRepository();

  Future<List<OnHandRecord>> fetchOnHand({
    String? branchId,
    String status = 'all',
  });

  Future<InventoryPaginatedResult<StockItem>> fetchStockItems({
    String? branchId,
    String status = 'all',
    int pageSize = 50,
    int offset = 0,
  });

  Future<void> assignToBranch({
    required String stockItemId,
    required String branchId,
    required int minThreshold,
  });
}
