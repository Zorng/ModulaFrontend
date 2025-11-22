import 'package:equatable/equatable.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

class StockInventoryState extends Equatable {
  const StockInventoryState({
    this.isLoading = false,
    this.items = const [],
    this.batches = const [],
    this.error,
  });

  final bool isLoading;
  final List<StockItem> items;
  final List<StockBatch> batches;
  final String? error;

  StockInventoryState copyWith({
    bool? isLoading,
    List<StockItem>? items,
    List<StockBatch>? batches,
    String? error,
  }) {
    return StockInventoryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      batches: batches ?? this.batches,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, batches, error];
}
