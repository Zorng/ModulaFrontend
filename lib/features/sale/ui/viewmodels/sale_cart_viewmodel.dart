import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail_page.dart';

class CartLine {
  const CartLine({
    required this.item,
    required this.quantity,
    required this.selectedOptionIds,
  });

  final MenuItem item;
  final int quantity;
  final Map<String, List<String>> selectedOptionIds;

  CartLine copyWith({
    MenuItem? item,
    int? quantity,
    Map<String, List<String>>? selectedOptionIds,
  }) {
    return CartLine(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
    );
  }
}

final saleCartProvider =
    NotifierProvider<SaleCartNotifier, List<CartLine>>(SaleCartNotifier.new);

class SaleCartNotifier extends Notifier<List<CartLine>> {
  @override
  List<CartLine> build() => const [];

  void addSelection(SaleItemSelectionResult selection) {
    // Check if the same item with same selections already exists; if so increment.
    for (var i = 0; i < state.length; i++) {
      final line = state[i];
      if (line.item.id == selection.item.id &&
          _mapsEqual(line.selectedOptionIds, selection.selectedOptionIds)) {
        final updated = line.copyWith(quantity: line.quantity + selection.quantity);
        state = [
          for (var j = 0; j < state.length; j++) if (j == i) updated else state[j],
        ];
        return;
      }
    }
    state = [
      ...state,
      CartLine(
        item: selection.item,
        quantity: selection.quantity,
        selectedOptionIds: selection.selectedOptionIds,
      ),
    ];
  }

  void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= state.length) return;
    if (quantity <= 0) {
      final newState = [...state]..removeAt(index);
      state = newState;
      return;
    }
    final updated = state[index].copyWith(quantity: quantity);
    state = [
      for (var i = 0; i < state.length; i++) if (i == index) updated else state[i],
    ];
  }

  bool _mapsEqual(Map<String, List<String>> a, Map<String, List<String>> b) {
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
}
