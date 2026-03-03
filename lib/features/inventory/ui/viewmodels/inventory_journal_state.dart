import 'package:equatable/equatable.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';

class InventoryJournalState extends Equatable {
  const InventoryJournalState({
    this.isLoading = false,
    this.entries = const [],
    this.error,
    this.errorCode,
  });

  final bool isLoading;
  final List<InventoryJournalEntry> entries;
  final String? error;
  final InventoryErrorCode? errorCode;

  InventoryJournalState copyWith({
    bool? isLoading,
    List<InventoryJournalEntry>? entries,
    String? error,
    InventoryErrorCode? errorCode,
  }) {
    return InventoryJournalState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
      error: error,
      errorCode: errorCode,
    );
  }

  @override
  List<Object?> get props => [isLoading, entries, error, errorCode];
}
