import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderNumber});

  final String orderNumber;

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _orderTypeLabel(String orderType) {
    switch (orderType) {
      case 'dine_in':
        return 'Dine In';
      case 'take_away':
        return 'Take Away';
      case 'delivery':
        return 'Delivery';
      default:
        return orderType.replaceAll('_', ' ').split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_prep':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final order = orders.firstWhere(
      (o) => o.number == orderNumber,
      orElse: () => Order(
        id: orderNumber,
        number: orderNumber,
        status: 'unknown',
        placedAt: DateTime.now(),
        orderType: 'take_away',
        paymentMethod: 'cash',
        totalUsd: 0,
        totalKhr: 0,
        tenderCurrency: 'usd',
        tenderAmount: 0,
        changeAmount: 0,
        lines: const [],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Order No. ${order.number}'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Type', value: _orderTypeLabel(order.orderType)),
                    const Divider(),
                _SummaryRow(label: 'Placed', value: _formatTime(order.placedAt.toLocal())),
                    const Divider(),
                    _SummaryRow(
                      label: 'Payment Method',
                      value: order.paymentMethod == 'qr' ? 'QR / Transfer' : 'Cash',
                    ),
                    const Divider(),
                    _SummaryRow(
                      label: 'Current Status',
                      value: _statusLabel(order.status),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Order Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                itemCount: order.lines.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final line = order.lines[index];
                  final modifierText =
                      line.modifiers.isEmpty ? 'No modifiers' : line.modifiers.join(', ');
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${line.quantity}x',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.name,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              modifierText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('Payment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Grand Total',
                      value: '\$${order.totalUsd.toStringAsFixed(2)}',
                      subValue: 'KHR ${order.totalKhr.toStringAsFixed(0)}',
                    ),
                    const Divider(),
                    _SummaryRow(
                      label: 'Received amount',
                      value: order.tenderCurrency == 'usd'
                          ? '\$${order.tenderAmount.toStringAsFixed(2)}'
                          : 'KHR ${order.tenderAmount.toStringAsFixed(0)}',
                    ),
                    const Divider(),
                    _SummaryRow(
                      label: 'Change',
                      value: order.tenderCurrency == 'usd'
                          ? '\$${order.changeAmount.toStringAsFixed(2)}'
                          : 'KHR ${order.changeAmount.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.subValue,
  });

  final String label;
  final String value;
  final String? subValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subValue != null)
                Text(
                  subValue!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
