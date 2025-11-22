import 'package:equatable/equatable.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';

class CategoryState extends Equatable {
  const CategoryState({
    this.isLoading = false,
    this.categories = const [],
    this.error,
  });

  final bool isLoading;
  final List<InventoryCategory> categories;
  final String? error;

  CategoryState copyWith({
    bool? isLoading,
    List<InventoryCategory>? categories,
    String? error,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, categories, error];
}
