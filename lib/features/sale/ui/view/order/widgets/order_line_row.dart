import 'package:flutter/material.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

class OrderLineRow extends StatelessWidget {
  const OrderLineRow({super.key, required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    final modifierText = line.modifiers.isEmpty
        ? 'No modifiers'
        : line.modifiers.join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${line.quantity}x',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.name, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 2),
              Text(modifierText, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
