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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 350;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 10),
                        Expanded(child: Text(message)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => context.push(cashSessionPath),
                      child: const Text('Cash session'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 10),
                    Expanded(child: Text(message)),
                    const SizedBox(width: 12),
                    Flexible(
                      fit: FlexFit.loose,
                      child: FilledButton(
                        onPressed: () => context.push(cashSessionPath),
                        child: const Text('Cash session'),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
