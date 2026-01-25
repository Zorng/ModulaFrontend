import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class CartLine {
  const CartLine({
    required this.item,
    required this.quantity,
    required this.selectedOptionIds,
    this.saleItemId,
    this.selectedOptions = const {},
  });

  final MenuItem item;
  final int quantity;
  final Map<String, List<String>> selectedOptionIds;
  final String? saleItemId;
  final Map<String, List<ModifierOption>> selectedOptions;

  CartLine copyWith({
    MenuItem? item,
    int? quantity,
    Map<String, List<String>>? selectedOptionIds,
    String? saleItemId,
    Map<String, List<ModifierOption>>? selectedOptions,
  }) {
    return CartLine(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      saleItemId: saleItemId ?? this.saleItemId,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }
}

class SaleCartState {
  const SaleCartState({
    this.saleId,
    this.saleType = 'take_away',
    this.lines = const [],
    this.tenderCurrency = 'USD',
    this.paymentMethod = 'cash',
    this.cashUsd = 0,
    this.cashKhr = 0,
  });

  final String? saleId;
  final String saleType;
  final List<CartLine> lines;
  final String tenderCurrency;
  final String paymentMethod;
  final double cashUsd;
  final double cashKhr;

  SaleCartState copyWith({
    String? saleId,
    String? saleType,
    List<CartLine>? lines,
    String? tenderCurrency,
    String? paymentMethod,
    double? cashUsd,
    double? cashKhr,
  }) {
    return SaleCartState(
      saleId: saleId ?? this.saleId,
      saleType: saleType ?? this.saleType,
      lines: lines ?? this.lines,
      tenderCurrency: tenderCurrency ?? this.tenderCurrency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashUsd: cashUsd ?? this.cashUsd,
      cashKhr: cashKhr ?? this.cashKhr,
    );
  }
}
