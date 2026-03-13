import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/media/product_image.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/sale/ui/components/quantity_stepper.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';

class SaleCartItemRow extends StatelessWidget {
  const SaleCartItemRow({
    super.key,
    required this.item,
    required this.groupLookup,
    this.onIncrement,
    this.onDecrement,
  });

  final CartLine item;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final Map<String, ModifierGroup> groupLookup;

  double _lineTotal() {
    double addons = 0;
    item.selectedOptionIds.forEach((groupId, optionIds) {
      final group = groupLookup[groupId];
      if (group == null) return;
      for (final id in optionIds) {
        final opt = group.options.firstWhere(
          (o) => o.id == id,
          orElse: () => const ModifierOption(id: '', name: '', price: 0),
        );
        addons += opt.price;
      }
    });
    return (item.item.price + addons) * item.quantity;
  }

  @override
  Widget build(BuildContext context) {
    final optionNames = <String>[];
    item.selectedOptionIds.forEach((groupId, optionIds) {
      final group = groupLookup[groupId];
      if (group == null) return;
      for (final id in optionIds) {
        final opt = group.options.firstWhere(
          (o) => o.id == id,
          orElse: () => const ModifierOption(id: '', name: '', price: 0),
        );
        if (opt.id.isNotEmpty) optionNames.add(opt.name);
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: ProductImage(
                imagePath: item.item.imageUrl,
                borderRadius: 8,
                placeholderIcon: Icons.fastfood_outlined,
                showPlaceholderLabel: false,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  optionNames.isNotEmpty
                      ? optionNames.join(', ')
                      : 'No modifiers',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              QuantityStepper(
                label: null,
                dense: true,
                quantity: item.quantity,
                onDecrement: onDecrement,
                onIncrement: onIncrement,
              ),
              const SizedBox(height: 4),
              Text(
                '\$${_lineTotal().toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
