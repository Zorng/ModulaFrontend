import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/discount/data/discount_error_codes.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/domain/models/discount_overlap_warning.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_schedule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/domain/models/discount_status.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_form_state.dart';

final discountFormControllerProvider =
    NotifierProvider<DiscountFormController, DiscountFormState>(
      DiscountFormController.new,
    );

class DiscountFormController extends Notifier<DiscountFormState> {
  DiscountRepository get _repository => ref.read(discountRepositoryProvider);
  String? _ruleId;

  bool get isEditMode => (_ruleId ?? '').trim().isNotEmpty;

  @override
  DiscountFormState build() {
    final session = ref.read(loginControllerProvider).session;
    return DiscountFormState(canManage: _canManage(session));
  }

  Future<void> load([String? ruleId]) async {
    final normalizedRuleId = ruleId?.trim() ?? '';

    if (normalizedRuleId.isEmpty) {
      _ruleId = null;
      if (state.initialRule != null ||
          state.name.isNotEmpty ||
          state.percentageText.isNotEmpty ||
          state.itemIdsText.isNotEmpty ||
          state.selectedBranchId.isNotEmpty ||
          state.startAt != null ||
          state.endAt != null ||
          state.invalidItemIds.isNotEmpty ||
          state.error != null ||
          state.errorCode != null ||
          state.overlapWarning != null ||
          state.isLoading ||
          state.isSaving) {
        state = DiscountFormState(canManage: state.canManage);
      }
      return;
    }

    if (_ruleId == normalizedRuleId && state.initialRule != null) {
      return;
    }

    _ruleId = normalizedRuleId;
    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      overlapWarning: null,
    );

    try {
      final rule = await _repository.fetchDiscountRuleById(normalizedRuleId);
      state = state.copyWith(
        isLoading: false,
        initialRule: rule,
        name: rule.name,
        percentageText: rule.percentage == rule.percentage.roundToDouble()
            ? rule.percentage.toStringAsFixed(0)
            : rule.percentage.toStringAsFixed(2),
        itemIdsText: rule.itemIds.join('\n'),
        selectedBranchId: rule.branchId,
        scope: rule.scope,
        startAt: rule.schedule.startAt?.toLocal(),
        endAt: rule.schedule.endAt?.toLocal(),
        invalidItemIds: const <String>[],
        error: null,
        errorCode: null,
        overlapWarning: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load discount rule.',
      );
    }
  }

  void setName(String value) {
    state = state.copyWith(
      name: value,
      error: null,
      errorCode: null,
      overlapWarning: null,
    );
  }

  void setPercentageText(String value) {
    state = state.copyWith(
      percentageText: value,
      error: null,
      errorCode: null,
      overlapWarning: null,
    );
  }

  void setItemIdsText(String value) {
    state = state.copyWith(
      itemIdsText: value,
      error: null,
      errorCode: null,
      overlapWarning: null,
    );
  }

  void setSelectedItemIds(List<String> itemIds) {
    if (state.isReadOnly) return;
    final normalized = itemIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    state = state.copyWith(
      itemIdsText: normalized.join('\n'),
      invalidItemIds: const <String>[],
      error: null,
      errorCode: null,
      overlapWarning: null,
    );
  }

  void setBranchId(String value) {
    if (isEditMode || state.isReadOnly) return;
    state = state.copyWith(
      selectedBranchId: value.trim(),
      itemIdsText: state.scope == DiscountScopes.item ? '' : state.itemIdsText,
      invalidItemIds: const <String>[],
      error: null,
      errorCode: null,
      overlapWarning: null,
    );
  }

  void setScope(String value) {
    if (state.isReadOnly) return;
    state = state.copyWith(
      scope: value,
      itemIdsText: value == DiscountScopes.branchWide ? '' : state.itemIdsText,
      invalidItemIds: const <String>[],
      error: null,
      errorCode: null,
      overlapWarning: null,
    );
  }

  void setStartAt(DateTime? value) {
    if (state.isReadOnly) return;
    state = state.copyWith(
      startAt: value,
      error: null,
      errorCode: null,
      overlapWarning: null,
    );
  }

  void setEndAt(DateTime? value) {
    if (state.isReadOnly) return;
    state = state.copyWith(
      endAt: value,
      error: null,
      errorCode: null,
      overlapWarning: null,
    );
  }

  void clearStartAt() {
    if (state.isReadOnly) return;
    state = state.copyWith(
      startAt: null,
      error: null,
      errorCode: null,
      overlapWarning: null,
    );
  }

  void clearEndAt() {
    if (state.isReadOnly) return;
    state = state.copyWith(
      endAt: null,
      error: null,
      errorCode: null,
      overlapWarning: null,
    );
  }

  void clearError() {
    state = state.copyWith(error: null, errorCode: null, overlapWarning: null);
  }

  Future<DiscountRule?> save({
    required String tenantId,
    bool confirmOverlap = false,
  }) async {
    final normalizedBranchId = state.selectedBranchId.trim();
    final normalizedTenantId = tenantId.trim();

    if (state.isReadOnly) {
      state = state.copyWith(
        error: state.isEditBlocked
            ? 'Currently eligible discount rules cannot be edited.'
            : 'Only admin or owner can save discount changes.',
        errorCode: state.isEditBlocked
            ? DiscountErrorCodes.updateRequiresEffectiveInactive
            : null,
        overlapWarning: null,
      );
      return null;
    }
    if (normalizedBranchId.isEmpty) {
      state = state.copyWith(
        error: 'Select one branch for this discount rule.',
        errorCode: null,
        overlapWarning: null,
      );
      return null;
    }
    if (state.scope == DiscountScopes.item && state.parsedItemIds.isEmpty) {
      state = state.copyWith(
        error: 'Select at least one item for an item-level discount.',
        errorCode: DiscountErrorCodes.itemAssignmentRequired,
        overlapWarning: null,
      );
      return null;
    }
    if (state.startAt != null &&
        state.endAt != null &&
        state.endAt!.isBefore(state.startAt!)) {
      state = state.copyWith(
        error: 'End time must be after start time.',
        errorCode: null,
        overlapWarning: null,
      );
      return null;
    }

    state = state.copyWith(
      isSaving: true,
      error: null,
      errorCode: null,
      overlapWarning: null,
      invalidItemIds: const <String>[],
    );

    try {
      final itemIds = state.parsedItemIds;
      if (state.scope == DiscountScopes.item) {
        final preflight = await _repository.resolveEligibleItemsForBranch(
          branchId: normalizedBranchId,
          itemIds: itemIds,
        );
        if (preflight.invalidItemIds.isNotEmpty) {
          state = state.copyWith(
            isSaving: false,
            error: 'Some selected items are not valid for the assigned branch.',
            errorCode: DiscountErrorCodes.ruleInvalid,
            overlapWarning: null,
            invalidItemIds: preflight.invalidItemIds,
          );
          return null;
        }
      }

      final baseRule =
          (state.initialRule ??
                  DiscountRule(
                    id: '',
                    tenantId: normalizedTenantId,
                    branchId: normalizedBranchId,
                    name: '',
                    percentage: 0,
                    scope: state.scope,
                    status: DiscountStatuses.inactive,
                  ))
              .copyWith(
                tenantId: normalizedTenantId.isEmpty
                    ? (state.initialRule?.tenantId ?? '')
                    : normalizedTenantId,
                branchId: normalizedBranchId,
                name: state.name.trim(),
                percentage: double.parse(state.percentageText.trim()),
                scope: state.scope,
                itemIds: state.scope == DiscountScopes.branchWide
                    ? const <String>[]
                    : itemIds,
                schedule: DiscountSchedule(
                  startAt: state.startAt?.toUtc(),
                  endAt: state.endAt?.toUtc(),
                ),
                status: state.initialRule?.status ?? DiscountStatuses.inactive,
              );

      final saved = isEditMode
          ? await _repository.updateDiscountRule(
              rule: baseRule,
              confirmOverlap: confirmOverlap,
            )
          : await _repository.createDiscountRule(
              rule: baseRule,
              confirmOverlap: confirmOverlap,
            );

      _ruleId = saved.id.trim().isEmpty ? _ruleId : saved.id;
      state = state.copyWith(
        isSaving: false,
        error: null,
        errorCode: null,
        overlapWarning: null,
        initialRule: saved,
        selectedBranchId: saved.branchId,
      );
      return saved;
    } catch (error) {
      if (error is ApiClientException) {
        final normalizedCode = DiscountErrorCodes.normalize(error.code);
        if (normalizedCode == DiscountErrorCodes.overlapWarning) {
          final conflictingRuleIds = _asStringList(
            error.details?['conflictingRuleIds'],
          );
          state = state.copyWith(
            isSaving: false,
            error: error.message,
            errorCode: normalizedCode,
            overlapWarning: DiscountOverlapWarning(
              code: normalizedCode ?? DiscountErrorCodes.overlapWarning,
              message: error.message,
              conflictingRuleIds: conflictingRuleIds,
            ),
          );
          return null;
        }
        state = state.copyWith(
          isSaving: false,
          error: error.message,
          errorCode: normalizedCode,
          overlapWarning: null,
        );
        return null;
      }

      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save discount rule.',
        errorCode: null,
        overlapWarning: null,
      );
      return null;
    }
  }

  List<String> _asStringList(Object? value) {
    if (value is List) {
      return value
          .map((entry) => entry?.toString().trim() ?? '')
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }
}

bool _canManage(AuthSession? session) {
  final role = resolveSessionAuthRole(session);
  return role == AuthRole.admin || role == AuthRole.owner;
}
