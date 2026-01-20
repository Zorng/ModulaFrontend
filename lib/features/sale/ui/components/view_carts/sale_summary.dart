import 'package:modular_pos/features/sale/domain/models/sale.dart';

class SaleSummary {
  const SaleSummary({
    required this.id,
    required this.state,
    required this.createdAt,
    required this.lines,
  });

  final String id;
  final String state;
  final DateTime createdAt;
  final List<SaleLine> lines;

  factory SaleSummary.fromSale(Sale sale) {
    final lines = sale.items
        .map(
          (item) => SaleLine(
            name: item.menuItemName.isEmpty ? 'Item' : item.menuItemName,
            quantity: item.quantity,
            modifiers: [
              for (final mod in item.modifiers) ...mod.optionLabels,
            ],
          ),
        )
        .toList();
    return SaleSummary(
      id: sale.id,
      state: sale.state,
      createdAt: sale.createdAt,
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
