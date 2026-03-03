import 'package:equatable/equatable.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';

class CategoryState extends Equatable {
  const CategoryState({
    this.isLoading = false,
    this.categories = const [],
    this.error,
    this.errorCode,
  });

  final bool isLoading;
  final List<InventoryCategory> categories;
  final String? error;
  final InventoryErrorCode? errorCode;

  CategoryState copyWith({
    bool? isLoading,
    List<InventoryCategory>? categories,
    String? error,
    InventoryErrorCode? errorCode,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      error: error,
      errorCode: errorCode,
    );
  }

  @override
  List<Object?> get props => [isLoading, categories, error, errorCode];
}
