import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/on_hand_record.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final mockBranchStockRepositoryProvider = Provider<BranchStockRepository>((
  ref,
) {
  return MockBranchStockRepository();
});

class MockBranchStockRepository extends BranchStockRepository {
  MockBranchStockRepository();

  final List<StockItem> _items = <StockItem>[];
  final Map<String, _BranchAssignment> _assignments =
      <String, _BranchAssignment>{};

  @override
  Future<List<OnHandRecord>> fetchOnHand({String? branchId}) async {
    return _assignments.entries
        .where(
          (entry) =>
              branchId == null ||
              branchId.isEmpty ||
              entry.value.branchId == branchId,
        )
        .map(
          (entry) => OnHandRecord(
            stockItemId: entry.key,
            branchId: entry.value.branchId,
            onHand: entry.value.onHand,
            minThreshold: entry.value.minThreshold,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<StockItem>> fetchStockItems({String? branchId}) async {
    if (_items.isEmpty) return const <StockItem>[];

    final items = _items.map(_withAssignment);
    if (branchId == null || branchId.isEmpty) {
      return items.toList(growable: false);
    }

    return items
        .where((item) => item.branchId == branchId)
        .toList(growable: false);
  }

  @override
  Future<void> assignToBranch({
    required String stockItemId,
    required String branchId,
    required int minThreshold,
  }) async {
    _assignments[stockItemId] = _BranchAssignment(
      branchId: branchId,
      minThreshold: minThreshold,
      onHand: _assignments[stockItemId]?.onHand ?? 0,
    );
  }

  StockItem _withAssignment(StockItem item) {
    final assignment = _assignments[item.id];
    if (assignment == null) return item;
    return item.copyWith(
      branchId: assignment.branchId,
      minThreshold: assignment.minThreshold,
      onHand: assignment.onHand,
    );
  }
}

class _BranchAssignment {
  const _BranchAssignment({
    required this.branchId,
    required this.minThreshold,
    required this.onHand,
  });

  final String branchId;
  final int minThreshold;
  final int onHand;
}
