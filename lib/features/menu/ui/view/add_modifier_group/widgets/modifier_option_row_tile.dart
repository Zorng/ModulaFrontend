import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group/add_modifier_group_models.dart';

class ModifierOptionRowTile extends StatelessWidget {
  const ModifierOptionRowTile({
    super.key,
    required this.option,
    required this.requiresPriceInput,
    required this.isSingleSelection,
    required this.isDefaultSelected,
    required this.onRemove,
    required this.onChanged,
    required this.onDefaultSelected,
  });

  final ModifierOptionRowModel option;
  final bool requiresPriceInput;
  final bool isSingleSelection;
  final bool isDefaultSelected;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final VoidCallback onDefaultSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: onRemove,
            tooltip: 'Remove option',
          ),
          Expanded(
            flex: 4,
            child: TextField(
              controller: option.nameController,
              decoration: InputDecoration(
                hintText: 'Option Label',
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
                labelText: 'Option Label *',
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          if (requiresPriceInput) ...[
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(
                    '+ \$ ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Expanded(
                    child: TextField(
                      controller: option.priceController,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isSingleSelection) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDefaultSelected,
              icon: Icon(
                isDefaultSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              color: isDefaultSelected ? Theme.of(context).primaryColor : null,
              tooltip: 'Set as default',
            ),
          ],
        ],
      ),
    );
  }
}

