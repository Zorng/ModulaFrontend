import 'package:flutter/foundation.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item_detail.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/menu_modifier_option_effect.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

const _unset = Object();

@immutable
class MenuState {
  const MenuState({
    this.isLoading = true,
    this.allItems = const [],
    this.filteredItems = const [],
    this.categories = const [],
    this.modifierGroups = const [],
    this.branches = const [],
    this.detailByItemId = const {},
    this.detailLoadingByItemId = const {},
    this.detailErrorsByItemId = const {},
    this.baseCompositionByItemId = const {},
    this.modifierOptionEffectsByItemId = const {},
    this.modifierOptionEffectsLoadingByItemId = const {},
    this.modifierOptionEffectsErrorsByItemId = const {},
    this.evaluatedCompositionByItemId = const {},
    this.hydratedItems = const {},
    this.hydratedModifierGroups = const {},
    this.hydrationErrors = const {},
    this.compositionByItem = const {},
    this.compositionEvaluationByItem = const {},
    this.compositionLoadedByItem = const {},
    this.compositionLoadingByItem = const {},
    this.compositionErrors = const {},
    this.compositionErrorCodes = const {},
    this.selectedCategoryId = 'all',
    this.selectedBranchId = 'all',
    this.selectedStatus = 'active',
    this.searchQuery = '',
    this.error,
    this.errorCode,
  });

  final bool isLoading;
  final List<MenuItem> allItems;
  final List<MenuItem> filteredItems;
  final List<MenuCategory> categories;
  final List<ModifierGroup> modifierGroups;
  final List<MenuBranch> branches;

  // Explicit detail/effect state for the new menu contract direction.
  final Map<String, MenuItemDetail> detailByItemId;
  final Map<String, bool> detailLoadingByItemId;
  final Map<String, String> detailErrorsByItemId;
  final Map<String, List<MenuComponent>> baseCompositionByItemId;
  final Map<String, List<MenuModifierOptionEffect>> modifierOptionEffectsByItemId;
  final Map<String, bool> modifierOptionEffectsLoadingByItemId;
  final Map<String, String> modifierOptionEffectsErrorsByItemId;
  final Map<String, MenuCompositionEvaluate> evaluatedCompositionByItemId;
  final Map<String, MenuItem> hydratedItems;
  final Map<String, ModifierGroup> hydratedModifierGroups;
  final Map<String, String> hydrationErrors;
  final Map<String, List<MenuComponent>> compositionByItem;
  final Map<String, MenuCompositionEvaluate> compositionEvaluationByItem;
  final Map<String, bool> compositionLoadedByItem;
  final Map<String, bool> compositionLoadingByItem;
  final Map<String, String> compositionErrors;
  final Map<String, String> compositionErrorCodes;
  final String selectedCategoryId;
  final String selectedBranchId;
  final String selectedStatus;
  final String searchQuery;
  final String? error;
  final String? errorCode;

  MenuState copyWith({
    bool? isLoading,
    List<MenuItem>? allItems,
    List<MenuItem>? filteredItems,
    List<MenuCategory>? categories,
    List<ModifierGroup>? modifierGroups,
    List<MenuBranch>? branches,
    Map<String, MenuItemDetail>? detailByItemId,
    Map<String, bool>? detailLoadingByItemId,
    Map<String, String>? detailErrorsByItemId,
    Map<String, List<MenuComponent>>? baseCompositionByItemId,
    Map<String, List<MenuModifierOptionEffect>>? modifierOptionEffectsByItemId,
    Map<String, bool>? modifierOptionEffectsLoadingByItemId,
    Map<String, String>? modifierOptionEffectsErrorsByItemId,
    Map<String, MenuCompositionEvaluate>? evaluatedCompositionByItemId,
    Map<String, MenuItem>? hydratedItems,
    Map<String, ModifierGroup>? hydratedModifierGroups,
    Map<String, String>? hydrationErrors,
    Map<String, List<MenuComponent>>? compositionByItem,
    Map<String, MenuCompositionEvaluate>? compositionEvaluationByItem,
    Map<String, bool>? compositionLoadedByItem,
    Map<String, bool>? compositionLoadingByItem,
    Map<String, String>? compositionErrors,
    Map<String, String>? compositionErrorCodes,
    String? selectedCategoryId,
    String? selectedBranchId,
    String? selectedStatus,
    String? searchQuery,
    Object? error = _unset,
    Object? errorCode = _unset,
  }) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      categories: categories ?? this.categories,
      modifierGroups: modifierGroups ?? this.modifierGroups,
      branches: branches ?? this.branches,
      detailByItemId: detailByItemId ?? this.detailByItemId,
      detailLoadingByItemId:
          detailLoadingByItemId ?? this.detailLoadingByItemId,
      detailErrorsByItemId: detailErrorsByItemId ?? this.detailErrorsByItemId,
      baseCompositionByItemId:
          baseCompositionByItemId ?? this.baseCompositionByItemId,
      modifierOptionEffectsByItemId:
          modifierOptionEffectsByItemId ??
          this.modifierOptionEffectsByItemId,
      modifierOptionEffectsLoadingByItemId:
          modifierOptionEffectsLoadingByItemId ??
          this.modifierOptionEffectsLoadingByItemId,
      modifierOptionEffectsErrorsByItemId:
          modifierOptionEffectsErrorsByItemId ??
          this.modifierOptionEffectsErrorsByItemId,
      evaluatedCompositionByItemId:
          evaluatedCompositionByItemId ?? this.evaluatedCompositionByItemId,
      hydratedItems: hydratedItems ?? this.hydratedItems,
      hydratedModifierGroups:
          hydratedModifierGroups ?? this.hydratedModifierGroups,
      hydrationErrors: hydrationErrors ?? this.hydrationErrors,
      compositionByItem: compositionByItem ?? this.compositionByItem,
      compositionEvaluationByItem:
          compositionEvaluationByItem ?? this.compositionEvaluationByItem,
      compositionLoadedByItem:
          compositionLoadedByItem ?? this.compositionLoadedByItem,
      compositionLoadingByItem:
          compositionLoadingByItem ?? this.compositionLoadingByItem,
      compositionErrors: compositionErrors ?? this.compositionErrors,
      compositionErrorCodes:
          compositionErrorCodes ?? this.compositionErrorCodes,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      error: identical(error, _unset) ? this.error : error as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
    );
  }
}
