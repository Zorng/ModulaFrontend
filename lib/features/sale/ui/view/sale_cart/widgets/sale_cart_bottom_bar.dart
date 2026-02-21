import 'package:flutter/material.dart';
import 'package:modular_pos/core/formatters/khr_currency_formatter.dart';

class SaleCartBottomBar extends StatelessWidget {
  const SaleCartBottomBar({
    super.key,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
    required this.canCheckout,
    required this.isProcessing,
    required this.onCheckout,
    this.showClearCart = false,
    this.onClearCart,
  });

  final double grandTotalUsd;
  final double grandTotalKhr;
  final bool canCheckout;
  final bool isProcessing;
  final VoidCallback onCheckout;
  final bool showClearCart;
  final VoidCallback? onClearCart;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Total (VAT inclu.)',
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '\$${grandTotalUsd.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'KHR ${formatKhrAmount(grandTotalKhr)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (showClearCart) ...[
                  IconButton(
                    onPressed: isProcessing ? null : onClearCart,
                    tooltip: 'Clear Cart',
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: (canCheckout && !isProcessing)
                        ? onCheckout
                        : null,
                    child: isProcessing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Checkout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
