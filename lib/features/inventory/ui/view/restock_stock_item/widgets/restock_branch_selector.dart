import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_field_label.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';

class RestockBranchSelector extends StatelessWidget {
  const RestockBranchSelector({
    super.key,
    required this.entries,
    required this.selectedBranchId,
    required this.onChanged,
  });

  final List<MapEntry<String, String>> entries;
  final String? selectedBranchId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // If there are no branch entries, show a non-interactive label instead of
    // trying to access entries.first which would throw.
    if (entries.isEmpty) {
      return const InventoryFieldLabel(
        text: 'Branch',
        isRequired: true,
        child: SizedBox(
          width: double.infinity,
          child: InputDecorator(
            decoration: InputDecoration(),
            child: Text('No branches available'),
          ),
        ),
      );
    }

    return FormField<String>(
      validator: (_) =>
          selectedBranchId == null ? 'Please select a branch' : null,
      builder: (state) => InventoryFieldLabel(
        text: 'Branch',
        isRequired: true,
        child: SizedBox(
          width: double.infinity,
          child: InventoryDropdown<String>(
            initialValue: selectedBranchId,
            hintText: 'Select branch',
            entries: entries
                .map(
                  (entry) =>
                      DropdownMenuEntry(value: entry.key, label: entry.value),
                )
                .toList(),
            onSelected: (value) {
              state.didChange(value);
              onChanged(value);
            },
            errorText: state.errorText,
          ),
        ),
      ),
    );
  }
}
