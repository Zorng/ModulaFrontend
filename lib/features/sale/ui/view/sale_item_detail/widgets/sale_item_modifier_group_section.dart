import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class SaleItemModifierGroupSection extends StatelessWidget {
  const SaleItemModifierGroupSection({
    super.key,
    required this.group,
    required this.selectedOptionIds,
    required this.onSelectionChanged,
  });

  final ModifierGroup group;
  final Set<String> selectedOptionIds;
  final ValueChanged<Set<String>> onSelectionChanged;

  bool get _isSingle => group.selectionType == 'single';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(group.name, style: Theme.of(context).textTheme.titleMedium),
              if (group.isRequired == true) ...[
                const SizedBox(width: 8),
                Chip(
                  label: const Text('Required'),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (_isSingle)
            RadioGroup<String>(
              groupValue: selectedOptionIds.isNotEmpty
                  ? selectedOptionIds.first
                  : null,
              onChanged: (value) {
                if (value == null) return;
                onSelectionChanged({value});
              },
              child: Column(
                children: [
                  ...group.options.map((option) {
                    final isSelected = selectedOptionIds.contains(option.id);
                    final priceDelta = option.price;
                    final priceLabel = priceDelta == 0
                        ? ''
                        : ' (+\$${priceDelta.toStringAsFixed(2)})';
                    final highlightColor = Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? highlightColor : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RadioListTile<String>(
                          value: option.id,
                          title: Text('${option.name}$priceLabel'),
                          dense: true,
                          contentPadding: const EdgeInsets.only(
                            left: 4,
                            right: 8,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            )
          else
            ...group.options.map((option) {
              final isSelected = selectedOptionIds.contains(option.id);
              final priceDelta = option.price;
              final priceLabel = priceDelta == 0
                  ? ''
                  : ' (+\$${priceDelta.toStringAsFixed(2)})';
              final highlightColor = Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? highlightColor : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 4, right: 8),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('${option.name}$priceLabel'),
                    onChanged: (checked) {
                      final updated = {...selectedOptionIds};
                      if (checked == true) {
                        updated.add(option.id);
                      } else {
                        updated.remove(option.id);
                      }
                      onSelectionChanged(updated);
                    },
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
