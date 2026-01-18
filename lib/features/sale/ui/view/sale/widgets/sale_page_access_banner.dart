import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SalePageAccessBanner extends StatelessWidget {
  const SalePageAccessBanner({super.key, required this.cashSessionPath});

  final String cashSessionPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Read-only: start a cash session to add items and checkout.',
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            height: 40,
            child: FilledButton(
              onPressed: () => context.push(cashSessionPath),
              child: const Text('Cash session'),
            ),
          ),
        ],
      ),
    );
  }
}
