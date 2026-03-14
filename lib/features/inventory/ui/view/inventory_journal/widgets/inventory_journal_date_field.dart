import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_field_label.dart';

class InventoryJournalDateField extends StatelessWidget {
  const InventoryJournalDateField({
    super.key,
    required this.controller,
    required this.label,
    required this.onTap,
    required this.onClear,
    this.allowClear = true,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    final hasValue = allowClear && controller.text.isNotEmpty;
    return InventoryFieldLabel(
      text: label,
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Select date',
          suffixIcon: hasValue
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: onTap,
                    ),
                  ],
                )
              : IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: onTap,
                ),
        ),
        onTap: onTap,
      ),
    );
  }
}
