import 'package:flutter/material.dart';

class InventoryJournalDateField extends StatelessWidget {
  const InventoryJournalDateField({
    super.key,
    required this.controller,
    required this.label,
    required this.onTap,
    required this.onClear,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.isNotEmpty;
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: hasValue
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
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
    );
  }
}

