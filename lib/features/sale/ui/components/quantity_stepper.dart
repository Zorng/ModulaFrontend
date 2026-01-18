import 'package:flutter/material.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
    this.label = 'Qty',
    this.dense = false,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final String? label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final buttonPadding = dense ? const EdgeInsets.all(4) : null;
    final buttonConstraints = dense ? const BoxConstraints() : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[Text(label!), const SizedBox(width: 8)],
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove_circle_outline),
          constraints: buttonConstraints,
          padding: buttonPadding,
        ),
        Text('$quantity', style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add_circle_outline),
          constraints: buttonConstraints,
          padding: buttonPadding,
        ),
      ],
    );
  }
}
