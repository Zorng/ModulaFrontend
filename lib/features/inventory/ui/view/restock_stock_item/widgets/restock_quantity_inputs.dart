import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

class RestockQuantityInputs extends StatelessWidget {
  const RestockQuantityInputs({
    super.key,
    required this.item,
    required this.pcsCtrl,
    required this.extraCtrl,
  });

  final StockItem item;
  final TextEditingController pcsCtrl;
  final TextEditingController extraCtrl;

  @override
  Widget build(BuildContext context) {
    if (item.pieceSize <= 1) {
      return TextFormField(
        controller: pcsCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Quantity received (${item.baseUnit})',
        ),
        validator: (value) {
          final parsed = int.tryParse(value ?? '');
          if (parsed == null || parsed <= 0) {
            return 'Enter a quantity greater than 0';
          }
          return null;
        },
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: pcsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Pieces received'),
            validator: (value) {
              final parsed = int.tryParse(value ?? '');
              if (parsed == null || parsed < 0) {
                return 'Enter pcs (0 or more)';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: extraCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Additional ${item.baseUnit}',
            ),
            validator: (value) {
              final parsed = int.tryParse(value ?? '');
              if (parsed == null || parsed < 0) {
                return 'Enter a value ≥ 0';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
