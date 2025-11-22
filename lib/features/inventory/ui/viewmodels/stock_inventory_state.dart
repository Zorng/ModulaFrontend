import 'package:equatable/equatable.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

class StockInventoryState extends Equatable {
  const StockInventoryState({
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  final bool isLoading;
  final List<StockItem> items;
  final String? error;

  StockInventoryState copyWith({
    bool? isLoading,
    List<StockItem>? items,
    String? error,
  }) {
    return StockInventoryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, error];
}
