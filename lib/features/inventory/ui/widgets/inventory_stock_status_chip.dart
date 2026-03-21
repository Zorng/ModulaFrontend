import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

enum InventoryStockDisplayStatus { inStock, low, out }

InventoryStockDisplayStatus inventoryStockDisplayStatus(StockItem item) {
  if (item.onHand <= 0) return InventoryStockDisplayStatus.out;
  if (item.onHand <= item.minThreshold) return InventoryStockDisplayStatus.low;
  return InventoryStockDisplayStatus.inStock;
}

class InventoryStockStatusChip extends StatelessWidget {
  const InventoryStockStatusChip({super.key, required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(context, inventoryStockDisplayStatus(item));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.borderColor),
      ),
      child: Text(
        style.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: style.textColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

_InventoryStockStatusStyle _statusStyle(
  BuildContext context,
  InventoryStockDisplayStatus status,
) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (status) {
    InventoryStockDisplayStatus.inStock => const _InventoryStockStatusStyle(
      label: 'In stock',
      backgroundColor: Color(0xFFE4F6EA),
      borderColor: Color(0xFFC2E8CF),
      textColor: Color(0xFF1E8E5A),
    ),
    InventoryStockDisplayStatus.low => const _InventoryStockStatusStyle(
      label: 'Low',
      backgroundColor: Color(0xFFFFF4D9),
      borderColor: Color(0xFFF2D48A),
      textColor: Color(0xFFAD7A00),
    ),
    InventoryStockDisplayStatus.out => _InventoryStockStatusStyle(
      label: 'Out',
      backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
      borderColor: colorScheme.primary.withValues(alpha: 0.24),
      textColor: colorScheme.primary,
    ),
  };
}

class _InventoryStockStatusStyle {
  const _InventoryStockStatusStyle({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
}
