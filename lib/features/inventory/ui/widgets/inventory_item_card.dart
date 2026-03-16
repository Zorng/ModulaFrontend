import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/widgets/stock_item_image.dart';

class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    super.key,
    required this.item,
    required this.categoryLabel,
    this.onAdjust,
    this.onViewHistory,
  });

  final StockItem item;
  final String categoryLabel;
  final VoidCallback? onAdjust;
  final VoidCallback? onViewHistory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonTextStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    final viewHistoryButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: AppTableTheme.actionButtonColor,
      side: const BorderSide(color: AppTableTheme.actionButtonColor),
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: buttonTextStyle,
    );
    final formatter = StockQuantityFormatter(
      baseQty: item.onHand,
      pieceSize: item.pieceSize,
      baseUnit: item.baseUnit,
    );
    final onHandLines = _quantityLines(formatter);
    final minText = StockQuantityFormatter(
      baseQty: item.minThreshold,
      pieceSize: item.pieceSize,
      baseUnit: item.baseUnit,
    ).format();
    return Card(
      elevation: 3,
      color: Colors.white,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StockItemImage(imageUrl: item.imageUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: AppTableTheme.categoryPillDecoration,
                        child: Text(
                          categoryLabel,
                          style: AppTableTheme.categoryPillText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ...onHandLines.map(
                      (line) => Text(
                        line,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(
                              color: item.isLowStock ? colorScheme.error : null,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    ..._minLines(minText).map(
                      (line) => Text(
                        line,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (onAdjust != null || onViewHistory != null) ...[
              const SizedBox(height: 22),
              Row(
                children: [
                  if (onAdjust != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: onAdjust,
                        child: const Text('Adjust'),
                      ),
                    ),
                  if (onAdjust != null && onViewHistory != null)
                    const SizedBox(width: 12),
                  if (onViewHistory != null)
                    Expanded(
                      child: OutlinedButton(
                        style: viewHistoryButtonStyle,
                        onPressed: onViewHistory,
                        child: const Text('View history'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

List<String> _quantityLines(StockQuantityFormatter formatter) {
  if (formatter.pieceSize <= 1) {
    return ['${formatter.baseQty} ${formatter.baseUnit}'];
  }
  final lines = <String>[];
  if (formatter.pcs > 0) {
    lines.add('${formatter.pcs} pcs');
  }
  if (formatter.remainder > 0) {
    lines.add('${formatter.remainder} ${formatter.baseUnit}');
  }
  if (lines.isEmpty) {
    lines.add('0 ${formatter.baseUnit}');
  }
  return lines;
}

List<String> _minLines(String formatted) {
  if (!formatted.contains('+')) {
    return ['Min $formatted'];
  }
  final parts = formatted.split('+').map((part) => part.trim()).toList();
  return ['Min ${parts.first}', if (parts.length > 1) parts[1]];
}
