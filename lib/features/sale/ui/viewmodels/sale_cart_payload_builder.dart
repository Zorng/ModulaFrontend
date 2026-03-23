import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_pricing.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';

class SaleCartPayloadBuilder {
  const SaleCartPayloadBuilder._();

  static bool mapsEqual(
    Map<String, List<String>> a,
    Map<String, List<String>> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null) return false;
      final listA = [...entry.value]..sort();
      final listB = [...other]..sort();
      if (listA.length != listB.length) return false;
      for (var i = 0; i < listA.length; i++) {
        if (listA[i] != listB[i]) return false;
      }
    }
    return true;
  }

  static SaleDraftItemInputDto fromSelection(
    SaleItemSelectionResult selection,
  ) {
    final unitPriceUsd = selection.unitPriceUsd;
    final lineTotalUsdExact = selection.lineTotalUsd;
    final addonTotalUsd = selection.addonTotalUsd;
    final pricingSnapshot = _pricingSnapshot(
      basePrice: selection.item.price,
      addonTotalUsd: addonTotalUsd,
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: lineTotalUsdExact,
    );
    final modifiers = _buildModifiersFromSelection(
      selection.selectedOptionIds,
      selection.selectedOptions,
      pricingSnapshot,
    );

    return SaleDraftItemInputDto(
      menuItemId: selection.item.id,
      quantity: selection.quantity,
      selectedOptionIds: selection.selectedOptionIds,
      modifiers: modifiers,
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: lineTotalUsdExact,
      addonTotalUsd: addonTotalUsd,
      pricingSnapshot: pricingSnapshot,
    );
  }

  static SaleDraftItemInputDto fromLine(
    CartLine line, {
    SaleCartLinePricing? pricing,
    SaleCartPricing? cartPricing,
  }) {
    final addonTotalUsd =
        pricing?.addonUnitTotalUsd ?? _addonUnitTotalFromLine(line);
    final unitPriceUsd =
        pricing?.discountedUnitPriceUsd ?? (line.item.price + addonTotalUsd);
    final lineTotalUsdExact =
        pricing?.lineTotalUsd ?? (unitPriceUsd * line.quantity);
    final pricingSnapshot = _pricingSnapshot(
      basePrice: line.item.price,
      addonTotalUsd: addonTotalUsd,
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: lineTotalUsdExact,
      lineBaseAmountUsd: pricing?.preDiscountLineTotalUsd,
      itemDiscountUsd: pricing?.itemDiscountUsd,
      discountResolutionBranchId: cartPricing?.discountResolutionBranchId,
      appliedItemDiscounts:
          pricing?.appliedItemRules
              .map(
                (rule) => SaleAppliedDiscountSnapshotDto(
                  ruleId: rule.ruleId,
                  percentage: rule.percentage,
                  scope: rule.scope,
                ),
              )
              .toList(growable: false) ??
          const <SaleAppliedDiscountSnapshotDto>[],
      cartDiscountSnapshot: cartPricing == null
          ? null
          : <String, dynamic>{
              'preDiscountSubtotalUsd': cartPricing.preDiscountSubtotalUsd,
              'itemDiscountUsd': cartPricing.itemDiscountUsd,
              'branchWideDiscountUsd': cartPricing.branchWideDiscountUsd,
              'discountUsd': cartPricing.discountUsd,
              'subtotalUsd': cartPricing.subtotalUsd,
              'branchWideDiscounts': cartPricing.branchWideRules
                  .map(
                    (rule) => <String, dynamic>{
                      'ruleId': rule.ruleId,
                      'percentage': rule.percentage,
                      'scope': rule.scope,
                    },
                  )
                  .toList(growable: false),
            },
    );
    final modifiers = _buildModifiersFromLine(line, pricingSnapshot);

    return SaleDraftItemInputDto(
      menuItemId: line.item.id,
      quantity: line.quantity,
      selectedOptionIds: line.selectedOptionIds,
      modifiers: modifiers,
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: lineTotalUsdExact,
      addonTotalUsd: addonTotalUsd,
      pricingSnapshot: pricingSnapshot,
    );
  }

  static SalePricingSnapshotDto _pricingSnapshot({
    required double basePrice,
    required double addonTotalUsd,
    required double unitPriceUsd,
    required double lineTotalUsdExact,
    double? lineBaseAmountUsd,
    double? itemDiscountUsd,
    String? discountResolutionBranchId,
    List<SaleAppliedDiscountSnapshotDto> appliedItemDiscounts =
        const <SaleAppliedDiscountSnapshotDto>[],
    Map<String, dynamic>? cartDiscountSnapshot,
  }) {
    return SalePricingSnapshotDto(
      baseUnitPriceUsd: basePrice,
      addonTotalUsd: addonTotalUsd,
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: lineTotalUsdExact,
      lineBaseAmountUsd: lineBaseAmountUsd,
      itemDiscountUsd: itemDiscountUsd,
      discountResolutionBranchId: discountResolutionBranchId,
      appliedItemDiscounts: appliedItemDiscounts,
      cartDiscountSnapshot: cartDiscountSnapshot,
    );
  }

  static List<SaleDraftModifierInputDto> _buildModifiersFromSelection(
    Map<String, List<String>> selectedOptionIds,
    Map<String, List<ModifierOption>> selectedOptions,
    SalePricingSnapshotDto pricingSnapshot,
  ) {
    final modifiers = <SaleDraftModifierInputDto>[];
    final entries = selectedOptionIds.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final options = selectedOptions[entry.key] ?? const <ModifierOption>[];
      final optionSummaries = _optionSummaries(options);
      final addonTotal = options.fold<double>(0, (sum, opt) => sum + opt.price);
      final modifierPayload = _modifierPayload(
        groupId: entry.key,
        optionIds: entry.value,
        optionSummaries: optionSummaries,
        addonTotal: addonTotal,
        pricingSnapshot: i == 0 ? pricingSnapshot : null,
      );
      modifiers.add(modifierPayload);
    }
    return modifiers;
  }

  static List<SaleDraftModifierOptionDto> _optionSummaries(
    List<ModifierOption> options,
  ) {
    return options
        .map(
          (opt) => SaleDraftModifierOptionDto(
            id: opt.id,
            label: opt.name,
            priceAdjustmentUsd: opt.price,
            isDefault: opt.isDefault,
          ),
        )
        .toList();
  }

  static double _addonUnitTotalFromLine(CartLine line) {
    var addonTotalUsd = 0.0;
    for (final options in line.selectedOptions.values) {
      addonTotalUsd += options.fold<double>(0, (sum, opt) => sum + opt.price);
    }
    return addonTotalUsd;
  }

  static List<SaleDraftModifierInputDto> _buildModifiersFromLine(
    CartLine line,
    SalePricingSnapshotDto pricingSnapshot,
  ) {
    final modifiers = <SaleDraftModifierInputDto>[];
    final entries = line.selectedOptionIds.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final options =
          line.selectedOptions[entry.key] ?? const <ModifierOption>[];
      final optionSummaries = _optionSummaries(options);
      final addonTotal = options.fold<double>(0, (sum, opt) => sum + opt.price);
      modifiers.add(
        _modifierPayload(
          groupId: entry.key,
          optionIds: entry.value,
          optionSummaries: optionSummaries,
          addonTotal: addonTotal,
          pricingSnapshot: i == 0 ? pricingSnapshot : null,
        ),
      );
    }
    return modifiers;
  }

  static SaleDraftModifierInputDto _modifierPayload({
    required String groupId,
    required List<String> optionIds,
    required List<SaleDraftModifierOptionDto> optionSummaries,
    required double addonTotal,
    SalePricingSnapshotDto? pricingSnapshot,
  }) {
    return SaleDraftModifierInputDto(
      groupId: groupId,
      optionIds: optionIds,
      options: optionSummaries,
      priceAdjustmentUsd: addonTotal,
      priceAdjustmentUsdTotal: addonTotal != 0 ? addonTotal : null,
      pricingSnapshot: pricingSnapshot,
    );
  }
}
