import 'package:equatable/equatable.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_journal_date_filter.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';

const Object _inventoryJournalUnset = Object();

enum InventoryJournalScope { tenantWide, branch }

class InventoryJournalState extends Equatable {
  const InventoryJournalState({
    this.isLoading = false,
    this.isPageLoading = false,
    this.isAccumulatingPages = false,
    this.entries = const [],
    this.scope = InventoryJournalScope.tenantWide,
    this.selectedBranchId = 'all',
    this.selectedStockItemId = '',
    this.selectedReason,
    this.dateFilter = const InventoryJournalDateFilter(
      preset: InventoryJournalDatePreset.today,
    ),
    this.pageSize = 10,
    this.currentPage = 1,
    this.pageOffset = 0,
    this.hasNextPage = true,
    this.error,
    this.errorCode,
  });

  final bool isLoading;
  final bool isPageLoading;
  final bool isAccumulatingPages;
  final List<InventoryJournalEntry> entries;
  final InventoryJournalScope scope;
  final String selectedBranchId;
  final String selectedStockItemId;
  final InventoryJournalReason? selectedReason;
  final InventoryJournalDateFilter dateFilter;
  final int pageSize;
  final int currentPage;
  final int pageOffset;
  final bool hasNextPage;
  final String? error;
  final InventoryErrorCode? errorCode;

  bool get hasPreviousPage => !isAccumulatingPages && currentPage > 1;

  int get visibleRangeStart =>
      entries.isEmpty ? 0 : (isAccumulatingPages ? 1 : pageOffset + 1);

  int get visibleRangeEnd =>
      isAccumulatingPages ? entries.length : pageOffset + entries.length;

  InventoryJournalState copyWith({
    bool? isLoading,
    bool? isPageLoading,
    bool? isAccumulatingPages,
    List<InventoryJournalEntry>? entries,
    InventoryJournalScope? scope,
    String? selectedBranchId,
    String? selectedStockItemId,
    Object? selectedReason = _inventoryJournalUnset,
    InventoryJournalDateFilter? dateFilter,
    int? pageSize,
    int? currentPage,
    int? pageOffset,
    bool? hasNextPage,
    String? error,
    InventoryErrorCode? errorCode,
  }) {
    return InventoryJournalState(
      isLoading: isLoading ?? this.isLoading,
      isPageLoading: isPageLoading ?? this.isPageLoading,
      isAccumulatingPages: isAccumulatingPages ?? this.isAccumulatingPages,
      entries: entries ?? this.entries,
      scope: scope ?? this.scope,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      selectedStockItemId: selectedStockItemId ?? this.selectedStockItemId,
      selectedReason: identical(selectedReason, _inventoryJournalUnset)
          ? this.selectedReason
          : selectedReason as InventoryJournalReason?,
      dateFilter: dateFilter ?? this.dateFilter,
      pageSize: pageSize ?? this.pageSize,
      currentPage: currentPage ?? this.currentPage,
      pageOffset: pageOffset ?? this.pageOffset,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      error: error,
      errorCode: errorCode,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isPageLoading,
    isAccumulatingPages,
    entries,
    scope,
    selectedBranchId,
    selectedStockItemId,
    selectedReason,
    dateFilter,
    pageSize,
    currentPage,
    pageOffset,
    hasNextPage,
    error,
    errorCode,
  ];
}
