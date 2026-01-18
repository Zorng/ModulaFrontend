import 'package:flutter/material.dart';

class SaleOrderTypeSelector extends StatelessWidget {
  const SaleOrderTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: [
        _OrderTypeChip(
          label: 'Dine in',
          value: 'dine_in',
          selected: value == 'dine_in',
          onSelected: enabled ? () => onChanged('dine_in') : null,
        ),
        _OrderTypeChip(
          label: 'Take away',
          value: 'take_away',
          selected: value == 'take_away',
          onSelected: enabled ? () => onChanged('take_away') : null,
        ),
        _OrderTypeChip(
          label: 'Delivery',
          value: 'delivery',
          selected: value == 'delivery',
          onSelected: enabled ? () => onChanged('delivery') : null,
        ),
      ],
    );
  }
}

class _OrderTypeChip extends StatelessWidget {
  const _OrderTypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected == null ? null : (_) => onSelected!(),
    );
  }
}
