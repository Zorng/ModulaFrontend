import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/domain/models/discount_eligibility.dart';
import 'package:modular_pos/features/sale/domain/models/sale_resolved_discount.dart';

final saleDiscountResolverProvider = Provider<SaleDiscountResolver>((ref) {
  final repository = ref.watch(discountRepositoryProvider);
  return SaleDiscountResolver(repository);
});

class SaleDiscountResolver {
  const SaleDiscountResolver(this._repository);

  final DiscountRepository _repository;

  Future<SaleResolvedDiscountSet> resolveForCart({
    required String branchId,
    required DateTime occurredAt,
    required List<SaleDiscountResolveLine> lines,
  }) async {
    final normalizedBranchId = branchId.trim();
    final normalizedLines = lines
        .where((line) => line.menuItemId.trim().isNotEmpty && line.quantity > 0)
        .map(
          (line) => DiscountEligibilityLineInput(
            menuItemId: line.menuItemId.trim(),
            quantity: line.quantity,
          ),
        )
        .toList(growable: false);

    if (normalizedBranchId.isEmpty || normalizedLines.isEmpty) {
      return SaleResolvedDiscountSet(
        branchId: normalizedBranchId,
        occurredAt: occurredAt.toUtc(),
        rules: const <SaleResolvedDiscountRule>[],
      );
    }

    final rules = await _repository.resolveDiscountEligibility(
      branchId: normalizedBranchId,
      occurredAt: occurredAt.toUtc(),
      lines: normalizedLines,
    );

    return SaleResolvedDiscountSet(
      branchId: normalizedBranchId,
      occurredAt: occurredAt.toUtc(),
      rules: rules
          .map(
            (rule) => SaleResolvedDiscountRule(
              ruleId: rule.ruleId,
              percentage: rule.percentage,
              scope: rule.scope,
              itemIds: rule.itemIds,
              stackingPolicy: rule.stackingPolicy,
            ),
          )
          .toList(growable: false),
    );
  }
}
