import 'package:flutter/foundation.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';

@immutable
class MenuState {
  final bool isLoading;
  final List<MenuItem> allItems;
  final List<MenuItem> filteredItems;
  final String selectedCategory;
  final String? error;

  const MenuState({
    this.isLoading = true,
    this.allItems = const [],
    this.filteredItems = const [],
    this.selectedCategory = 'All',
    this.error,
  });

  MenuState copyWith({
    bool? isLoading,
    List<MenuItem>? allItems,
    List<MenuItem>? filteredItems,
    String? selectedCategory,
    String? error,
  }) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      error: error ?? this.error,
    );
  }
}