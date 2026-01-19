import 'package:flutter/material.dart';

import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

class AdjustQuantityInputs extends StatelessWidget {
  const AdjustQuantityInputs({
    super.key,
    required this.item,
    required this.pcsCtrl,
    required this.baseCtrl,
  });

  final StockItem item;
  final TextEditingController pcsCtrl;
  final TextEditingController baseCtrl;

  @override
  Widget build(BuildContext context) {
    if (item.pieceSize <= 1) {
      return TextFormField(
        controller: baseCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Quantity (${item.baseUnit})',
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
            decoration: const InputDecoration(
              labelText: 'Pieces',
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
              labelText: 'Extra (${item.baseUnit})',
              hintText: 'Optional remainder',
            ),
          ),
        ),
      ],
    );
  }
}

