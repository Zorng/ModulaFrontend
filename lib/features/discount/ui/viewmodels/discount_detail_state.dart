import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';

class DiscountDetailState {
  const DiscountDetailState({
    this.rule,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
    this.canManage = false,
  });

  final DiscountRule? rule;
  final bool isLoading;
  final bool isUpdating;
  final String? error;
  final bool canManage;

  bool get hasRule => rule != null;
  bool get isReadOnly => !canManage;
  bool get canEdit => canManage && !(rule?.isCurrentlyEligible ?? false);

  DiscountDetailState copyWith({
    DiscountRule? rule,
    bool clearRule = false,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    bool clearError = false,
    bool? canManage,
  }) {
    return DiscountDetailState(
      rule: clearRule ? null : (rule ?? this.rule),
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : (error ?? this.error),
      canManage: canManage ?? this.canManage,
    );
  }
}
