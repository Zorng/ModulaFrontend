import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';

class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.showState = true,
  });

  final StockItem item;
  final VoidCallback onTap;
  final bool showState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 3,
        color: Colors.white,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InventoryItemImage(label: item.name, imageUrl: item.imageUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _pieceLabel(item),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (showState)
                      InventoryStatePill(
                        state: item.onHand == 0
                            ? InventoryStockState.outOfStock
                            : item.isLowStock
                            ? InventoryStockState.lowStock
                            : InventoryStockState.healthy,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ...onHandLines.map(
                    (line) => Text(
                      line,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
        ),
      ),
    );
  }
}

String _pieceLabel(StockItem item) {
  if (item.pieceSize <= 1) return item.baseUnit;
  return '${item.pieceSize} ${item.baseUnit} per piece';
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

class InventoryStatePill extends StatelessWidget {
  const InventoryStatePill({super.key, required this.state});

  final InventoryStockState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (state) {
      InventoryStockState.lowStock => scheme.errorContainer,
      InventoryStockState.outOfStock => scheme.error,
      InventoryStockState.healthy => scheme.secondaryContainer,
    };
    final textColor = switch (state) {
      InventoryStockState.lowStock => scheme.onErrorContainer,
      InventoryStockState.outOfStock => scheme.onError,
      InventoryStockState.healthy => scheme.onSecondaryContainer,
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_stateIcon(state), size: 14, color: textColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _stateLabel(state),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stateLabel(InventoryStockState state) => switch (state) {
    InventoryStockState.healthy => 'Healthy',
    InventoryStockState.lowStock => 'Low stock',
    InventoryStockState.outOfStock => 'Out of stock',
  };

  IconData _stateIcon(InventoryStockState state) => switch (state) {
    InventoryStockState.healthy => Icons.check_circle,
    InventoryStockState.lowStock => Icons.warning_amber,
    InventoryStockState.outOfStock => Icons.error_outline,
  };
}

class InventoryItemImage extends StatelessWidget {
  const InventoryItemImage({super.key, required this.label, this.imageUrl});

  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trimmed = label.trim();
    final initials = trimmed.isNotEmpty
        ? trimmed.substring(0, 1).toUpperCase()
        : '?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _InitialsPlaceholder(initials: initials, scheme: scheme),
              )
            : _InitialsPlaceholder(initials: initials, scheme: scheme),
      ),
    );
  }
}

enum InventoryStockState { healthy, lowStock, outOfStock }

class _InitialsPlaceholder extends StatelessWidget {
  const _InitialsPlaceholder({required this.initials, required this.scheme});

  final String initials;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.secondaryContainer,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
