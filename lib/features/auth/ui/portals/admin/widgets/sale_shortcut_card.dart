import 'package:flutter/material.dart';

class SaleShortcutCard extends StatelessWidget {
  const SaleShortcutCard({super.key, required this.onOpenSale});

  final VoidCallback onOpenSale;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('POS / Sale', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Launch the sale screen used by cashiers with admin permissions.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onOpenSale,
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Open Sale'),
            ),
          ],
        ),
      ),
    );
  }
}

