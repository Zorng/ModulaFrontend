import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/sale/ui/components/quantity_stepper.dart';

class SaleItemDetailBottomBar extends StatelessWidget {
  const SaleItemDetailBottomBar({
    super.key,
    required this.basePrice,
    required this.addonTotal,
    required this.totalUsd,
    required this.quantity,
    required this.selectedOptions,
    required this.onQuantityChanged,
    required this.canAddToCart,
    required this.onAddItem,
    required this.blockingMessage,
    this.showPriceBreakdown = true,
  });

  final double basePrice;
  final double addonTotal;
  final double totalUsd;
  final int quantity;
  final Map<String, List<ModifierOption>> selectedOptions;
  final ValueChanged<int> onQuantityChanged;
  final bool canAddToCart;
  final VoidCallback? onAddItem;
  final String? blockingMessage;
  final bool showPriceBreakdown;

  @override
  Widget build(BuildContext context) {
    // Build list of selected modifiers with prices
    final pricedAddons = <MapEntry<String, double>>[];
    selectedOptions.forEach((groupId, options) {
      for (final option in options) {
        if (option.price > 0) {
          pricedAddons.add(MapEntry(option.name, option.price));
        }
      }
    });

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            // Quantity selector at the top
            Row(
              children: [
                Text('Quantity', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                QuantityStepper(
                  quantity: quantity,
                  onDecrement: quantity > 1
                      ? () => onQuantityChanged(quantity - 1)
                      : null,
                  onIncrement: () => onQuantityChanged(quantity + 1),
                ),
              ],
            ),
            if (showPriceBreakdown) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Price breakdown
              Row(
                children: [
                  Text(
                    'Based Price',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${basePrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              // Show priced add-ons
              ...pricedAddons.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Text(
                        '+ ${entry.key}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '+ \$${entry.value.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Total
              Row(
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${totalUsd.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Add to cart button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canAddToCart ? onAddItem : null,
                child: const Text('Add to Cart'),
              ),
            ),
            if (!canAddToCart) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
            if (canAddToCart) ...[
              const SizedBox(height: 8),
              Text(
                'Please select all required modifiers before adding to cart.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
