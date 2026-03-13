import 'package:modular_pos/features/sale/domain/models/sale.dart';

class SaleSummary {
  const SaleSummary({
    required this.id,
    required this.state,
    required this.fulfillmentStatus,
    required this.paymentMethod,
    required this.tenderCurrency,
    required this.createdAt,
    required this.updatedAt,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.cashReceivedUsd,
    required this.cashReceivedKhr,
    required this.changeGivenUsd,
    required this.changeGivenKhr,
    required this.lines,
  });

  final String id;
  final String state;
  final String fulfillmentStatus;
  final String paymentMethod;
  final String tenderCurrency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double totalUsdExact;
  final double totalKhrExact;
  final double? cashReceivedUsd;
  final double? cashReceivedKhr;
  final double? changeGivenUsd;
  final double? changeGivenKhr;
  final List<SaleLine> lines;

  bool get canVoid => state.trim().toUpperCase() == 'PENDING';

  factory SaleSummary.fromSale(Sale sale) {
    final lines = sale.items
        .map(
          (item) => SaleLine(
            name: item.menuItemName.isEmpty ? 'Item' : item.menuItemName,
            quantity: item.quantity,
            modifiers: [for (final mod in item.modifiers) ...mod.optionLabels],
          ),
        )
        .toList();
    return SaleSummary(
      id: sale.id,
      state: sale.state,
      fulfillmentStatus: sale.fulfillmentStatus,
      paymentMethod: sale.paymentMethod,
      tenderCurrency: sale.tenderCurrency,
      createdAt: sale.createdAt,
      updatedAt: sale.updatedAt,
      totalUsdExact: sale.totalUsdExact,
      totalKhrExact: sale.totalKhrExact,
      cashReceivedUsd: sale.cashReceivedUsd,
      cashReceivedKhr: sale.cashReceivedKhr,
      changeGivenUsd: sale.changeGivenUsd,
      changeGivenKhr: sale.changeGivenKhr,
      lines: lines,
    );
  }
}

class SaleLine {
  const SaleLine({
    required this.name,
    required this.quantity,
    required this.modifiers,
  });

  final String name;
  final int quantity;
  final List<String> modifiers;
}
