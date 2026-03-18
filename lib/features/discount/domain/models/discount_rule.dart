import 'package:modular_pos/features/discount/domain/models/discount_schedule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/domain/models/discount_status.dart';

class DiscountRule {
  const DiscountRule({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.name,
    required this.percentage,
    required this.scope,
    required this.status,
    this.itemIds = const <String>[],
    this.schedule = const DiscountSchedule(),
    this.stackingPolicy = 'MULTIPLICATIVE',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String branchId;
  final String name;
  final double percentage;
  final String scope;
  final String status;
  final List<String> itemIds;
  final DiscountSchedule schedule;
  final String stackingPolicy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == DiscountStatuses.active;
  bool get isArchived => status == DiscountStatuses.archived;
  bool get isItemLevel => scope == DiscountScopes.item;
  bool get isBranchWide => scope == DiscountScopes.branchWide;
  bool get isCurrentlyEligible =>
      isActive && !isArchived && schedule.isEffectiveAt(DateTime.now().toUtc());

  DiscountRule copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? name,
    double? percentage,
    String? scope,
    String? status,
    List<String>? itemIds,
    DiscountSchedule? schedule,
    String? stackingPolicy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiscountRule(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      scope: scope == null ? this.scope : DiscountScopes.normalize(scope),
      status: status == null ? this.status : DiscountStatuses.normalize(status),
      itemIds: itemIds ?? this.itemIds,
      schedule: schedule ?? this.schedule,
      stackingPolicy: stackingPolicy ?? this.stackingPolicy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
