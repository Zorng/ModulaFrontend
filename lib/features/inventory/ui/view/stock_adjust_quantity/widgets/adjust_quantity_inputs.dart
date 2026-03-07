import 'package:flutter/material.dart';

import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

class AdjustQuantityInputs extends StatelessWidget {
  const AdjustQuantityInputs({
    super.key,
    required this.item,
    required this.pcsCtrl,
    required this.baseCtrl,
    required this.mode,
  });

  final StockItem item;
  final TextEditingController pcsCtrl;
  final TextEditingController baseCtrl;
  final AdjustQuantityInputMode mode;

  @override
  Widget build(BuildContext context) {
    final quantityLabel = switch (mode) {
      AdjustQuantityInputMode.delta => 'Adjustment quantity',
      AdjustQuantityInputMode.setToCount => 'Counted on-hand quantity',
    };
    final pieceLabel = switch (mode) {
      AdjustQuantityInputMode.delta => 'Pieces to adjust',
      AdjustQuantityInputMode.setToCount => 'Counted pieces',
    };
    final extraLabel = switch (mode) {
      AdjustQuantityInputMode.delta => 'Additional ${item.baseUnit}',
      AdjustQuantityInputMode.setToCount =>
        'Additional counted ${item.baseUnit}',
    };
    if (item.pieceSize <= 1) {
      return TextFormField(
        controller: baseCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: '$quantityLabel (${item.baseUnit})',
          hintText: 'Enter amount',
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: pcsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: pieceLabel,
              hintText: 'e.g., number of cartons',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: baseCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: extraLabel,
              hintText: 'Optional remainder',
            ),
          ),
        ),
      ],
    );
  }
}

enum AdjustQuantityInputMode { delta, setToCount }
