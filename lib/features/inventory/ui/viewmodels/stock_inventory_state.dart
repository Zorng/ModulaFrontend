import 'package:equatable/equatable.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';

class StockInventoryState extends Equatable {
  const StockInventoryState({
    this.isLoading = false,
    this.isInventoryPageLoading = false,
    this.isLoadingMoreInventoryItems = false,
    this.isAccumulatingInventoryItems = false,
    this.isStockItemsPageLoading = false,
    this.isLoadingMoreStockItems = false,
    this.isAccumulatingStockItems = false,
    this.isBatchesLoading = false,
    this.isLoadingMoreBatches = false,
    this.inventoryItems = const [],
    this.stockItems = const [],
    this.selectedInventoryBranchId = 'all',
    this.inventoryPageSize = 10,
    this.inventoryCurrentPage = 1,
    this.inventoryOffset = 0,
    this.inventoryTotal = 0,
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
  final bool isInventoryPageLoading;
  final bool isLoadingMoreInventoryItems;
  final bool isAccumulatingInventoryItems;
  final bool isStockItemsPageLoading;
  final bool isLoadingMoreStockItems;
  final bool isAccumulatingStockItems;
  final bool isBatchesLoading;
  final bool isLoadingMoreBatches;
  final List<StockItem> inventoryItems;
  final List<StockItem> stockItems;
  final String selectedInventoryBranchId;
  final int inventoryPageSize;
  final int inventoryCurrentPage;
  final int inventoryOffset;
  final int inventoryTotal;
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

  bool get hasPreviousInventoryPage =>
      !isAccumulatingInventoryItems && inventoryCurrentPage > 1;

  int get inventoryTotalPages => inventoryTotal <= 0
      ? 1
      : ((inventoryTotal + inventoryPageSize - 1) ~/ inventoryPageSize);

  bool get hasNextInventoryPage => inventoryCurrentPage < inventoryTotalPages;

  int get inventoryVisibleRangeStart => inventoryItems.isEmpty
      ? 0
      : (isAccumulatingInventoryItems ? 1 : inventoryOffset + 1);

  int get inventoryVisibleRangeEnd {
    if (inventoryItems.isEmpty) return 0;
    final rawEnd = isAccumulatingInventoryItems
        ? inventoryItems.length
        : inventoryOffset + inventoryItems.length;
    return inventoryTotal > 0
        ? rawEnd.clamp(0, inventoryTotal).toInt()
        : rawEnd;
  }

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
    return stockItemsTotal > 0
        ? rawEnd.clamp(0, stockItemsTotal).toInt()
        : rawEnd;
  }

  StockInventoryState copyWith({
    bool? isLoading,
    bool? isInventoryPageLoading,
    bool? isLoadingMoreInventoryItems,
    bool? isAccumulatingInventoryItems,
    bool? isStockItemsPageLoading,
    bool? isLoadingMoreStockItems,
    bool? isAccumulatingStockItems,
    bool? isBatchesLoading,
    bool? isLoadingMoreBatches,
    List<StockItem>? inventoryItems,
    List<StockItem>? stockItems,
    String? selectedInventoryBranchId,
    int? inventoryPageSize,
    int? inventoryCurrentPage,
    int? inventoryOffset,
    int? inventoryTotal,
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
      isInventoryPageLoading:
          isInventoryPageLoading ?? this.isInventoryPageLoading,
      isLoadingMoreInventoryItems:
          isLoadingMoreInventoryItems ?? this.isLoadingMoreInventoryItems,
      isAccumulatingInventoryItems:
          isAccumulatingInventoryItems ?? this.isAccumulatingInventoryItems,
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
      inventoryPageSize: inventoryPageSize ?? this.inventoryPageSize,
      inventoryCurrentPage: inventoryCurrentPage ?? this.inventoryCurrentPage,
      inventoryOffset: inventoryOffset ?? this.inventoryOffset,
      inventoryTotal: inventoryTotal ?? this.inventoryTotal,
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
    isInventoryPageLoading,
    isLoadingMoreInventoryItems,
    isAccumulatingInventoryItems,
    isStockItemsPageLoading,
    isLoadingMoreStockItems,
    isAccumulatingStockItems,
    isBatchesLoading,
    isLoadingMoreBatches,
    inventoryItems,
    stockItems,
    selectedInventoryBranchId,
    inventoryPageSize,
    inventoryCurrentPage,
    inventoryOffset,
    inventoryTotal,
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
