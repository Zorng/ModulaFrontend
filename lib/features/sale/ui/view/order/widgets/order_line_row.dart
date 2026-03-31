import 'package:flutter/material.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

class OrderLineRow extends StatelessWidget {
  const OrderLineRow({
    super.key,
    required this.line,
    this.quantityStyle,
    this.nameStyle,
    this.modifierStyle,
    this.maxNameLines = 1,
    this.maxModifierLines = 1,
  });

  final OrderLine line;
  final TextStyle? quantityStyle;
  final TextStyle? nameStyle;
  final TextStyle? modifierStyle;
  final int maxNameLines;
  final int maxModifierLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modifierText = line.modifiers.isEmpty
        ? 'No modifiers'
        : line.modifiers.join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${line.quantity}x',
          style: quantityStyle ?? theme.textTheme.titleMedium,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.name,
                maxLines: maxNameLines,
                overflow: TextOverflow.ellipsis,
                style: nameStyle ?? theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 2),
              Text(
                modifierText,
                maxLines: maxModifierLines,
                overflow: TextOverflow.ellipsis,
                style: modifierStyle ?? theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
