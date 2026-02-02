import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';

class RestockStockSummary extends StatelessWidget {
  const RestockStockSummary({super.key, required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current on-hand',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            StockQuantityFormatter(
              baseQty: item.onHand,
              pieceSize: item.pieceSize,
              baseUnit: item.baseUnit,
            ).format(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Min threshold: ${StockQuantityFormatter(baseQty: item.minThreshold, pieceSize: item.pieceSize, baseUnit: item.baseUnit).format()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
