import 'package:flutter/foundation.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

@immutable
class MenuState {
  const MenuState({
    this.isLoading = true,
    this.allItems = const [],
    this.filteredItems = const [],
    this.categories = const [],
    this.modifierGroups = const [],
    this.branches = const [],
    this.hydratedItems = const {},
    this.hydratedModifierGroups = const {},
    this.hydrationErrors = const {},
    this.selectedCategoryId = 'all',
    this.selectedBranchId = 'all',
    this.searchQuery = '',
    this.error,
  });

  final bool isLoading;
  final List<MenuItem> allItems;
  final List<MenuItem> filteredItems;
  final List<MenuCategory> categories;
  final List<ModifierGroup> modifierGroups;
  final List<MenuBranch> branches;
  final Map<String, MenuItem> hydratedItems;
  final Map<String, ModifierGroup> hydratedModifierGroups;
  final Map<String, String> hydrationErrors;
  final String selectedCategoryId;
  final String selectedBranchId;
  final String searchQuery;
  final String? error;

  MenuState copyWith({
    bool? isLoading,
    List<MenuItem>? allItems,
    List<MenuItem>? filteredItems,
    List<MenuCategory>? categories,
    List<ModifierGroup>? modifierGroups,
    List<MenuBranch>? branches,
    Map<String, MenuItem>? hydratedItems,
    Map<String, ModifierGroup>? hydratedModifierGroups,
    Map<String, String>? hydrationErrors,
    String? selectedCategoryId,
    String? selectedBranchId,
    String? searchQuery,
    String? error,
  }) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      categories: categories ?? this.categories,
      modifierGroups: modifierGroups ?? this.modifierGroups,
      branches: branches ?? this.branches,
      hydratedItems: hydratedItems ?? this.hydratedItems,
      hydratedModifierGroups:
          hydratedModifierGroups ?? this.hydratedModifierGroups,
      hydrationErrors: hydrationErrors ?? this.hydrationErrors,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error ?? this.error,
    );
  }
}
