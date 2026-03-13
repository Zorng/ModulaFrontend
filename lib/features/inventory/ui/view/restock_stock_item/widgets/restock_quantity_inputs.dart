import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_field_label.dart';

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
      return InventoryFieldLabel(
        text: 'Quantity received (${item.baseUnit})',
        isRequired: true,
        child: TextFormField(
          controller: pcsCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter ${item.baseUnit} quantity',
          ),
          validator: (value) {
            final parsed = int.tryParse(value ?? '');
            if (parsed == null || parsed <= 0) {
              return 'Enter a quantity greater than 0';
            }
            return null;
          },
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: InventoryFieldLabel(
            text: 'Pieces received',
            isRequired: true,
            child: TextFormField(
              controller: pcsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter pieces'),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return null;
                final parsed = int.tryParse(trimmed);
                if (parsed == null || parsed < 0) {
                  return 'Enter pcs (0 or more)';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InventoryFieldLabel(
            text: 'Additional ${item.baseUnit}',
            child: TextFormField(
              controller: extraCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter additional ${item.baseUnit}',
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return null;
                final parsed = int.tryParse(trimmed);
                if (parsed == null || parsed < 0) {
                  return 'Enter a value ≥ 0';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }
}
