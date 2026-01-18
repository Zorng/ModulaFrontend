import 'package:flutter/material.dart';
import 'package:modular_pos/features/sale/ui/components/quantity_stepper.dart';

class SaleItemDetailBottomBar extends StatelessWidget {
  const SaleItemDetailBottomBar({
    super.key,
    required this.totalUsd,
    required this.quantity,
    required this.onQuantityChanged,
    required this.canAddToCart,
    required this.onAddItem,
    required this.blockingMessage,
  });

  final double totalUsd;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final bool canAddToCart;
  final VoidCallback? onAddItem;
  final String? blockingMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  '\$${totalUsd.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                QuantityStepper(
                  quantity: quantity,
                  onDecrement: quantity > 1
                      ? () => onQuantityChanged(quantity - 1)
                      : null,
                  onIncrement: () => onQuantityChanged(quantity + 1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: canAddToCart ? onAddItem : null,
                      child: const Text('Add Item'),
                    ),
                  ),
                ),
              ],
            ),
            if (!canAddToCart) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      blockingMessage ?? 'Start a cash session to add items.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.right,
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
