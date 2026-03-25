import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/widgets/stock_item_image.dart';

class StockItemCard extends StatelessWidget {
  const StockItemCard({
    super.key,
    required this.item,
    required this.categoryLabel,
    this.onRestore,
  });

  final StockItem item;
  final String categoryLabel;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseUnitValue = _baseUnitValue(item);
    return Card(
      elevation: 3,
      color: Colors.white,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed(
          AppRoute.inventoryStockDetail.name,
          extra: item,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                    ),
                    const SizedBox(height: 8),
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
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Base unit:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      baseUnitValue,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!item.isActive && onRestore != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: onRestore,
                        icon: const Icon(Icons.restore_outlined, size: 18),
                        label: const Text('Restore'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _baseUnitValue(StockItem item) {
  if (item.pieceSize <= 1) {
    return item.baseUnit;
  }
  return '${item.pieceSize} ${item.baseUnit}';
}
