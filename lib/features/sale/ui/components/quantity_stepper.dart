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
    final theme = Theme.of(context);
    final buttonPadding = dense ? const EdgeInsets.all(4) : null;
    final buttonConstraints = dense ? const BoxConstraints() : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[Text(label!), const SizedBox(width: 8)],
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove),
          constraints: buttonConstraints,
          padding: buttonPadding,
        ),
        const SizedBox(width: 20),
        Text('$quantity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 20),
        IconButton(
          onPressed: onIncrement,
          icon: Icon(
            Icons.add,
            color: onIncrement == null
                ? theme.disabledColor
                : theme.colorScheme.primary,
          ),
          constraints: buttonConstraints,
          padding: buttonPadding,
        ),
      ],
    );
  }
}
