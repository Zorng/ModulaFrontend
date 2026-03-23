import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_detail_state.dart';

final discountDetailControllerProvider =
    NotifierProvider<DiscountDetailController, DiscountDetailState>(
      DiscountDetailController.new,
    );

class DiscountDetailController extends Notifier<DiscountDetailState> {
  DiscountRepository get _repository => ref.read(discountRepositoryProvider);
  String? _ruleId;

  @override
  DiscountDetailState build() {
    final session = ref.read(loginControllerProvider).session;
    return DiscountDetailState(canManage: _canManage(session));
  }

  Future<void> load(String ruleId) async {
    final normalizedRuleId = ruleId.trim();
    if (normalizedRuleId.isEmpty) {
      _ruleId = null;
      state = state.copyWith(
        clearRule: true,
        isLoading: false,
        isUpdating: false,
        error: 'Missing discount rule id.',
      );
      return;
    }

    if (_ruleId == normalizedRuleId && state.rule != null && !state.isLoading) {
      return;
    }

    _ruleId = normalizedRuleId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final rule = await _repository.fetchDiscountRuleById(normalizedRuleId);
      state = state.copyWith(
        rule: rule,
        isLoading: false,
        isUpdating: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        clearRule: true,
        isLoading: false,
        isUpdating: false,
        error: 'Failed to load discount rule.',
      );
    }
  }

  Future<void> refresh() async {
    final currentRuleId = _ruleId;
    if (currentRuleId == null || currentRuleId.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final rule = await _repository.fetchDiscountRuleById(currentRuleId);
      state = state.copyWith(
        rule: rule,
        isLoading: false,
        isUpdating: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isUpdating: false,
        error: 'Failed to load discount rule.',
      );
    }
  }

  Future<DiscountRule?> updateStatus(String status) async {
    final rule = state.rule;
    if (rule == null || state.isUpdating || state.isReadOnly) return null;

    state = state.copyWith(isUpdating: true, clearError: true);
    try {
      final updated = await _repository.updateDiscountRuleStatus(
        ruleId: rule.id,
        status: status,
      );
      state = state.copyWith(
        rule: updated,
        isUpdating: false,
        clearError: true,
      );
      return updated;
    } catch (_) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update discount status.',
      );
      return null;
    }
  }

  void applyUpdatedRule(DiscountRule rule) {
    _ruleId = rule.id.trim().isEmpty ? _ruleId : rule.id;
    state = state.copyWith(rule: rule, clearError: true);
  }

  void clearError() {
    if (state.error == null) return;
    state = state.copyWith(clearError: true);
  }
}

bool _canManage(AuthSession? session) {
  final role = resolveSessionAuthRole(session);
  return role == AuthRole.admin || role == AuthRole.owner;
}
