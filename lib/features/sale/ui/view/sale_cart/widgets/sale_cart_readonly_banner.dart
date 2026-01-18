import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SaleCartReadOnlyBanner extends StatelessWidget {
  const SaleCartReadOnlyBanner({
    super.key,
    required this.message,
    required this.cashSessionPath,
  });

  final String message;
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
          Expanded(child: Text(message)),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () => context.push(cashSessionPath),
            child: const Text('Cash session'),
          ),
        ],
      ),
    );
  }
}
