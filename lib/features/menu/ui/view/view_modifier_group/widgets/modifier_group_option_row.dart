import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class ModifierGroupOptionRow extends StatelessWidget {
  const ModifierGroupOptionRow({
    super.key,
    required this.option,
  });

  final ModifierOption option;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(option.name),
        if (option.price > 0)
          Text(
            '+ \$${option.price.toStringAsFixed(2)}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[700]),
          ),
      ],
    );
  }
}

