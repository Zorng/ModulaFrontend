import 'package:flutter/material.dart';

import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_field_label.dart';

class AdjustQuantityInputs extends StatelessWidget {
  const AdjustQuantityInputs({
    super.key,
    required this.item,
    required this.pcsCtrl,
    required this.baseCtrl,
    required this.mode,
    this.errorText,
  });

  final StockItem item;
  final TextEditingController pcsCtrl;
  final TextEditingController baseCtrl;
  final AdjustQuantityInputMode mode;
  final String? errorText;

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
      return InventoryFieldLabel(
        text: '$quantityLabel (${item.baseUnit})',
        isRequired: true,
        child: TextFormField(
          controller: baseCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter ${item.baseUnit} quantity',
            errorText: errorText,
            errorMaxLines: 3,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InventoryFieldLabel(
                text: pieceLabel,
                isRequired: true,
                child: TextFormField(
                  controller: pcsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Enter pieces'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InventoryFieldLabel(
                text: extraLabel,
                child: TextFormField(
                  controller: baseCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter additional ${item.baseUnit}',
                  ),
                ),
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            softWrap: true,
            maxLines: 3,
            overflow: TextOverflow.visible,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

enum AdjustQuantityInputMode { delta, setToCount }
