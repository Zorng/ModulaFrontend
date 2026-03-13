import 'package:equatable/equatable.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';

const Object _inventoryJournalUnset = Object();

enum InventoryJournalScope { tenantWide, branch }

class InventoryJournalState extends Equatable {
  const InventoryJournalState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.entries = const [],
    this.scope = InventoryJournalScope.tenantWide,
    this.selectedBranchId = 'all',
    this.selectedStockItemId = '',
    this.selectedReason,
    this.limit = 50,
    this.offset = 0,
    this.hasMore = true,
    this.error,
    this.errorCode,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final List<InventoryJournalEntry> entries;
  final InventoryJournalScope scope;
  final String selectedBranchId;
  final String selectedStockItemId;
  final InventoryJournalReason? selectedReason;
  final int limit;
  final int offset;
  final bool hasMore;
  final String? error;
  final InventoryErrorCode? errorCode;

  InventoryJournalState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<InventoryJournalEntry>? entries,
    InventoryJournalScope? scope,
    String? selectedBranchId,
    String? selectedStockItemId,
    Object? selectedReason = _inventoryJournalUnset,
    int? limit,
    int? offset,
    bool? hasMore,
    String? error,
    InventoryErrorCode? errorCode,
  }) {
    return InventoryJournalState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      entries: entries ?? this.entries,
      scope: scope ?? this.scope,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      selectedStockItemId: selectedStockItemId ?? this.selectedStockItemId,
      selectedReason: identical(selectedReason, _inventoryJournalUnset)
          ? this.selectedReason
          : selectedReason as InventoryJournalReason?,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      errorCode: errorCode,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingMore,
    entries,
    scope,
    selectedBranchId,
    selectedStockItemId,
    selectedReason,
    limit,
    offset,
    hasMore,
    error,
    errorCode,
  ];
}
