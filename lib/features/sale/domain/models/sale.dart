class Sale {
  const Sale({
    required this.id,
    required this.saleType,
    required this.state,
    required this.fulfillmentStatus,
    required this.paymentMethod,
    required this.tenderCurrency,
    required this.fxRateUsed,
    required this.subtotalUsdExact,
    required this.subtotalKhrExact,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.cashReceivedUsd,
    required this.cashReceivedKhr,
    required this.changeGivenUsd,
    required this.changeGivenKhr,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  final String id;
  final String saleType;
  final String state;
  final String fulfillmentStatus;
  final String paymentMethod;
  final String tenderCurrency;
  final double fxRateUsed;
  final double subtotalUsdExact;
  final double subtotalKhrExact;
  final double totalUsdExact;
  final double totalKhrExact;
  final double? cashReceivedUsd;
  final double? cashReceivedKhr;
  final double? changeGivenUsd;
  final double? changeGivenKhr;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SaleItem> items;
}

class SaleItem {
  const SaleItem({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.modifiers,
  });

  final String id;
  final String menuItemId;
  final String menuItemName;
  final int quantity;
  final List<SaleModifier> modifiers;
}

class SaleModifier {
  const SaleModifier({
    required this.groupId,
    required this.optionIds,
    required this.optionLabels,
  });

  final String groupId;
  final List<String> optionIds;
  final List<String> optionLabels;
}

class SaleCheckoutSummary {
  const SaleCheckoutSummary({
    required this.saleId,
    required this.tenderCurrency,
    required this.paymentMethod,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.cashReceivedUsd,
    required this.cashReceivedKhr,
    required this.changeGivenUsd,
    required this.changeGivenKhr,
  });

  final String saleId;
  final String tenderCurrency;
  final String paymentMethod;
  final double totalUsdExact;
  final double totalKhrExact;
  final double cashReceivedUsd;
  final double cashReceivedKhr;
  final double changeGivenUsd;
  final double changeGivenKhr;
}

