import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';

class AddStockItemUsageSection extends StatelessWidget {
  const AddStockItemUsageSection({
    super.key,
    required this.typeOptions,
    required this.selectedTypes,
    required this.onToggleType,
  });

  final List<String> typeOptions;
  final Set<String> selectedTypes;
  final void Function(String type, bool selected) onToggleType;

  @override
  Widget build(BuildContext context) {
    return InventorySectionCard(
      title: 'Item usage',
      children: [
        ...typeOptions.map(
          (type) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(type),
            value: selectedTypes.contains(type),
            onChanged: (value) => onToggleType(type, value ?? false),
          ),
        ),
      ],
    );
  }
}
