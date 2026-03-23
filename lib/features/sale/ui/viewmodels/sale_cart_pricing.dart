import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/sale/domain/models/sale_resolved_discount.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';

class SaleCartLinePricing {
  const SaleCartLinePricing({
    required this.menuItemId,
    required this.quantity,
    required this.baseUnitPriceUsd,
    required this.addonUnitTotalUsd,
    required this.preDiscountUnitPriceUsd,
    required this.preDiscountLineTotalUsd,
    required this.itemDiscountUsd,
    required this.discountedUnitPriceUsd,
    required this.lineTotalUsd,
    required this.appliedItemRules,
  });

  final String menuItemId;
  final int quantity;
  final double baseUnitPriceUsd;
  final double addonUnitTotalUsd;
  final double preDiscountUnitPriceUsd;
  final double preDiscountLineTotalUsd;
  final double itemDiscountUsd;
  final double discountedUnitPriceUsd;
  final double lineTotalUsd;
  final List<SaleResolvedDiscountRule> appliedItemRules;

  bool get hasDiscount => itemDiscountUsd.abs() >= 0.005;
}

class SaleCartPricing {
  const SaleCartPricing({
    required this.linePricings,
    required this.preDiscountSubtotalUsd,
    required this.itemDiscountUsd,
    required this.branchWideDiscountUsd,
    required this.discountUsd,
    required this.subtotalUsd,
    required this.taxUsd,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
    required this.branchWideRules,
    required this.discountResolutionBranchId,
  });

  final List<SaleCartLinePricing> linePricings;
  final double preDiscountSubtotalUsd;
  final double itemDiscountUsd;
  final double branchWideDiscountUsd;
  final double discountUsd;
  final double subtotalUsd;
  final double taxUsd;
  final double grandTotalUsd;
  final double grandTotalKhr;
  final List<SaleResolvedDiscountRule> branchWideRules;
  final String? discountResolutionBranchId;

  SaleCartLinePricing pricingForIndex(int index) => linePricings[index];
}

class SaleCartPricingCalculator {
  const SaleCartPricingCalculator._();

  static SaleCartPricing calculate({
    required List<CartLine> lines,
    required Map<String, ModifierGroup> groupLookup,
    required BranchPolicy branchPolicy,
    SaleResolvedDiscountSet? resolvedDiscounts,
  }) {
    final linePricings = lines
        .map(
          (line) => _linePricing(
            line: line,
            groupLookup: groupLookup,
            resolvedDiscounts: resolvedDiscounts,
          ),
        )
        .toList(growable: false);

    final preDiscountSubtotalUsd = linePricings.fold<double>(
      0,
      (sum, line) => sum + line.preDiscountLineTotalUsd,
    );
    final itemDiscountUsd = linePricings.fold<double>(
      0,
      (sum, line) => sum + line.itemDiscountUsd,
    );
    final subtotalAfterItemDiscountUsd = linePricings.fold<double>(
      0,
      (sum, line) => sum + line.lineTotalUsd,
    );

    final branchWideRules = resolvedDiscounts?.branchWideRules ?? const [];
    final branchWideMultiplier = _combinedMultiplier(branchWideRules);
    final subtotalAfterBranchDiscountUsd =
        subtotalAfterItemDiscountUsd * branchWideMultiplier;
    final branchWideDiscountUsd =
        subtotalAfterItemDiscountUsd - subtotalAfterBranchDiscountUsd;
    final discountUsd = itemDiscountUsd + branchWideDiscountUsd;
    final taxUsd = _taxUsd(
      subtotalAfterBranchDiscountUsd,
      branchPolicy: branchPolicy,
    );
    final grandTotalUsd = subtotalAfterBranchDiscountUsd + taxUsd;
    final grandTotalKhr = _grandTotalKhr(
      grandTotalUsd,
      branchPolicy: branchPolicy,
    );

    return SaleCartPricing(
      linePricings: linePricings,
      preDiscountSubtotalUsd: preDiscountSubtotalUsd,
      itemDiscountUsd: itemDiscountUsd,
      branchWideDiscountUsd: branchWideDiscountUsd,
      discountUsd: discountUsd,
      subtotalUsd: subtotalAfterBranchDiscountUsd,
      taxUsd: taxUsd,
      grandTotalUsd: grandTotalUsd,
      grandTotalKhr: grandTotalKhr,
      branchWideRules: branchWideRules,
      discountResolutionBranchId: resolvedDiscounts?.branchId,
    );
  }

  static SaleCartLinePricing _linePricing({
    required CartLine line,
    required Map<String, ModifierGroup> groupLookup,
    required SaleResolvedDiscountSet? resolvedDiscounts,
  }) {
    final addonUnitTotalUsd = _addonUnitTotalUsd(
      line: line,
      groupLookup: groupLookup,
    );
    final preDiscountUnitPriceUsd = line.item.price + addonUnitTotalUsd;
    final preDiscountLineTotalUsd = preDiscountUnitPriceUsd * line.quantity;
    final appliedItemRules =
        (resolvedDiscounts?.rulesForMenuItem(line.item.id) ?? const [])
            .where((rule) => rule.isItemLevel)
            .toList(growable: false);
    final itemMultiplier = _combinedMultiplier(appliedItemRules);
    final lineTotalUsd = preDiscountLineTotalUsd * itemMultiplier;
    final itemDiscountUsd = preDiscountLineTotalUsd - lineTotalUsd;
    final discountedUnitPriceUsd = line.quantity <= 0
        ? 0.0
        : lineTotalUsd / line.quantity;

    return SaleCartLinePricing(
      menuItemId: line.item.id,
      quantity: line.quantity,
      baseUnitPriceUsd: line.item.price,
      addonUnitTotalUsd: addonUnitTotalUsd,
      preDiscountUnitPriceUsd: preDiscountUnitPriceUsd,
      preDiscountLineTotalUsd: preDiscountLineTotalUsd,
      itemDiscountUsd: itemDiscountUsd,
      discountedUnitPriceUsd: discountedUnitPriceUsd,
      lineTotalUsd: lineTotalUsd,
      appliedItemRules: appliedItemRules,
    );
  }

  static double _addonUnitTotalUsd({
    required CartLine line,
    required Map<String, ModifierGroup> groupLookup,
  }) {
    var addonTotalUsd = 0.0;
    for (final entry in line.selectedOptionIds.entries) {
      final group = groupLookup[entry.key];
      if (group == null) continue;
      for (final optionId in entry.value) {
        final option = group.options.where(
          (candidate) => candidate.id == optionId,
        );
        if (option.isNotEmpty) {
          addonTotalUsd += option.first.price;
        }
      }
    }
    return addonTotalUsd;
  }

  static double _combinedMultiplier(List<SaleResolvedDiscountRule> rules) {
    var multiplier = 1.0;
    for (final rule in rules) {
      final percentage = rule.percentage.clamp(0, 100).toDouble();
      multiplier *= (1 - (percentage / 100));
    }
    return multiplier;
  }

  static double _taxUsd(
    double subtotalUsd, {
    required BranchPolicy branchPolicy,
  }) {
    if (!branchPolicy.saleVatEnabled) {
      return 0;
    }
    final ratePercent = branchPolicy.saleVatRatePercent;
    if (ratePercent <= 0) {
      return 0;
    }
    return subtotalUsd * (ratePercent / 100);
  }

  static double _grandTotalKhr(
    double totalUsd, {
    required BranchPolicy branchPolicy,
  }) {
    final roundingMode = BranchPolicyRoundingModes.normalize(
      branchPolicy.saleKhrRoundingMode,
    );
    final roundingGranularity = BranchPolicyRoundingGranularities.asAmount(
      branchPolicy.saleKhrRoundingGranularity,
    );
    final baseKhr = (totalUsd * branchPolicy.saleFxRateKhrPerUsd).toDouble();
    return _roundKhr(
      baseKhr,
      enabled: branchPolicy.saleKhrRoundingEnabled,
      mode: roundingMode,
      granularity: roundingGranularity,
    );
  }

  static double _roundKhr(
    double amount, {
    required bool enabled,
    required String mode,
    required double granularity,
  }) {
    if (!enabled) {
      return amount;
    }
    final step = granularity <= 0 ? 100.0 : granularity;
    final ratio = amount / step;
    switch (mode.toUpperCase()) {
      case BranchPolicyRoundingModes.up:
        return ratio.ceil() * step;
      case BranchPolicyRoundingModes.down:
        return ratio.floor() * step;
      default:
        return ratio.round() * step;
    }
  }
}
