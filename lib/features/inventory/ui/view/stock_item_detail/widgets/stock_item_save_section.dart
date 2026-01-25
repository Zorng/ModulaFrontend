import 'package:flutter/material.dart';

class StockItemSaveSection extends StatelessWidget {
  const StockItemSaveSection({
    super.key,
    required this.onSave,
  });

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: FilledButton(
        onPressed: onSave,
        child: const Text('Save changes'),
      ),
    );
  }
}
