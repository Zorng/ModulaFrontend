import 'package:modular_pos/features/discount/data/discount_api.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/data/dto/discount_eligibility_dto.dart';
import 'package:modular_pos/features/discount/data/dto/discount_item_preflight_result_dto.dart';
import 'package:modular_pos/features/discount/data/dto/discount_rule_dto.dart';
import 'package:modular_pos/features/discount/domain/models/discount_eligibility.dart';
import 'package:modular_pos/features/discount/domain/models/discount_item_preflight_result.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_schedule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/domain/models/discount_status.dart';

class RemoteDiscountRepository implements DiscountRepository {
  RemoteDiscountRepository(this._api);

  final DiscountApi _api;

  @override
  Future<List<DiscountRule>> fetchDiscountRules({
    String? status,
    String? scope,
    String? branchId,
    String? search,
    int? limit,
    int? offset,
  }) async {
    final rows = await _api.getDiscountRules(
      status: status,
      scope: scope,
      branchId: branchId,
      search: search,
      limit: limit,
      offset: offset,
    );
    return rows.map(_toDiscountRule).toList(growable: false);
  }

  @override
  Future<DiscountRule> fetchDiscountRuleById(String ruleId) async {
    final dto = await _api.getDiscountRuleById(ruleId);
    return _toDiscountRule(dto);
  }

  @override
  Future<DiscountRule> createDiscountRule({
    required DiscountRule rule,
    bool confirmOverlap = false,
  }) async {
    final dto = await _api.createDiscountRule(
      rule: rule,
      confirmOverlap: confirmOverlap,
    );
    return _toDiscountRule(dto);
  }

  @override
  Future<DiscountItemPreflightResult> resolveEligibleItemsForBranch({
    required String branchId,
    required List<String> itemIds,
  }) async {
    final dto = await _api.resolveEligibleItemsForBranch(
      branchId: branchId,
      itemIds: itemIds,
    );
    return _toPreflightResult(dto);
  }

  @override
  Future<List<DiscountEligibilityRule>> resolveDiscountEligibility({
    required String branchId,
    required DateTime occurredAt,
    required List<DiscountEligibilityLineInput> lines,
  }) async {
    final rows = await _api.resolveDiscountEligibility(
      branchId: branchId,
      occurredAt: occurredAt,
      lines: lines,
    );
    return rows.map(_toEligibilityRule).toList(growable: false);
  }

  @override
  Future<DiscountRule> updateDiscountRule({
    required DiscountRule rule,
    bool confirmOverlap = false,
  }) async {
    final dto = await _api.updateDiscountRule(
      rule: rule,
      confirmOverlap: confirmOverlap,
    );
    return _toDiscountRule(dto);
  }

  @override
  Future<DiscountRule> updateDiscountRuleStatus({
    required String ruleId,
    required String status,
  }) async {
    final dto = await _api.updateDiscountRuleStatus(
      ruleId: ruleId,
      status: status,
    );
    return _toDiscountRule(dto);
  }

  DiscountRule _toDiscountRule(DiscountRuleDto dto) {
    return DiscountRule(
      id: dto.id,
      tenantId: dto.tenantId,
      branchId: dto.branchId,
      name: dto.name,
      percentage: dto.percentage,
      scope: DiscountScopes.normalize(dto.scope),
      status: DiscountStatuses.normalize(dto.status),
      itemIds: dto.itemIds,
      schedule: DiscountSchedule(
        startAt: _asDateTime(dto.schedule.startAt),
        endAt: _asDateTime(dto.schedule.endAt),
      ),
      stackingPolicy: dto.stackingPolicy,
      createdAt: _asDateTime(dto.createdAt),
      updatedAt: _asDateTime(dto.updatedAt),
    );
  }

  DiscountItemPreflightResult _toPreflightResult(
    DiscountItemPreflightResultDto dto,
  ) {
    return DiscountItemPreflightResult(
      branchId: dto.branchId,
      eligibleItemIds: dto.eligibleItemIds,
      invalidItemIds: dto.invalidItemIds,
      allEligible: dto.allEligible,
    );
  }

  DiscountEligibilityRule _toEligibilityRule(DiscountEligibilityRuleDto dto) {
    return DiscountEligibilityRule(
      ruleId: dto.ruleId,
      percentage: dto.percentage,
      scope: DiscountScopes.normalize(dto.scope),
      itemIds: dto.itemIds,
      stackingPolicy: dto.stackingPolicy,
    );
  }

  DateTime? _asDateTime(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    return DateTime.tryParse(value!);
  }
}
