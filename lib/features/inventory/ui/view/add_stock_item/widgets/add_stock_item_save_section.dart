import 'package:flutter/material.dart';

class AddStockItemSaveSection extends StatelessWidget {
  const AddStockItemSaveSection({super.key, required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onSave, child: const Text('Save item'));
  }
}
