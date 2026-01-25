import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';

class RestockBranchSelector extends StatelessWidget {
  const RestockBranchSelector({
    super.key,
    required this.entries,
    required this.selectedBranchId,
    required this.onChanged,
    this.enabled = true,
  });

  final List<MapEntry<String, String>> entries;
  final String? selectedBranchId;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      final label = entries
          .firstWhere(
            (entry) => entry.key == selectedBranchId,
            orElse: () => entries.first,
          )
          .value;
      return SizedBox(
        width: double.infinity,
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Branch'),
          child: Text(label),
        ),
      );
    }

    return FormField<String>(
      validator: (_) => selectedBranchId == null ? 'Please select a branch' : null,
      builder: (state) => SizedBox(
        width: double.infinity,
        child: InventoryDropdown<String>(
          initialValue: selectedBranchId,
          label: const Text('Branch'),
          entries: entries
              .map((entry) => DropdownMenuEntry(value: entry.key, label: entry.value))
              .toList(),
          onSelected: (value) {
            state.didChange(value);
            onChanged(value);
          },
          errorText: state.errorText,
        ),
      ),
    );
  }
}

