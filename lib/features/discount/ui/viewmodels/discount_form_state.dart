import 'package:modular_pos/features/discount/domain/models/discount_overlap_warning.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';

class DiscountFormState {
  static const _unset = Object();

  const DiscountFormState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.errorCode,
    this.overlapWarning,
    this.scope = DiscountScopes.item,
    this.name = '',
    this.percentageText = '',
    this.itemIdsText = '',
    this.selectedBranchId = '',
    this.startAt,
    this.endAt,
    this.invalidItemIds = const <String>[],
    this.initialRule,
    this.canManage = false,
  });

  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? errorCode;
  final DiscountOverlapWarning? overlapWarning;
  final String scope;
  final String name;
  final String percentageText;
  final String itemIdsText;
  final String selectedBranchId;
  final DateTime? startAt;
  final DateTime? endAt;
  final List<String> invalidItemIds;
  final DiscountRule? initialRule;
  final bool canManage;

  bool get isEditMode => initialRule != null;
  bool get isEditBlocked => initialRule?.isCurrentlyEligible == true;
  bool get isReadOnly => !canManage || isEditBlocked;

  List<String> get parsedItemIds {
    return itemIdsText
        .split(RegExp(r'[\n,]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  String get previewName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Discount name preview' : trimmed;
  }

  String get previewPercentageLabel {
    final trimmed = percentageText.trim();
    return '${trimmed.isEmpty ? '0' : trimmed}%';
  }

  int get parsedItemCount => parsedItemIds.length;

  DiscountFormState copyWith({
    bool? isLoading,
    bool? isSaving,
    Object? error = _unset,
    Object? errorCode = _unset,
    Object? overlapWarning = _unset,
    String? scope,
    String? name,
    String? percentageText,
    String? itemIdsText,
    String? selectedBranchId,
    Object? startAt = _unset,
    Object? endAt = _unset,
    List<String>? invalidItemIds,
    Object? initialRule = _unset,
    bool? canManage,
  }) {
    return DiscountFormState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: identical(error, _unset) ? this.error : error as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      overlapWarning: identical(overlapWarning, _unset)
          ? this.overlapWarning
          : overlapWarning as DiscountOverlapWarning?,
      scope: scope ?? this.scope,
      name: name ?? this.name,
      percentageText: percentageText ?? this.percentageText,
      itemIdsText: itemIdsText ?? this.itemIdsText,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      startAt: identical(startAt, _unset) ? this.startAt : startAt as DateTime?,
      endAt: identical(endAt, _unset) ? this.endAt : endAt as DateTime?,
      invalidItemIds: invalidItemIds ?? this.invalidItemIds,
      initialRule: identical(initialRule, _unset)
          ? this.initialRule
          : initialRule as DiscountRule?,
      canManage: canManage ?? this.canManage,
    );
  }
}
