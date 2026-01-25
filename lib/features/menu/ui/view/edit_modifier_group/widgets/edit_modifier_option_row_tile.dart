import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/ui/view/edit_modifier_group/edit_modifier_group_models.dart';
import 'package:modular_pos/features/menu/ui/view/edit_modifier_group/widgets/default_selector_button.dart';

class EditModifierOptionRowTile extends StatelessWidget {
  const EditModifierOptionRowTile({
    super.key,
    required this.option,
    required this.requiresPriceInput,
    required this.isSingleSelection,
    required this.isDefaultSelected,
    required this.onRemove,
    required this.onDefaultSelected,
  });

  final EditModifierOptionRowModel option;
  final bool requiresPriceInput;
  final bool isSingleSelection;
  final bool isDefaultSelected;
  final VoidCallback onRemove;
  final VoidCallback onDefaultSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove option',
          ),
          const SizedBox(width: 8),
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
              ),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isSingleSelection) ...[
            const SizedBox(width: 8),
            DefaultSelectorButton(
              isSelected: isDefaultSelected,
              onPressed: onDefaultSelected,
            ),
          ],
        ],
      ),
    );
  }
}

