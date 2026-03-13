import 'package:equatable/equatable.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';

class StockInventoryState extends Equatable {
  const StockInventoryState({
    this.isLoading = false,
    this.isBatchesLoading = false,
    this.isLoadingMoreBatches = false,
    this.inventoryItems = const [],
    this.stockItems = const [],
    this.selectedInventoryBranchId = 'all',
    this.batches = const [],
    this.restockBatchLimit = 200,
    this.restockBatchOffset = 0,
    this.hasMoreRestockBatches = true,
    this.restockBatchStatus = 'active',
    this.restockBatchStockItemId = '',
    this.restockBatchBranchId = '',
    this.error,
    this.errorCode,
  });

  final bool isLoading;
  final bool isBatchesLoading;
  final bool isLoadingMoreBatches;
  final List<StockItem> inventoryItems;
  final List<StockItem> stockItems;
  final String selectedInventoryBranchId;
  final List<StockBatch> batches;
  final int restockBatchLimit;
  final int restockBatchOffset;
  final bool hasMoreRestockBatches;
  final String restockBatchStatus;
  final String restockBatchStockItemId;
  final String restockBatchBranchId;
  final String? error;
  final InventoryErrorCode? errorCode;

  StockInventoryState copyWith({
    bool? isLoading,
    bool? isBatchesLoading,
    bool? isLoadingMoreBatches,
    List<StockItem>? inventoryItems,
    List<StockItem>? stockItems,
    String? selectedInventoryBranchId,
    List<StockBatch>? batches,
    int? restockBatchLimit,
    int? restockBatchOffset,
    bool? hasMoreRestockBatches,
    String? restockBatchStatus,
    String? restockBatchStockItemId,
    String? restockBatchBranchId,
    String? error,
    InventoryErrorCode? errorCode,
  }) {
    return StockInventoryState(
      isLoading: isLoading ?? this.isLoading,
      isBatchesLoading: isBatchesLoading ?? this.isBatchesLoading,
      isLoadingMoreBatches: isLoadingMoreBatches ?? this.isLoadingMoreBatches,
      inventoryItems: inventoryItems ?? this.inventoryItems,
      stockItems: stockItems ?? this.stockItems,
      selectedInventoryBranchId:
          selectedInventoryBranchId ?? this.selectedInventoryBranchId,
      batches: batches ?? this.batches,
      restockBatchLimit: restockBatchLimit ?? this.restockBatchLimit,
      restockBatchOffset: restockBatchOffset ?? this.restockBatchOffset,
      hasMoreRestockBatches:
          hasMoreRestockBatches ?? this.hasMoreRestockBatches,
      restockBatchStatus: restockBatchStatus ?? this.restockBatchStatus,
      restockBatchStockItemId:
          restockBatchStockItemId ?? this.restockBatchStockItemId,
      restockBatchBranchId: restockBatchBranchId ?? this.restockBatchBranchId,
      error: error,
      errorCode: errorCode,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isBatchesLoading,
    isLoadingMoreBatches,
    inventoryItems,
    stockItems,
    selectedInventoryBranchId,
    batches,
    restockBatchLimit,
    restockBatchOffset,
    hasMoreRestockBatches,
    restockBatchStatus,
    restockBatchStockItemId,
    restockBatchBranchId,
    error,
    errorCode,
  ];
}
