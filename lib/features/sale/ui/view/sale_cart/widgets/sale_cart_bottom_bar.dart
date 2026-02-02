import 'package:flutter/material.dart';

class SaleCartBottomBar extends StatelessWidget {
  const SaleCartBottomBar({
    super.key,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
    required this.canCheckout,
    required this.onCheckout,
  });

  final double grandTotalUsd;
  final double grandTotalKhr;
  final bool canCheckout;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Total (VAT inclu.)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '\$${grandTotalUsd.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '៛ ${grandTotalKhr.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: canCheckout ? onCheckout : null,
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
