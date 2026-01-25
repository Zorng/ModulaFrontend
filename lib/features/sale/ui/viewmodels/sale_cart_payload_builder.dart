import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
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

  static AddItemPayload fromSelection(SaleItemSelectionResult selection) {
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

    return AddItemPayload(
      modifiers: modifiers,
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: lineTotalUsdExact,
      addonTotalUsd: addonTotalUsd,
      pricingSnapshot: pricingSnapshot,
    );
  }

  static AddItemPayload fromLine(CartLine line) {
    double addonTotalUsd = 0;
    final entries = line.selectedOptionIds.entries.toList();
    final modifiers = <Map<String, dynamic>>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final options =
          line.selectedOptions[entry.key] ?? const <ModifierOption>[];
      final optionSummaries = _optionSummaries(options);
      final addonTotal = options.fold<double>(0, (sum, opt) => sum + opt.price);
      addonTotalUsd += addonTotal;
      modifiers.add(
        _modifierPayload(
          groupId: entry.key,
          optionIds: entry.value,
          optionSummaries: optionSummaries,
          addonTotal: addonTotal,
        ),
      );
    }

    final unitPriceUsd = line.item.price + addonTotalUsd;
    final lineTotalUsdExact = unitPriceUsd * line.quantity;
    final pricingSnapshot = _pricingSnapshot(
      basePrice: line.item.price,
      addonTotalUsd: addonTotalUsd,
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: lineTotalUsdExact,
    );

    if (modifiers.isNotEmpty) {
      modifiers.first['pricingSnapshot'] = pricingSnapshot;
    } else {
      modifiers.add({'pricingSnapshot': pricingSnapshot});
    }

    return AddItemPayload(
      modifiers: modifiers,
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: lineTotalUsdExact,
      addonTotalUsd: addonTotalUsd,
      pricingSnapshot: pricingSnapshot,
    );
  }

  static Map<String, dynamic> _pricingSnapshot({
    required double basePrice,
    required double addonTotalUsd,
    required double unitPriceUsd,
    required double lineTotalUsdExact,
  }) {
    return {
      'baseUnitPriceUsd': basePrice,
      'addonTotalUsd': addonTotalUsd,
      'unitPriceUsd': unitPriceUsd,
      'lineTotalUsdExact': lineTotalUsdExact,
    };
  }

  static List<Map<String, dynamic>> _buildModifiersFromSelection(
    Map<String, List<String>> selectedOptionIds,
    Map<String, List<ModifierOption>> selectedOptions,
    Map<String, dynamic> pricingSnapshot,
  ) {
    final modifiers = <Map<String, dynamic>>[];
    final entries = selectedOptionIds.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final options =
          selectedOptions[entry.key] ?? const <ModifierOption>[];
      final optionSummaries = _optionSummaries(options);
      final addonTotal = options.fold<double>(0, (sum, opt) => sum + opt.price);
      final modifierPayload = _modifierPayload(
        groupId: entry.key,
        optionIds: entry.value,
        optionSummaries: optionSummaries,
        addonTotal: addonTotal,
      );
      if (i == 0) {
        modifierPayload['pricingSnapshot'] = pricingSnapshot;
      }
      modifiers.add(modifierPayload);
    }
    if (modifiers.isEmpty) {
      modifiers.add({'pricingSnapshot': pricingSnapshot});
    }
    return modifiers;
  }

  static List<Map<String, dynamic>> _optionSummaries(
    List<ModifierOption> options,
  ) {
    return options
        .map(
          (opt) => {
            'id': opt.id,
            'label': opt.name,
            'priceAdjustmentUsd': opt.price,
            'isDefault': opt.isDefault,
          },
        )
        .toList();
  }

  static Map<String, dynamic> _modifierPayload({
    required String groupId,
    required List<String> optionIds,
    required List<Map<String, dynamic>> optionSummaries,
    required double addonTotal,
  }) {
    return <String, dynamic>{
      'groupId': groupId,
      'optionIds': optionIds,
      if (optionSummaries.isNotEmpty) 'options': optionSummaries,
      // Backend saleEntity expects priceAdjustmentUsd at the modifier level.
      'priceAdjustmentUsd': addonTotal,
      if (addonTotal != 0) 'priceAdjustmentUsdTotal': addonTotal,
    };
  }
}

class AddItemPayload {
  AddItemPayload({
    required this.modifiers,
    required this.unitPriceUsd,
    required this.lineTotalUsdExact,
    required this.addonTotalUsd,
    required this.pricingSnapshot,
  });

  final List<Map<String, dynamic>> modifiers;
  final double unitPriceUsd;
  final double lineTotalUsdExact;
  final double addonTotalUsd;
  final Map<String, dynamic> pricingSnapshot;
}
