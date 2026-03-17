import 'package:equatable/equatable.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';

class StockInventoryState extends Equatable {
  const StockInventoryState({
    this.isLoading = false,
    this.isStockItemsPageLoading = false,
    this.isLoadingMoreStockItems = false,
    this.isAccumulatingStockItems = false,
    this.isBatchesLoading = false,
    this.isLoadingMoreBatches = false,
    this.inventoryItems = const [],
    this.stockItems = const [],
    this.selectedInventoryBranchId = 'all',
    this.stockItemsPageSize = 10,
    this.stockItemsCurrentPage = 1,
    this.stockItemsOffset = 0,
    this.stockItemsTotal = 0,
    this.stockItemsStatus = 'all',
    this.stockItemsSearch = '',
    this.stockItemsCategoryId = '',
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
  final bool isStockItemsPageLoading;
  final bool isLoadingMoreStockItems;
  final bool isAccumulatingStockItems;
  final bool isBatchesLoading;
  final bool isLoadingMoreBatches;
  final List<StockItem> inventoryItems;
  final List<StockItem> stockItems;
  final String selectedInventoryBranchId;
  final int stockItemsPageSize;
  final int stockItemsCurrentPage;
  final int stockItemsOffset;
  final int stockItemsTotal;
  final String stockItemsStatus;
  final String stockItemsSearch;
  final String stockItemsCategoryId;
  final List<StockBatch> batches;
  final int restockBatchLimit;
  final int restockBatchOffset;
  final bool hasMoreRestockBatches;
  final String restockBatchStatus;
  final String restockBatchStockItemId;
  final String restockBatchBranchId;
  final String? error;
  final InventoryErrorCode? errorCode;

  bool get hasPreviousStockItemsPage =>
      !isAccumulatingStockItems && stockItemsCurrentPage > 1;

  int get stockItemsTotalPages => stockItemsTotal <= 0
      ? 1
      : ((stockItemsTotal + stockItemsPageSize - 1) ~/ stockItemsPageSize);

  bool get hasNextStockItemsPage =>
      stockItemsCurrentPage < stockItemsTotalPages;

  int get stockItemsVisibleRangeStart => stockItems.isEmpty
      ? 0
      : (isAccumulatingStockItems ? 1 : stockItemsOffset + 1);

  int get stockItemsVisibleRangeEnd {
    if (stockItems.isEmpty) return 0;
    final rawEnd = isAccumulatingStockItems
        ? stockItems.length
        : stockItemsOffset + stockItems.length;
    return stockItemsTotal > 0 ? rawEnd.clamp(0, stockItemsTotal) : rawEnd;
  }

  StockInventoryState copyWith({
    bool? isLoading,
    bool? isStockItemsPageLoading,
    bool? isLoadingMoreStockItems,
    bool? isAccumulatingStockItems,
    bool? isBatchesLoading,
    bool? isLoadingMoreBatches,
    List<StockItem>? inventoryItems,
    List<StockItem>? stockItems,
    String? selectedInventoryBranchId,
    int? stockItemsPageSize,
    int? stockItemsCurrentPage,
    int? stockItemsOffset,
    int? stockItemsTotal,
    String? stockItemsStatus,
    String? stockItemsSearch,
    String? stockItemsCategoryId,
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
      isStockItemsPageLoading:
          isStockItemsPageLoading ?? this.isStockItemsPageLoading,
      isLoadingMoreStockItems:
          isLoadingMoreStockItems ?? this.isLoadingMoreStockItems,
      isAccumulatingStockItems:
          isAccumulatingStockItems ?? this.isAccumulatingStockItems,
      isBatchesLoading: isBatchesLoading ?? this.isBatchesLoading,
      isLoadingMoreBatches: isLoadingMoreBatches ?? this.isLoadingMoreBatches,
      inventoryItems: inventoryItems ?? this.inventoryItems,
      stockItems: stockItems ?? this.stockItems,
      selectedInventoryBranchId:
          selectedInventoryBranchId ?? this.selectedInventoryBranchId,
      stockItemsPageSize: stockItemsPageSize ?? this.stockItemsPageSize,
      stockItemsCurrentPage:
          stockItemsCurrentPage ?? this.stockItemsCurrentPage,
      stockItemsOffset: stockItemsOffset ?? this.stockItemsOffset,
      stockItemsTotal: stockItemsTotal ?? this.stockItemsTotal,
      stockItemsStatus: stockItemsStatus ?? this.stockItemsStatus,
      stockItemsSearch: stockItemsSearch ?? this.stockItemsSearch,
      stockItemsCategoryId: stockItemsCategoryId ?? this.stockItemsCategoryId,
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
    isStockItemsPageLoading,
    isLoadingMoreStockItems,
    isAccumulatingStockItems,
    isBatchesLoading,
    isLoadingMoreBatches,
    inventoryItems,
    stockItems,
    selectedInventoryBranchId,
    stockItemsPageSize,
    stockItemsCurrentPage,
    stockItemsOffset,
    stockItemsTotal,
    stockItemsStatus,
    stockItemsSearch,
    stockItemsCategoryId,
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
