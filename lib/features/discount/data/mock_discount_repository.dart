import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/discount/data/discount_error_codes.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/domain/models/discount_eligibility.dart';
import 'package:modular_pos/features/discount/domain/models/discount_item_preflight_result.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_schedule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/domain/models/discount_status.dart';

class MockDiscountRepository implements DiscountRepository {
  MockDiscountRepository()
    : _rules = <DiscountRule>[
        DiscountRule(
          id: 'disc-001',
          tenantId: 'tenant-001',
          branchId: 'branch-001',
          name: 'Morning Coffee 10%',
          percentage: 10,
          scope: DiscountScopes.item,
          status: DiscountStatuses.active,
          itemIds: const <String>['menu-coffee-001', 'menu-coffee-002'],
          schedule: DiscountSchedule(
            startAt: DateTime.utc(2026, 3, 14, 0),
            endAt: DateTime.utc(2026, 3, 30, 0),
          ),
          stackingPolicy: 'MULTIPLICATIVE',
          createdAt: DateTime.utc(2026, 3, 1, 8),
          updatedAt: DateTime.utc(2026, 3, 1, 8),
        ),
        DiscountRule(
          id: 'disc-002',
          tenantId: 'tenant-001',
          branchId: 'branch-002',
          name: 'Branch Opening Promo',
          percentage: 5,
          scope: DiscountScopes.branchWide,
          status: DiscountStatuses.inactive,
          stackingPolicy: 'MULTIPLICATIVE',
          createdAt: DateTime.utc(2026, 3, 10, 9),
          updatedAt: DateTime.utc(2026, 3, 10, 9),
        ),
      ];

  List<DiscountRule> _rules;

  @override
  Future<DiscountRule> createDiscountRule({
    required DiscountRule rule,
    bool confirmOverlap = false,
  }) async {
    final overlaps = _findConflictingRules(candidate: rule);
    if (overlaps.isNotEmpty && !confirmOverlap) {
      throw ApiClientException(
        message:
            'This discount overlaps with existing rules on the assigned branch. Confirm to continue.',
        code: DiscountErrorCodes.overlapWarning,
        statusCode: 409,
        details: <String, dynamic>{
          'conflictingRuleIds': overlaps.map((entry) => entry.id).toList(),
        },
      );
    }

    final created = rule.copyWith(
      id: rule.id.isEmpty ? 'disc-${_rules.length + 1}' : rule.id,
      createdAt: rule.createdAt ?? DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    _rules = [..._rules, created];
    return created;
  }

  @override
  Future<DiscountRule> fetchDiscountRuleById(String ruleId) async {
    return _rules.firstWhere(
      (rule) => rule.id == ruleId,
      orElse: () => throw const ApiClientException(
        message: 'Discount rule not found.',
        code: DiscountErrorCodes.ruleNotFound,
        statusCode: 404,
      ),
    );
  }

  @override
  Future<List<DiscountRule>> fetchDiscountRules({
    String? status,
    String? scope,
    String? branchId,
    String? search,
    int? limit,
    int? offset,
  }) async {
    Iterable<DiscountRule> result = _rules;
    final normalizedStatus = (status ?? '').trim().toUpperCase();
    final normalizedScope = (scope ?? '').trim().toUpperCase();
    final normalizedBranchId = (branchId ?? '').trim();
    final normalizedSearch = (search ?? '').trim().toLowerCase();

    if (normalizedStatus.isNotEmpty && normalizedStatus != 'ALL') {
      result = result.where((rule) => rule.status == normalizedStatus);
    }
    if (normalizedScope.isNotEmpty && normalizedScope != 'ALL') {
      result = result.where((rule) => rule.scope == normalizedScope);
    }
    if (normalizedBranchId.isNotEmpty) {
      result = result.where((rule) => rule.branchId == normalizedBranchId);
    }
    if (normalizedSearch.isNotEmpty) {
      result = result.where(
        (rule) => rule.name.toLowerCase().contains(normalizedSearch),
      );
    }

    final start = (offset ?? 0).clamp(0, 1 << 30);
    final items = result.toList(growable: false);
    final end = limit == null
        ? items.length
        : (start + limit).clamp(0, items.length);
    if (start >= items.length) return const <DiscountRule>[];
    return items.sublist(start, end);
  }

  @override
  Future<DiscountItemPreflightResult> resolveEligibleItemsForBranch({
    required String branchId,
    required List<String> itemIds,
  }) async {
    final eligible = itemIds
        .where((itemId) => itemId.startsWith('menu-'))
        .toList(growable: false);
    final eligibleSet = eligible.toSet();
    final invalid = itemIds
        .where((itemId) => !eligibleSet.contains(itemId))
        .toList(growable: false);

    return DiscountItemPreflightResult(
      branchId: branchId,
      eligibleItemIds: eligible,
      invalidItemIds: invalid,
      allEligible: invalid.isEmpty,
    );
  }

  @override
  Future<List<DiscountEligibilityRule>> resolveDiscountEligibility({
    required String branchId,
    required DateTime occurredAt,
    required List<DiscountEligibilityLineInput> lines,
  }) async {
    final normalizedBranchId = branchId.trim();
    if (normalizedBranchId.isEmpty || lines.isEmpty) {
      return const <DiscountEligibilityRule>[];
    }

    final menuItemIds = {
      for (final line in lines)
        if (line.menuItemId.trim().isNotEmpty) line.menuItemId.trim(),
    };
    final effectiveAt = occurredAt.toUtc();

    return _rules
        .where((rule) {
          if (rule.branchId != normalizedBranchId) return false;
          if (!rule.isActive || rule.isArchived) return false;
          if (!rule.schedule.isEffectiveAt(effectiveAt)) return false;
          if (rule.isBranchWide) return true;
          return rule.itemIds.any(menuItemIds.contains);
        })
        .map(
          (rule) => DiscountEligibilityRule(
            ruleId: rule.id,
            percentage: rule.percentage,
            scope: rule.scope,
            itemIds: rule.itemIds,
            stackingPolicy: rule.stackingPolicy,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<DiscountRule> updateDiscountRule({
    required DiscountRule rule,
    bool confirmOverlap = false,
  }) async {
    final index = _rules.indexWhere((entry) => entry.id == rule.id);
    if (index < 0) {
      return createDiscountRule(rule: rule, confirmOverlap: confirmOverlap);
    }

    final existing = _rules[index];
    if (existing.isCurrentlyEligible) {
      throw const ApiClientException(
        message: 'Currently eligible discount rules cannot be edited.',
        code: DiscountErrorCodes.updateRequiresEffectiveInactive,
        statusCode: 409,
      );
    }

    final overlaps = _findConflictingRules(
      candidate: rule,
      excludedRuleId: rule.id,
    );
    if (overlaps.isNotEmpty && !confirmOverlap) {
      throw ApiClientException(
        message:
            'This discount overlaps with existing rules on the assigned branch. Confirm to continue.',
        code: DiscountErrorCodes.overlapWarning,
        statusCode: 409,
        details: <String, dynamic>{
          'conflictingRuleIds': overlaps.map((entry) => entry.id).toList(),
        },
      );
    }

    final updated = rule.copyWith(updatedAt: DateTime.now().toUtc());
    _rules = [..._rules]..[index] = updated;
    return updated;
  }

  @override
  Future<DiscountRule> updateDiscountRuleStatus({
    required String ruleId,
    required String status,
  }) async {
    final existing = await fetchDiscountRuleById(ruleId);
    final updated = existing.copyWith(
      status: status,
      updatedAt: DateTime.now().toUtc(),
    );
    final index = _rules.indexWhere((entry) => entry.id == existing.id);
    _rules = [..._rules]..[index] = updated;
    return updated;
  }

  List<DiscountRule> _findConflictingRules({
    required DiscountRule candidate,
    String? excludedRuleId,
  }) {
    return _rules
        .where((rule) {
          if (rule.id == excludedRuleId) return false;
          if (rule.branchId != candidate.branchId) return false;
          if (rule.status == DiscountStatuses.archived) return false;
          if (!_schedulesOverlap(rule.schedule, candidate.schedule)) {
            return false;
          }
          if (rule.scope == DiscountScopes.branchWide ||
              candidate.scope == DiscountScopes.branchWide) {
            return true;
          }
          return rule.itemIds.any(candidate.itemIds.contains);
        })
        .toList(growable: false);
  }

  bool _schedulesOverlap(DiscountSchedule left, DiscountSchedule right) {
    final leftStart = left.startAt?.toUtc();
    final leftEnd = left.endAt?.toUtc();
    final rightStart = right.startAt?.toUtc();
    final rightEnd = right.endAt?.toUtc();

    if (leftEnd != null && rightStart != null && leftEnd.isBefore(rightStart)) {
      return false;
    }
    if (rightEnd != null && leftStart != null && rightEnd.isBefore(leftStart)) {
      return false;
    }
    return true;
  }
}
